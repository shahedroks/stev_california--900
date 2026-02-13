import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/chat_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/messages/data/chat_api_models.dart';

/// Chat API service – threads, read, messages, send.
class ChatApiService {
  Future<Map<String, String>?> _headers() async =>
      await AuthLocalStorage.authHeaders();

  /// GET /chat/threads – list threads for current user (customer or provider).
  Future<List<ApiChatThread>> getThreads() async {
    final headers = await _headers();
    if (headers == null) return [];
    final res = await http.get(
      Uri.parse(ChatApi.threads),
      headers: headers,
    );
    if (res.statusCode != 200) return [];
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'];
      if (data is! List) return [];
      return data
          .map((e) => ApiChatThread.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// POST /chat/threads with body { "bookingId": "..." } – get or create thread. Returns thread _id or null.
  Future<String?> getOrCreateThread(String bookingId) async {
    final headers = await _headers();
    if (headers == null) return null;
    final res = await http.post(
      Uri.parse(ChatApi.createThread),
      headers: headers,
      body: jsonEncode({'bookingId': bookingId}),
    );
    if (res.statusCode != 200) return null;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'];
      if (data is! Map) return null;
      final id = data['_id']?.toString();
      return id;
    } catch (_) {
      return null;
    }
  }

  /// GET /chat/threads/:threadId/read – mark thread as read (per user image 2).
  Future<bool> markThreadRead(String threadId) async {
    final headers = await _headers();
    if (headers == null) return false;
    final res = await http.get(
      Uri.parse(ChatApi.threadRead(threadId)),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  /// GET /chat/threads/:threadId/messages?limit=30
  /// Response: { "status": "success", "message": "Messages", "data": [ { _id, threadId, senderUserId, senderRole, message, isBlocked, detected, createdAt, updatedAt }, ... ] }
  Future<List<ApiChatMessage>> getMessages(String threadId, {int limit = 30}) async {
    final headers = await _headers();
    if (headers == null) return [];
    final uri = Uri.parse(ChatApi.threadMessages(threadId))
        .replace(queryParameters: {'limit': limit.toString()});
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) return [];
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'];
      if (data is! List) return [];
      final list = data
          .map((e) => ApiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // API may return newest first; show chronological (oldest first) so newest at bottom
      if (list.length > 1 && list.first.createdAt.isAfter(list.last.createdAt)) {
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// POST /chat/threads/:threadId/messages – body: { "message": "..." }
  /// Returns sent message or null; check message.isBlocked and blockedReason.
  Future<ApiChatMessage?> sendMessage(String threadId, String message) async {
    final headers = await _headers();
    if (headers == null) return null;
    final res = await http.post(
      Uri.parse(ChatApi.threadMessages(threadId)),
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200) return null;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'];
      if (data is! Map) return null;
      return ApiChatMessage.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}
