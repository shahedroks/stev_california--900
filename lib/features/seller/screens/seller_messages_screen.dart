import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';

// TSX SellerMessagesScreen.tsx colors
class _MessagesColors {
  static const blueBg = Color(0xFF2384F4);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
}

/// Chat item for list – mirrors TSX Chat interface.
class _ChatItem {
  final String customerId;
  final String customerName;
  final String lastMessage;
  final String timestamp;
  final int unread;
  final String bookingId;
  final String categoryName;

  const _ChatItem({
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    required this.timestamp,
    this.unread = 0,
    required this.bookingId,
    required this.categoryName,
  });
}

/// Seller messages – full conversion from React SellerMessagesScreen.tsx.
/// Blue header, list of chat cards (avatar, name, last message, timestamp, category badge), empty state.
class SellerMessagesScreen extends StatelessWidget {
  const SellerMessagesScreen({
    super.key,
    this.showAppBar = true,
    this.onSelectChat,
  });

  final bool showAppBar;
  final void Function(String customerId, String bookingId)? onSelectChat;

  static List<_ChatItem> _mockChats() => [
        const _ChatItem(
          customerId: 'customer1',
          customerName: 'John Doe',
          lastMessage: 'Thank you! See you tomorrow.',
          timestamp: '10:30 AM',
          unread: 2,
          bookingId: 'booking1',
          categoryName: 'Plumbing',
        ),
        const _ChatItem(
          customerId: 'customer2',
          customerName: 'Sarah Johnson',
          lastMessage: 'What time will you arrive?',
          timestamp: 'Yesterday',
          unread: 0,
          bookingId: 'booking2',
          categoryName: 'Electrical',
        ),
        const _ChatItem(
          customerId: 'customer3',
          customerName: 'Mike Williams',
          lastMessage: 'Great job, thanks!',
          timestamp: 'Jan 15',
          unread: 0,
          bookingId: 'booking3',
          categoryName: 'Cleaning',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final chats = _mockChats();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header – TSX: px-4 py-6, bg blue
        Container(
          width: double.infinity,
          color: _MessagesColors.blueBg,
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(height: 4.h),
                Text('Chat with your customers', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
        ),
        // List or empty – TSX: flex-1 overflow-y-auto px-4 pb-4 space-y-3
        Expanded(
          child: Container(
            color: _MessagesColors.blueBg,
            child: chats.isEmpty
                ? _EmptyMessages()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _ChatCard(
                          chat: chat,
                          onTap: () => onSelectChat?.call(chat.customerId, chat.bookingId),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );

    if (!showAppBar) return content;
    return Scaffold(
      backgroundColor: _MessagesColors.blueBg,
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: _MessagesColors.blueBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: AppLogoButton(size: 34),
          ),
        ],
      ),
      body: content,
    );
  }
}

/// TSX: motion.button – white rounded-2xl shadow-md px-4 py-4, avatar, name, timestamp, lastMessage, category badge, chevron.
class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.chat, required this.onTap});

  final _ChatItem chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF408AF1).withOpacity(0.1), const Color(0xFF5ca3f5).withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.person_outline, size: 28.sp, color: const Color(0xFF408AF1)),
                  ),
                  if (chat.unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('${chat.unread}', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(chat.customerName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: _MessagesColors.gray600), overflow: TextOverflow.ellipsis),
                        ),
                        Text(chat.timestamp, style: TextStyle(fontSize: 12.sp, color: _MessagesColors.gray500)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(chat.lastMessage, style: TextStyle(fontSize: 14.sp, color: _MessagesColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(color: _MessagesColors.gray100, borderRadius: BorderRadius.circular(12.r)),
                          child: Text(chat.categoryName, style: TextStyle(fontSize: 12.sp, color: _MessagesColors.gray400)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.chevron_right, size: 20.sp, color: _MessagesColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

/// TSX: empty state – MessageSquare icon, "No messages yet", subtitle.
class _EmptyMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(color: _MessagesColors.gray100, borderRadius: BorderRadius.circular(16.r)),
              child: Icon(Icons.chat_bubble_outline, size: 32.sp, color: _MessagesColors.gray400),
            ),
            Text('No messages yet', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: _MessagesColors.gray600)),
            SizedBox(height: 4.h),
            Text('Customer messages will appear here', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: _MessagesColors.gray500)),
          ],
        ),
      ),
    );
  }
}
