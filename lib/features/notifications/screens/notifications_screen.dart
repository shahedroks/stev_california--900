import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/core/models/town.dart';

/// Notification item type – mirrors NotificationsScreen.tsx.
enum NotificationItemType { booking, message, promotion, reminder }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.unread,
  });

  final String id;
  final NotificationItemType type;
  final String title;
  final String message;
  final String timestamp;
  final bool unread;
}

/// Notifications – full conversion from React NotificationsScreen.tsx.
/// Blue bg, CustomerHeader, bottom nav, unread badge, list of notification cards, empty state.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onBack,
    this.onClose,
    this.selectedTownName,
    this.selectedTownId,
    this.onChangeTown,
    this.onNotifications,
  });

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final String? selectedTownName;
  final String? selectedTownId;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  static const String routeName = '/notifications';

  static const List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: NotificationItemType.booking,
      title: 'Booking Confirmed',
      message:
          "Mike's Plumbing confirmed your appointment for tomorrow at 2:00 PM",
      timestamp: '5 min ago',
      unread: true,
    ),
    NotificationItem(
      id: '2',
      type: NotificationItemType.message,
      title: 'New Message',
      message: 'Elite Electric Co. sent you a message',
      timestamp: '1 hour ago',
      unread: true,
    ),
    NotificationItem(
      id: '4',
      type: NotificationItemType.promotion,
      title: 'Special Offer',
      message: 'Get 15% off your next HVAC service this week',
      timestamp: '3 hours ago',
      unread: false,
    ),
    NotificationItem(
      id: '5',
      type: NotificationItemType.reminder,
      title: 'Upcoming Appointment',
      message: 'Your appointment with Sparkle Clean is tomorrow',
      timestamp: '1 day ago',
      unread: false,
    ),
  ];

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
    // Already on NotificationsScreen; no-op or could refresh
  }

  void _onNavTabTap(int index) {
    if (index == 4) return;
    Navigator.of(context).pop();
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  void _onBack() {
    widget.onBack?.call();
    if (widget.onBack != null) return;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = NotificationsScreen._notifications
        .where((n) => n.unread)
        .length;
    final notifications = NotificationsScreen._notifications;

    return Scaffold(
      backgroundColor: _bgBlue,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: 4,
        onTabTap: _onNavTabTap,
      ),
      body: Column(
        children: [
          CustomerHeader(
            leading: IconButton(
              onPressed: _onBack,
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 22.sp,
                color: Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: null, // Already on notifications screen
          ),
          _buildTitle(unreadCount),
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _NotificationCard(item: notifications[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(int unreadCount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (unreadCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Stay updated on your bookings',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 40.sp,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "We'll notify you about booking updates and messages",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconColor, Color bgColor) = _styleForType(
      item.type,
    );
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: item.unread
              ? const Color(0xFF408AF1).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.unread
                ? const Color(0xFF408AF1).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 24.sp, color: iconColor),
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
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: item.unread
                              ? const Color(0xFF111827)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 10.w,
                        height: 10.w,
                        margin: EdgeInsets.only(left: 8.w, top: 6.h),
                        decoration: const BoxDecoration(
                          color: Color(0xFF408AF1),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  item.timestamp,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _styleForType(NotificationItemType type) {
    switch (type) {
      case NotificationItemType.booking:
        return (
          Icons.calendar_today_outlined,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        );
      case NotificationItemType.message:
        return (
          Icons.message_outlined,
          const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
        );
      case NotificationItemType.promotion:
        return (
          Icons.trending_up,
          const Color(0xFFEA580C),
          const Color(0xFFFFF7ED),
        );
      case NotificationItemType.reminder:
        return (
          Icons.schedule,
          const Color(0xFFCA8A04),
          const Color(0xFFFEFCE8),
        );
    }
  }
}
