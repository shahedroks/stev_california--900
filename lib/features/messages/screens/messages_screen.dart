import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/messages/screens/chat_screen.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/core/models/town.dart';

/// Chat list item – mirrors React MessagesScreen Chat interface.
class ChatListItem {
  const ChatListItem({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.providerAvatar,
    required this.categoryName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.timeAgo,
    required this.unreadCount,
    required this.bookingStatus,
  });

  final String id;
  final String bookingId;
  final String providerId;
  final String providerName;
  final String providerAvatar;
  final String categoryName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String timeAgo;
  final int unreadCount;
  final BookingStatus bookingStatus;
}

/// Messages screen – full conversion from React MessagesScreen.tsx.
/// Same header as CustomerHomeScreen; blue background, search, chat list, loading, empty state.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.customerId = 'customer1',
    this.onSelectChat,
    this.selectedTownId,
    this.selectedTownName,
    this.onChangeTown,
    this.onNotifications,
  });

  final String customerId;
  final void Function(String providerId, String? bookingId)? onSelectChat;
  final String? selectedTownId;
  final String? selectedTownName;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ChatListItem> _chats = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
        _selectedTownId = town.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing services in ${town.name}')),
        );
      }
    }
  }

  void _onNotifications() {
    widget.onNotifications?.call();
    if (widget.onNotifications != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    final bookings = await loadBookingsForCustomer(widget.customerId);
    if (!mounted) return;
    final active = bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .toList();

    final lastMessages = {
      BookingStatus.pending:
          "Thanks for booking! I'll confirm the details shortly.",
      BookingStatus.confirmed: "See you on the scheduled date!",
      BookingStatus.inProgress: "I'm on my way to your location.",
      BookingStatus.completed: 'Thanks for choosing our service!',
      BookingStatus.cancelled: 'Message received',
    };

    final now = DateTime.now();
    final chats = <ChatListItem>[];
    for (final booking in active) {
      final dt = booking.scheduledDateTime ?? now;
      final diff = now.difference(dt);
      String timeAgo;
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inHours < 48) {
        timeAgo = 'Yesterday';
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        timeAgo = '${months[dt.month - 1]} ${dt.day}';
      }

      chats.add(
        ChatListItem(
          id: 'chat-${booking.id}',
          bookingId: booking.id,
          providerId: booking.id,
          providerName: booking.providerName,
          providerAvatar: booking.providerAvatar,
          categoryName: booking.categoryName,
          lastMessage: lastMessages[booking.status] ?? 'Message received',
          lastMessageTime: dt,
          timeAgo: timeAgo,
          unreadCount: booking.status == BookingStatus.pending ? 1 : 0,
          bookingStatus: booking.status,
        ),
      );
    }
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    setState(() {
      _chats = chats;
      _loading = false;
    });
  }

  List<ChatListItem> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    final q = _searchQuery.toLowerCase();
    return _chats.where((c) {
      return c.providerName.toLowerCase().contains(q) ||
          c.categoryName.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  (Color bg, Color text) _statusColors(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case BookingStatus.confirmed:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case BookingStatus.inProgress:
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case BookingStatus.completed:
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
      case BookingStatus.cancelled:
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  void _onSelectChat(ChatListItem chat) {
    widget.onSelectChat?.call(chat.providerId, chat.bookingId);
    if (widget.onSelectChat != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          bookingId: chat.bookingId,
          userRole: 'customer',
          providerId: chat.providerId,
          providerName: chat.providerName,
          providerAvatar: chat.providerAvatar.isNotEmpty
              ? chat.providerAvatar
              : null,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: SizedBox(
                      width: 48.w,
                      height: 48.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _chats.isEmpty
                                    ? 'No active conversations'
                                    : '${_chats.length} active conversation${_chats.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              if (_chats.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search messages...',
                                    hintStyle: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: 20.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF3F4F6),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF3F4F6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF408AF1),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 12.h,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Expanded(
                          child: _filteredChats.isNotEmpty
                              ? ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    16.w,
                                    0,
                                    16.w,
                                    16.h,
                                  ),
                                  itemCount: _filteredChats.length,
                                  itemBuilder: (context, index) {
                                    final chat = _filteredChats[index];
                                    return _ChatCard(
                                      chat: chat,
                                      statusColors: _statusColors(
                                        chat.bookingStatus,
                                      ),
                                      statusLabel: _statusLabel(
                                        chat.bookingStatus,
                                      ),
                                      onTap: () => _onSelectChat(chat),
                                    );
                                  },
                                )
                              : _buildEmptyState(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty ? 'No messages yet' : 'No results found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AllColor.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isEmpty
                  ? 'Book a service to start chatting with providers'
                  : 'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14.sp,
                color: AllColor.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.statusColors,
    required this.statusLabel,
    required this.onTap,
  });

  final ChatListItem chat;
  final (Color bg, Color text) statusColors;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = chat.providerName.isNotEmpty
        ? chat.providerName[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: chat.providerAvatar.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: chat.providerAvatar,
                              width: 56.w,
                              height: 56.h,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _avatarPlaceholder(initial),
                              errorWidget: (_, __, ___) =>
                                  _avatarPlaceholder(initial),
                            )
                          : _avatarPlaceholder(initial),
                    ),
                    if (chat.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF408AF1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${chat.unreadCount}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.providerName,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  chat.categoryName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                chat.timeAgo,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColors.$1,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: statusColors.$2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: chat.unreadCount > 0
                              ? const Color(0xFF111827)
                              : const Color(0xFF4B5563),
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String initial) {
    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF408AF1), Color(0xFF5ca3f5)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
