import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';

/// Booking details – full conversion from React BookingDetails.tsx.
/// Blue background, status timeline, service provider, service details, payment info.
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.onBack,
    this.initialBooking,
    this.onOpenChat,
    this.onUpdateBooking,
    this.userRole = UserRole.customer,
  });

  final String bookingId;
  final VoidCallback onBack;
  final BookingDetailsModel? initialBooking;
  final void Function(String bookingId)? onOpenChat;
  final void Function(String bookingId, BookingStatus status)? onUpdateBooking;
  final UserRole userRole;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

enum UserRole { customer, provider }

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingDetailsModel? _booking;
  bool _loading = true;
  bool _notFound = false;

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _primaryBlue = Color(0xFF408AF1);

  Future<void> _loadBooking() async {
    setState(() => _loading = true);
    if (widget.initialBooking != null) {
      setState(() {
        _booking = widget.initialBooking;
        _notFound = false;
        _loading = false;
      });
      return;
    }
    final b = await getBookingById(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _booking = b;
      _notFound = b == null;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void didUpdateWidget(covariant BookingDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingId != widget.bookingId ||
        oldWidget.initialBooking != widget.initialBooking) {
      _loadBooking();
    }
  }

  void _onOpenChat() {
    widget.onOpenChat?.call(widget.bookingId);
    if (widget.onOpenChat == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open chat')),
      );
    }
  }

  void _onUpdateStatus(BookingStatus status) {
    widget.onUpdateBooking?.call(widget.bookingId, status);
    if (widget.onUpdateBooking == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ${status.name}')),
      );
    } else if (mounted && _booking != null) {
      setState(() => _booking = BookingDetailsModel(
        id: _booking!.id,
        providerName: _booking!.providerName,
        providerAvatar: _booking!.providerAvatar,
        categoryName: _booking!.categoryName,
        townName: _booking!.townName,
        scheduledDate: _booking!.scheduledDate,
        scheduledTime: _booking!.scheduledTime,
        address: _booking!.address,
        notes: _booking!.notes,
        status: status,
        paymentStatus: _booking!.paymentStatus,
        totalAmount: _booking!.totalAmount,
      ));
    }
  }

  void _goHome() {
    if (widget.userRole == UserRole.provider) {
      context.go(ProviderAppScreen.routeName);
    } else {
      context.go(BottomNavBar.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bgBlue,
        body: Center(
          child: SizedBox(
            width: 48.w,
            height: 48.h,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_notFound || _booking == null) {
      return Scaffold(
        backgroundColor: _bgBlue,
        body: Center(
          child: Text(
            'Booking not found',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final booking = _booking!;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final statusSteps = _statusSteps(widget.userRole);
    final currentStepIndex = _currentStepIndex(booking.status, statusSteps);

    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(booking),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSection(booking, isCancelled, statusSteps, currentStepIndex),
                    if (widget.userRole == UserRole.customer) _buildServiceProviderSection(booking),
                    if (widget.userRole == UserRole.provider) _buildCustomerSection(booking),
                    if (widget.userRole == UserRole.provider && booking.status == BookingStatus.pending)
                      _buildAcceptDeclineSection(),
                    if (widget.userRole == UserRole.provider && booking.status == BookingStatus.confirmed)
                      _buildStartJobButton(),
                    if (widget.userRole == UserRole.provider && booking.status == BookingStatus.inProgress)
                      _buildCompleteJobButton(),
                    _buildServiceDetailsSection(booking),
                    _buildPaymentSection(booking),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BookingDetailsModel booking) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, size: 24.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text('Back', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AppLogoButton(
                size: 36,
                onTap: _goHome,
              ),
            ],
          ),
          Text(
            'Booking Details',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 4.h),
          Text(
            'Order #${booking.id.length >= 8 ? booking.id.substring(0, 8) : booking.id}',
            style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  /// Customer view: 3 steps (Booking Requested → Service In Progress → Service Completed) per image.
  /// Provider view: 4 steps including Provider Confirmed.
  List<({String key, String label, IconData icon})> _statusSteps(UserRole role) {
    if (role == UserRole.customer) {
      return const [
        (key: 'pending', label: 'Booking Requested', icon: Icons.schedule),
        (key: 'inProgress', label: 'Service In Progress', icon: Icons.schedule),
        (key: 'completed', label: 'Service Completed', icon: Icons.check),
      ];
    }
    return const [
      (key: 'pending', label: 'Booking Requested', icon: Icons.schedule),
      (key: 'confirmed', label: 'Provider Confirmed', icon: Icons.check),
      (key: 'inProgress', label: 'Service In Progress', icon: Icons.schedule),
      (key: 'completed', label: 'Service Completed', icon: Icons.check),
    ];
  }

  /// Current step index for timeline. Customer (3 steps): pending/confirmed=0, inProgress=1, completed=2.
  /// Provider (4 steps): pending=0, confirmed=1, inProgress=2, completed=3.
  int _currentStepIndex(BookingStatus status, List<({String key, String label, IconData icon})> steps) {
    if (steps.length == 3) {
      switch (status) {
        case BookingStatus.pending:
        case BookingStatus.confirmed:
          return 0;
        case BookingStatus.inProgress:
          return 1;
        case BookingStatus.completed:
          return 2;
        case BookingStatus.cancelled:
          return -1;
      }
    }
    switch (status) {
      case BookingStatus.pending: return 0;
      case BookingStatus.confirmed: return 1;
      case BookingStatus.inProgress: return 2;
      case BookingStatus.completed: return 3;
      case BookingStatus.cancelled: return -1;
    }
  }

  Widget _buildStatusSection(
    BookingDetailsModel booking,
    bool isCancelled,
    List<({String key, String label, IconData icon})> statusSteps,
    int currentStepIndex,
  ) {
    if (isCancelled) {
      return Padding(
        padding: EdgeInsets.only(bottom: 24.h),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.close, size: 24.sp, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Cancelled', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    SizedBox(height: 4.h),
                    Text('This booking has been cancelled', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Status', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 16.h),
          ...List.generate(statusSteps.length, (index) {
            final step = statusSteps[index];
            final isComplete = currentStepIndex >= 0 && index <= currentStepIndex;
            final isCurrent = index == currentStepIndex;
            return Padding(
              padding: EdgeInsets.only(bottom: index < statusSteps.length - 1 ? 8.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: isComplete ? Colors.white : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: isComplete ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8)] : null,
                        ),
                        child: Icon(step.icon, size: 20.sp, color: isComplete ? _bgBlue : Colors.white.withOpacity(0.5)),
                      ),
                      if (index < statusSteps.length - 1)
                        Container(
                          width: 2,
                          height: 24.h,
                          color: isComplete ? Colors.white : Colors.white.withOpacity(0.2),
                        ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? Colors.white : (isComplete ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.5)),
                            ),
                          ),
                          if (isCurrent) Text('Current status', style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceProviderSection(BookingDetailsModel booking) {
    final initial = booking.providerName.isNotEmpty ? booking.providerName[0].toUpperCase() : '?';
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Provider', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.h),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryBlue, Color(0xFF5ca3f5)],
                    ),
                  ),
                  child: booking.providerAvatar.isNotEmpty
                      ? CachedNetworkImage(imageUrl: booking.providerAvatar, fit: BoxFit.cover)
                      : Center(child: Text(initial, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600, color: Colors.white))),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.providerName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(booking.categoryName, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _actionButton(
            label: 'Message',
            icon: Icons.chat_bubble_outline,
            onTap: _onOpenChat,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BookingDetailsModel booking) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Information', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.person_outline, size: 28.sp, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(booking.categoryName, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _actionButton(
            label: 'Message Customer',
            icon: Icons.chat_bubble_outline,
            onTap: _onOpenChat,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptDeclineSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Action Required', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Booking Request', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white)),
                Text('Review the details and accept or decline this job', style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'Decline',
                  icon: Icons.close,
                  onTap: () => _onUpdateStatus(BookingStatus.cancelled),
                  secondary: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onUpdateStatus(BookingStatus.confirmed),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF22C55E), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20.sp, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text('Accept Job', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartJobButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: _actionButton(
        label: 'Start Job',
        icon: Icons.schedule,
        onTap: () => _onUpdateStatus(BookingStatus.inProgress),
      ),
    );
  }

  Widget _buildCompleteJobButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: _actionButton(
        label: 'Mark as Completed',
        icon: Icons.check_circle,
        onTap: () => _onUpdateStatus(BookingStatus.completed),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool secondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: secondary ? null : double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: secondary ? 20.w : 16.w),
          decoration: BoxDecoration(
            color: secondary ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.r),
            border: secondary ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
            boxShadow: secondary ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: secondary ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 20.sp, color: secondary ? Colors.white : const Color(0xFF003E93)),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: secondary ? Colors.white : const Color(0xFF003E93))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDetailsSection(BookingDetailsModel booking) {
    final date = _formatDate(booking.scheduledDate);
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Details', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(height: 12.h),
          _detailTile(
            icon: Icons.calendar_today_outlined,
            title: 'Date & Time',
            value: '$date at ${booking.scheduledTime}',
          ),
          SizedBox(height: 8.h),
          _detailTile(
            icon: Icons.location_on_outlined,
            title: 'Service Location',
            value: booking.townName,
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _detailTile(icon: Icons.description_outlined, title: 'Special Instructions', value: booking.notes!),
          ],
        ],
      ),
    );
  }

  String _formatDate(String scheduledDate) {
    try {
      final parts = scheduledDate.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          final dt = DateTime(y, m, d);
          const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
          return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, $y';
        }
      }
    } catch (_) {}
    return scheduledDate;
  }

  Widget _detailTile({required IconData icon, required String title, required String value}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: Colors.white),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.7))),
                SizedBox(height: 4.h),
                Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Payment section – matches React BookingDetails.tsx (397–452) + image: white text, white/20 cards, pills.
  Widget _buildPaymentSection(BookingDetailsModel booking) {
    final isPaid = booking.paymentStatus == PaymentStatus.paidInApp;
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          SizedBox(height: 12.h),
          _paymentRow('Payment Method', isPaid ? 'In-App Payment' : 'Cash on Completion', isPill: true, showIcon: isPaid),
          SizedBox(height: 8.h),
          _paymentRow('Status', 'Pay on Completion', isPill: true, isPaid: false),
          if (booking.totalAmount != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text('Payment Breakdown', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(height: 1, color: Colors.white.withOpacity(0.2)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
                      Text('\$${booking.totalAmount!.toStringAsFixed(2)}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(height: 1, color: Colors.white.withOpacity(0.2)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Renizo Service Fee', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
                          SizedBox(width: 6.w),
                          Icon(Icons.info_outline, size: 14.sp, color: Colors.white.withOpacity(0.6)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('-', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
                          Text('\$${(booking.totalAmount! * 0.1).toStringAsFixed(2)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                          Text(' (10%)', style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    ],
                  ),
                  if (isPaid && booking.status != BookingStatus.cancelled) ...[
                    SizedBox(height: 16.h),
                    _buildWarrantySection(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 30-Day Workmanship Warranty – nested inside Payment Breakdown card, per image: light blue-green box, white checkmark, bold title, lighter description.
  Widget _buildWarrantySection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 22.sp, color: Colors.white),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30-Day Workmanship Warranty',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 6.h),
                Text(
                  'All services include free warranty coverage for workmanship issues within 30 days of completion.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.85), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single row: bg-white/20 rounded-xl p-3. Label white/80, value in pill (rounded-full) white bold – matches React + image.
  Widget _paymentRow(String label, String value, {bool isPill = false, bool isPaid = false, bool showIcon = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
          if (isPill)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showIcon) ...[Icon(Icons.credit_card, size: 16.sp, color: Colors.white), SizedBox(width: 6.w)],
                  Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            )
          else
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
