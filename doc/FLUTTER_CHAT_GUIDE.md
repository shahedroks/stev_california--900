# Flutter Chat System Implementation Guide

This guide explains how to implement the real-time chat feature in your Flutter app. The chat allows customers and providers to communicate after a booking is created, with automatic blocking of contact information sharing (phone numbers, emails, "call me", etc.).

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Socket.IO Integration (Real-time)](#socketio-integration-realtime)
5. [Data Models](#data-models)
6. [Implementation Flow](#implementation-flow)
7. [Contact Blocking Behavior](#contact-blocking-behavior)
8. [Error Handling](#error-handling)
9. [Testing in Postman](#testing-in-postman)

---

## Overview

The chat system works as follows:

- **Chat threads are tied to bookings**: Each booking has one chat thread between customer and provider
- **Access control**: Only the customer and provider of a booking can access that thread
- **Real-time messaging**: Use Socket.IO for instant message delivery (optional - HTTP polling also works)
- **Contact blocking**: Messages containing phone numbers, emails, or contact intent words are automatically blocked
- **Unread counts**: Separate unread counters for customer and provider

**Base URL**: Replace `{{BASE_URL}}` with your server (e.g., `http://localhost:5000/api/v1` or `https://your-api.com/api/v1`)

---

## Authentication

All chat endpoints require authentication. Include the JWT token in the `Authorization` header:

```
Authorization: Bearer <accessToken>
```

**Getting the token:**
1. User logs in via `POST /api/v1/auth/login`
2. Response contains `data.tokens.accessToken`
3. Store this token securely (e.g., using `flutter_secure_storage` or `shared_preferences`)
4. Include it in all API requests

**Example:**
```dart
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $accessToken',
};
```

---

## API Endpoints

### 1. Get or Create Chat Thread

**Endpoint:** `POST /api/v1/chat/threads`

**Purpose:** Create a chat thread for a booking, or get existing thread if already created.

**Request:**
```json
{
  "bookingId": "507f1f77bcf86cd799439011"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Thread ready",
  "data": {
    "_id": "507f191e810c19729de860ea",
    "bookingId": "507f1f77bcf86cd799439011",
    "customerId": {
      "_id": "507f1f77bcf86cd799439012",
      "fullName": "John Doe",
      "avatarUrl": "https://..."
    },
    "providerId": {
      "_id": "507f1f77bcf86cd799439013",
      "fullName": "Sparkle Home Cleaning",
      "avatarUrl": "https://..."
    },
    "lastMessage": "",
    "lastMessageAt": null,
    "unreadByCustomer": 0,
    "unreadByProvider": 0,
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Notes:**
- Both customer and provider can call this with the same `bookingId`
- Backend automatically verifies the user is either the customer or provider of that booking
- Returns existing thread if one already exists for that booking

---

### 2. List All Chat Threads

**Endpoint:** `GET /api/v1/chat/threads`

**Purpose:** Get all chat conversations for the logged-in user (customer sees their threads, provider sees their threads).

**Request:** No body required

**Response:**
```json
{
  "status": "success",
  "message": "Threads",
  "data": [
    {
      "_id": "507f191e810c19729de860ea",
      "bookingId": {
        "_id": "507f1f77bcf86cd799439011",
        "scheduledAt": "2024-01-20T14:00:00.000Z",
        "status": "accepted"
      },
      "customerId": {
        "_id": "507f1f77bcf86cd799439012",
        "fullName": "John Doe",
        "avatarUrl": "https://..."
      },
      "providerId": {
        "_id": "507f1f77bcf86cd799439013",
        "fullName": "Sparkle Home Cleaning",
        "avatarUrl": "https://..."
      },
      "lastMessage": "Thanks for booking!",
      "lastMessageAt": "2024-01-15T12:00:00.000Z",
      "lastSenderUserId": "507f1f77bcf86cd799439013",
      "lastSenderRole": "provider",
      "unreadByCustomer": 2,
      "unreadByProvider": 0,
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T12:00:00.000Z"
    }
  ]
}
```

**Notes:**
- For **customer app**: Check `unreadByCustomer` for badge count
- For **provider app**: Check `unreadByProvider` for badge count
- Backend automatically filters by user role (customer sees threads where they are customer, provider sees threads where they are provider)

---

### 3. Get Messages in a Thread

**Endpoint:** `GET /api/v1/chat/threads/:id/messages?limit=30&before=2024-01-15T12:00:00.000Z`

**Purpose:** Load messages for a specific chat thread.

**Query Parameters:**
- `limit` (optional, default: 30, max: 50): Number of messages to return
- `before` (optional): ISO date string - get messages before this date (for pagination)

**Response:**
```json
{
  "status": "success",
  "message": "Messages",
  "data": [
    {
      "_id": "507f191e810c19729de860eb",
      "threadId": "507f191e810c19729de860ea",
      "senderUserId": "507f1f77bcf86cd799439013",
      "senderRole": "provider",
      "message": "Thanks for booking with us! I've received your request.",
      "isBlocked": false,
      "blockedReason": null,
      "detected": {
        "hasPhone": false,
        "hasEmail": false,
        "hasContactIntent": false
      },
      "createdAt": "2024-01-15T11:00:00.000Z",
      "updatedAt": "2024-01-15T11:00:00.000Z"
    },
    {
      "_id": "507f191e810c19729de860ec",
      "threadId": "507f191e810c19729de860ea",
      "senderUserId": "507f1f77bcf86cd799439012",
      "senderRole": "customer",
      "message": "Great! What time works best for you?",
      "isBlocked": false,
      "blockedReason": null,
      "detected": {
        "hasPhone": false,
        "hasEmail": false,
        "hasContactIntent": false
      },
      "createdAt": "2024-01-15T11:05:00.000Z",
      "updatedAt": "2024-01-15T11:05:00.000Z"
    }
  ]
}
```

**Notes:**
- Messages are returned in chronological order (oldest first)
- Use `before` parameter for pagination (load older messages)
- If a message is blocked, `message` field will be empty string `""` and `isBlocked: true`

---

### 4. Send a Message

**Endpoint:** `POST /api/v1/chat/threads/:id/messages`

**Purpose:** Send a message in a chat thread.

**Request:**
```json
{
  "message": "Hi, looking forward to the job!"
}
```

**Response (Success):**
```json
{
  "status": "success",
  "message": "Message sent",
  "data": {
    "_id": "507f191e810c19729de860ed",
    "threadId": "507f191e810c19729de860ea",
    "senderUserId": "507f1f77bcf86cd799439012",
    "senderRole": "customer",
    "message": "Hi, looking forward to the job!",
    "isBlocked": false,
    "blockedReason": null,
    "detected": {
      "hasPhone": false,
      "hasEmail": false,
      "hasContactIntent": false
    },
    "createdAt": "2024-01-15T12:00:00.000Z",
    "updatedAt": "2024-01-15T12:00:00.000Z"
  }
}
```

**Response (Blocked Message):**
```json
{
  "status": "success",
  "message": "Message sent",
  "data": {
    "_id": "507f191e810c19729de860ee",
    "threadId": "507f191e810c19729de860ea",
    "senderUserId": "507f1f77bcf86cd799439012",
    "senderRole": "customer",
    "message": "",
    "isBlocked": true,
    "blockedReason": "Sharing contact information is not allowed",
    "detected": {
      "hasPhone": true,
      "hasEmail": false,
      "hasContactIntent": true
    },
    "createdAt": "2024-01-15T12:00:00.000Z",
    "updatedAt": "2024-01-15T12:00:00.000Z"
  }
}
```

**Notes:**
- Message must be between 1 and 2000 characters
- If message contains contact info, it will be blocked (see [Contact Blocking Behavior](#contact-blocking-behavior))
- Even if blocked, the message is saved in DB but `message` field is empty in response
- Check `isBlocked` and `blockedReason` to show warning to user

---

### 5. Mark Thread as Read

**Endpoint:** `PATCH /api/v1/chat/threads/:id/read`

**Purpose:** Mark all messages in a thread as read (clears unread count).

**Request:** No body required

**Response:**
```json
{
  "status": "success",
  "message": "Marked read",
  "data": {
    "ok": true
  }
}
```

**Notes:**
- For **customer**: Sets `unreadByCustomer = 0`
- For **provider**: Sets `unreadByProvider = 0`
- Call this when user opens the chat screen

---

## Socket.IO Integration (Real-time)

For real-time message delivery, use Socket.IO. This is **optional** - you can also poll the messages endpoint periodically.

### Setup

**Package:** Add `socket_io_client` to your `pubspec.yaml`:
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

**Connection:**
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'http://your-api-host:5000', // or https://your-api.com
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': 'Bearer $accessToken'}) // or use extraHeaders
    .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
    .build(),
);
```

### Socket Events

#### 1. Join Chat Room

**Event:** `chat:join`

**Payload:**
```json
{
  "bookingId": "507f1f77bcf86cd799439011"
}
```
or
```json
{
  "threadId": "507f191e810c19729de860ea"
}
```

**Response (callback):**
```json
{
  "ok": true,
  "threadId": "507f191e810c19729de860ea"
}
```

**Example:**
```dart
socket.emitWithAck('chat:join', {'bookingId': bookingId}, (response) {
  if (response['ok'] == true) {
    final threadId = response['threadId'];
    // Now joined to room: thread:<threadId>
  } else {
    // Handle error
    print('Error: ${response['error']}');
  }
});
```

#### 2. Send Message (Real-time)

**Event:** `chat:send`

**Payload:**
```json
{
  "threadId": "507f191e810c19729de860ea",
  "message": "Hello!"
}
```

**Response (callback):**
```json
{
  "ok": true,
  "message": {
    "_id": "507f191e810c19729de860ed",
    "threadId": "507f191e810c19729de860ea",
    "senderUserId": "507f1f77bcf86cd799439012",
    "senderRole": "customer",
    "message": "Hello!",
    "isBlocked": false,
    "createdAt": "2024-01-15T12:00:00.000Z"
  }
}
```

**Example:**
```dart
socket.emitWithAck('chat:send', {
  'threadId': threadId,
  'message': messageText,
}, (response) {
  if (response['ok'] == true) {
    // Message sent successfully
    final message = response['message'];
    if (message['isBlocked'] == true) {
      // Show warning to user
      showWarning('Contact information is not allowed');
    } else {
      // Add message to UI
      addMessageToUI(message);
    }
  } else {
    // Handle error
    showError(response['error'] ?? 'Failed to send message');
  }
});
```

#### 3. Receive New Messages

**Event:** `chat:message` (listen for this)

**Payload:**
```json
{
  "threadId": "507f191e810c19729de860ea",
  "message": {
    "_id": "507f191e810c19729de860ed",
    "threadId": "507f191e810c19729de860ea",
    "senderUserId": "507f1f77bcf86cd799439012",
    "senderRole": "customer",
    "message": "Hello!",
    "isBlocked": false,
    "createdAt": "2024-01-15T12:00:00.000Z"
  }
}
```

**Example:**
```dart
socket.on('chat:message', (data) {
  final threadId = data['threadId'];
  final message = data['message'];
  
  // Only process if it's for the current thread
  if (threadId == currentThreadId) {
    if (message['isBlocked'] == true) {
      // Show blocked message indicator
      showBlockedMessageIndicator();
    } else {
      // Add message to UI
      addMessageToUI(message);
    }
  }
});
```

#### 4. Mark as Read (Real-time)

**Event:** `chat:read`

**Payload:**
```json
{
  "threadId": "507f191e810c19729de860ea"
}
```

**Response (callback):**
```json
{
  "ok": true
}
```

**Example:**
```dart
socket.emitWithAck('chat:read', {'threadId': threadId}, (response) {
  if (response['ok'] == true) {
    // Unread count cleared
  }
});
```

#### 5. Receive Read Receipt

**Event:** `chat:read` (listen for this - when other party marks as read)

**Payload:**
```json
{
  "threadId": "507f191e810c19729de860ea"
}
```

**Example:**
```dart
socket.on('chat:read', (data) {
  final threadId = data['threadId'];
  if (threadId == currentThreadId) {
    // Update read status in UI (e.g., show double checkmark)
    updateReadStatus();
  }
});
```

---

## Data Models

### ChatThread Model

```dart
class ChatThread {
  final String id;
  final String bookingId;
  final UserInfo customer;
  final UserInfo provider;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderUserId;
  final String? lastSenderRole;
  final int unreadByCustomer;
  final int unreadByProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatThread({
    required this.id,
    required this.bookingId,
    required this.customer,
    required this.provider,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderUserId,
    this.lastSenderRole,
    required this.unreadByCustomer,
    required this.unreadByProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['_id'],
      bookingId: json['bookingId'] is String 
          ? json['bookingId'] 
          : json['bookingId']['_id'],
      customer: UserInfo.fromJson(json['customerId']),
      provider: UserInfo.fromJson(json['providerId']),
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      lastSenderUserId: json['lastSenderUserId'],
      lastSenderRole: json['lastSenderRole'],
      unreadByCustomer: json['unreadByCustomer'] ?? 0,
      unreadByProvider: json['unreadByProvider'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class UserInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;

  UserInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
```

### ChatMessage Model

```dart
class ChatMessage {
  final String id;
  final String threadId;
  final String senderUserId;
  final String senderRole; // "customer" or "provider"
  final String message; // Empty string if blocked
  final bool isBlocked;
  final String? blockedReason;
  final DetectedInfo detected;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.senderRole,
    required this.message,
    required this.isBlocked,
    this.blockedReason,
    required this.detected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      threadId: json['threadId'],
      senderUserId: json['senderUserId'],
      senderRole: json['senderRole'],
      message: json['message'] ?? '',
      isBlocked: json['isBlocked'] ?? false,
      blockedReason: json['blockedReason'],
      detected: DetectedInfo.fromJson(json['detected'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class DetectedInfo {
  final bool hasPhone;
  final bool hasEmail;
  final bool hasContactIntent;

  DetectedInfo({
    required this.hasPhone,
    required this.hasEmail,
    required this.hasContactIntent,
  });

  factory DetectedInfo.fromJson(Map<String, dynamic> json) {
    return DetectedInfo(
      hasPhone: json['hasPhone'] ?? false,
      hasEmail: json['hasEmail'] ?? false,
      hasContactIntent: json['hasContactIntent'] ?? false,
    );
  }
}
```

---

## Implementation Flow

### Customer App Flow

#### 1. Messages List Screen

```dart
// On screen load
Future<void> loadThreads() async {
  final response = await http.get(
    Uri.parse('$baseUrl/chat/threads'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final threads = (data['data'] as List)
        .map((t) => ChatThread.fromJson(t))
        .toList();
    
    // Display threads in ListView
    // Show badge with unreadByCustomer count
  }
}
```

#### 2. Open Chat from Booking

```dart
// When user taps "Chat" button on booking detail
Future<void> openChatFromBooking(String bookingId) async {
  // Create/get thread
  final response = await http.post(
    Uri.parse('$baseUrl/chat/threads'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'bookingId': bookingId}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final thread = ChatThread.fromJson(data['data']);
    final threadId = thread.id;
    
    // Navigate to chat screen with threadId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(threadId: threadId),
      ),
    );
  }
}
```

#### 3. Chat Screen

```dart
class ChatScreen extends StatefulWidget {
  final String threadId;
  
  const ChatScreen({required this.threadId});
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> messages = [];
  IO.Socket? socket;
  
  @override
  void initState() {
    super.initState();
    loadMessages();
    connectSocket();
    markAsRead();
  }
  
  Future<void> loadMessages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/threads/${widget.threadId}/messages?limit=50'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        messages = (data['data'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
      });
    }
  }
  
  void connectSocket() {
    socket = IO.io(
      baseUrl.replaceAll('/api/v1', ''),
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
        .build(),
    );
    
    // Join room
    socket!.emitWithAck('chat:join', {'threadId': widget.threadId}, (response) {
      if (response['ok'] != true) {
        print('Failed to join chat: ${response['error']}');
      }
    });
    
    // Listen for new messages
    socket!.on('chat:message', (data) {
      if (data['threadId'] == widget.threadId) {
        final message = ChatMessage.fromJson(data['message']);
        setState(() {
          messages.add(message);
        });
      }
    });
  }
  
  Future<void> markAsRead() async {
    await http.patch(
      Uri.parse('$baseUrl/chat/threads/${widget.threadId}/read'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
  
  Future<void> sendMessage(String text) async {
    // Option 1: HTTP
    final response = await http.post(
      Uri.parse('$baseUrl/chat/threads/${widget.threadId}/messages'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': text}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = ChatMessage.fromJson(data['data']);
      
      if (message.isBlocked) {
        // Show warning
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.blockedReason ?? 'Message blocked'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          messages.add(message);
        });
      }
    }
    
    // Option 2: Socket.IO (alternative)
    // socket!.emitWithAck('chat:send', {
    //   'threadId': widget.threadId,
    //   'message': text,
    // }, (response) {
    //   if (response['ok'] == true) {
    //     final message = ChatMessage.fromJson(response['message']);
    //     if (message.isBlocked) {
    //       // Show warning
    //     } else {
    //       setState(() {
    //         messages.add(message);
    //       });
    //     }
    //   }
    // });
  }
  
  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderRole == 'customer';
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.isBlocked)
                          Text(
                            '[Message blocked - Contact information not allowed]',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
                          )
                        else
                          Text(
                            msg.message,
                            style: TextStyle(color: isMe ? Colors.white : Colors.black),
                          ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(msg.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Message input field
        ],
      ),
    );
  }
}
```

### Provider App Flow

The provider app follows the **same flow** as customer app:

1. **Messages List**: `GET /api/v1/chat/threads` - shows threads where provider is the provider
2. **Open Chat**: `POST /api/v1/chat/threads` with `bookingId` - same endpoint
3. **Chat Screen**: Same implementation, but check `unreadByProvider` for badge count

**Key difference**: When displaying unread counts, use `unreadByProvider` instead of `unreadByCustomer`.

---

## Contact Blocking Behavior

The backend automatically detects and blocks messages containing:

1. **Phone numbers**: Patterns like `555-123-4567`, `(555) 123-4567`, `+1 555 123 4567`, etc.
2. **Email addresses**: Patterns like `user@example.com`
3. **Contact intent words**: "call", "phone", "text", "whatsapp", "email", "contact", "telegram", "wechat", "viber", "imo", "sms", "dm"

### What Happens When a Message is Blocked:

1. **Message is saved** in database with `isBlocked: true`
2. **Message content is hidden** - `message` field returns as empty string `""`
3. **User is blocked** - The sender's account is marked as `isBlocked: true`
4. **Booking is flagged** - `outsideContactFlag: true` is set on the booking
5. **Strike count incremented** - User's `strikeCount` is increased

### UI Recommendations:

- **Show warning**: Display a warning message when `isBlocked: true` or `blockedReason` is present
- **Blocked message indicator**: Show `[Message blocked - Contact information not allowed]` instead of the actual message
- **Prevent sending**: Optionally validate on client-side before sending (but server will always enforce)

---

## Error Handling

### Common HTTP Status Codes:

- **200**: Success
- **400**: Bad Request (e.g., invalid message, missing fields)
- **401**: Unauthorized (invalid or expired token)
- **403**: Forbidden (user not part of this thread/booking)
- **404**: Not Found (thread or booking not found)
- **409**: Conflict (duplicate thread creation - should not happen)

### Error Response Format:

```json
{
  "status": "fail",
  "message": "Error message here"
}
```

### Handling in Flutter:

```dart
try {
  final response = await http.post(...);
  
  if (response.statusCode == 200) {
    // Success
  } else {
    final error = jsonDecode(response.body);
    showError(error['message'] ?? 'An error occurred');
  }
} catch (e) {
  showError('Network error: $e');
}
```

---

## Testing in Postman

You can test the entire chat system using Postman (HTTP endpoints only - Socket.IO requires a Socket.IO client).

### Step 1: Login as Customer

**POST** `{{BASE_URL}}/auth/login`
```json
{
  "email": "customer@example.com",
  "password": "password123"
}
```
Save `data.tokens.accessToken` as `CUSTOMER_TOKEN`

### Step 2: Get a Booking ID

**GET** `{{BASE_URL}}/bookings/me`  
Headers: `Authorization: Bearer {{CUSTOMER_TOKEN}}`

Copy a `bookingId` from the response (e.g., `data.items[0]._id`)

### Step 3: Create/Get Thread

**POST** `{{BASE_URL}}/chat/threads`  
Headers: `Authorization: Bearer {{CUSTOMER_TOKEN}}`  
Body:
```json
{
  "bookingId": "<bookingId from step 2>"
}
```

Save `data._id` as `THREAD_ID`

### Step 4: Send Normal Message

**POST** `{{BASE_URL}}/chat/threads/{{THREAD_ID}}/messages`  
Headers: `Authorization: Bearer {{CUSTOMER_TOKEN}}`  
Body:
```json
{
  "message": "Hi, looking forward to the job!"
}
```

### Step 5: Send Blocked Message

**POST** `{{BASE_URL}}/chat/threads/{{THREAD_ID}}/messages`  
Headers: `Authorization: Bearer {{CUSTOMER_TOKEN}}`  
Body:
```json
{
  "message": "Call or text me at 555-123-4567"
}
```

**Expected Response:**
- `isBlocked: true`
- `blockedReason: "Sharing contact information is not allowed"`
- `detected.hasPhone: true` or `detected.hasContactIntent: true`
- `message: ""` (empty string)

### Step 6: Get Messages

**GET** `{{BASE_URL}}/chat/threads/{{THREAD_ID}}/messages?limit=30`  
Headers: `Authorization: Bearer {{CUSTOMER_TOKEN}}`

### Step 7: Login as Provider (Same Booking)

**POST** `{{BASE_URL}}/auth/login`  
```json
{
  "email": "provider@example.com",
  "password": "password123"
}
```
Save `data.tokens.accessToken` as `PROVIDER_TOKEN`

### Step 8: Provider Gets Same Thread

**POST** `{{BASE_URL}}/chat/threads`  
Headers: `Authorization: Bearer {{PROVIDER_TOKEN}}`  
Body:
```json
{
  "bookingId": "<same bookingId from step 2>"
}
```

Should return the **same thread ID** as step 3.

### Step 9: Provider Sends Message

**POST** `{{BASE_URL}}/chat/threads/{{THREAD_ID}}/messages`  
Headers: `Authorization: Bearer {{PROVIDER_TOKEN}}`  
Body:
```json
{
  "message": "Thanks for booking! I'll confirm the details soon."
}
```

### Step 10: Provider Lists Threads

**GET** `{{BASE_URL}}/chat/threads`  
Headers: `Authorization: Bearer {{PROVIDER_TOKEN}}`

Should show the thread with `unreadByProvider` count.

### Step 11: Mark as Read

**PATCH** `{{BASE_URL}}/chat/threads/{{THREAD_ID}}/read`  
Headers: `Authorization: Bearer {{PROVIDER_TOKEN}}`

---

## Summary

- **Authentication**: Include `Authorization: Bearer <token>` in all requests
- **Thread Creation**: `POST /chat/threads` with `bookingId` (works for both customer and provider)
- **List Threads**: `GET /chat/threads` (automatically filtered by user role)
- **Send Message**: `POST /chat/threads/:id/messages` (check `isBlocked` in response)
- **Real-time (Optional)**: Use Socket.IO for instant message delivery
- **Contact Blocking**: Automatic - messages with phone/email/contact words are blocked
- **Unread Counts**: Use `unreadByCustomer` for customer app, `unreadByProvider` for provider app

For questions or issues, refer to the backend API documentation or contact the backend team.
