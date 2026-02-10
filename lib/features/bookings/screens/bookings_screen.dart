// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
// import 'package:renizo/features/bookings/screens/booking_details_screen.dart';
// import 'package:renizo/features/bookings/screens/task_submission_screen.dart';
//
// /// Bookings list – full conversion from React BookingsScreen.tsx.
// /// Blue background, loading spinner, "My Bookings", list of BookingCard or empty state with Create button.
// class BookingsScreen extends StatefulWidget {
//   const BookingsScreen({
//     super.key,
//     this.customerId = 'customer1',
//     this.onCreateNew,
//     this.onSelectBooking,
//   });
//
//   final String customerId;
//   final VoidCallback? onCreateNew;
//   final void Function(String bookingId)? onSelectBooking;
//
//   @override
//   State<BookingsScreen> createState() => _BookingsScreenState();
// }
//
// class _BookingsScreenState extends State<BookingsScreen> {
//   List<BookingDisplayItem> _bookings = [];
//   bool _loading = true;
//
//   static const Color _bgBlue = Color(0xFF2384F4);
//
//   Future<void> _loadBookings() async {
//     setState(() => _loading = true);
//     final list = await loadBookingsForCustomer(widget.customerId);
//     if (!mounted) return;
//     setState(() {
//       _bookings = list;
//       _loading = false;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBookings();
//   }
//
//   void _onCreateNew() {
//     widget.onCreateNew?.call();
//     if (widget.onCreateNew != null) return;
//     if (!mounted) return;
//     Navigator.of(context).push<void>(
//       MaterialPageRoute<void>(
//         builder: (context) => TaskSubmissionScreen(
//           selectedTownId: '',
//           onSubmit: (_) {
//             if (!context.mounted) return;
//             Navigator.of(context).pop();
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Booking created')),
//             );
//             _loadBookings();
//           },
//         ),
//       ),
//     );
//   }
//
//   void _openBookingDetails(String bookingId) {
//     widget.onSelectBooking?.call(bookingId);
//     if (!mounted) return;
//     Navigator.of(context).push<void>(
//       MaterialPageRoute<void>(
//         builder: (context) => BookingDetailsScreen(
//           bookingId: bookingId,
//           onBack: () => Navigator.of(context).pop(),
//           onOpenChat: (id) {
//             if (!context.mounted) return;
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Open chat for $id')),
//             );
//           },
//           onUpdateBooking: (id, status) {
//             if (!context.mounted) return;
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Booking ${status.name}')),
//             );
//           },
//           userRole: UserRole.customer,
//         ),
//       ),
//     ).then((_) {
//       if (mounted) _loadBookings();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         backgroundColor: _bgBlue,
//         body: Center(
//           child: SizedBox(
//             width: 48.w,
//             height: 48.h,
//             child: CircularProgressIndicator(
//               strokeWidth: 3,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: _bgBlue,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Padding(
//               padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'My Bookings',
//                     style: TextStyle(
//                       fontSize: 20.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 4.h),
//                   Text(
//                     '${_bookings.length} total bookings',
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       color: Colors.white.withOpacity(0.8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: _bookings.isEmpty ? _buildEmptyState() : _buildBookingList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'No bookings yet',
//               style: TextStyle(fontSize: 16.sp, color: Colors.white.withOpacity(0.8)),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16.h),
//             Material(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12.r),
//               elevation: 4,
//               shadowColor: Colors.black.withOpacity(0.2),
//               child: InkWell(
//                 onTap: _onCreateNew,
//                 borderRadius: BorderRadius.circular(12.r),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
//                   child: Text(
//                     'Create Your First Booking',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: const Color(0xFF408AF1),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBookingList() {
//     return ListView.builder(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
//       itemCount: _bookings.length,
//       itemBuilder: (context, index) {
//         final booking = _bookings[index];
//         return Padding(
//           padding: EdgeInsets.only(bottom: 12.h),
//           child: BookingCard(
//             booking: booking,
//             onSelect: () => _openBookingDetails(booking.id),
//           ),
//         );
//       },
//     );
//   }
// }
//
// /// Single booking card – mirrors React BookingCard (white rounded-2xl, avatar, name, category, status, date/time).
// class BookingCard extends StatefulWidget {
//   const BookingCard({
//     super.key,
//     required this.booking,
//     required this.onSelect,
//   });
//
//   final BookingDisplayItem booking;
//   final VoidCallback onSelect;
//
//   @override
//   State<BookingCard> createState() => _BookingCardState();
// }
//
// class _BookingCardState extends State<BookingCard> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacity;
//   late Animation<Offset> _slide;
//   bool _imageError = false;
//
//   static const Color _gradientStart = Color(0xFF408AF1);
//   static const Color _gradientEnd = Color(0xFF5ca3f5);
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _opacity = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );
//     _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   (Color bg, Color text) _statusColors(BookingStatus status) {
//     switch (status) {
//       case BookingStatus.pending:
//         return (const Color(0xFFFEF3C7), const Color(0xFFB45309)); // yellow-100, yellow-700
//       case BookingStatus.confirmed:
//         return (const Color(0xFFDCFCE7), const Color(0xFF15803D)); // green-100, green-700
//       case BookingStatus.inProgress:
//         return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)); // blue-100, blue-700
//       case BookingStatus.completed:
//         return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
//       case BookingStatus.cancelled:
//         return (const Color(0xFFF3F4F6), const Color(0xFF374151)); // gray-100, gray-700
//     }
//   }
//
//   String _statusLabel(BookingStatus status) {
//     switch (status) {
//       case BookingStatus.pending:
//         return 'Pending';
//       case BookingStatus.confirmed:
//         return 'Confirmed';
//       case BookingStatus.inProgress:
//         return 'In Progress';
//       case BookingStatus.completed:
//         return 'Completed';
//       case BookingStatus.cancelled:
//         return 'Cancelled';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final b = widget.booking;
//     final initial = b.providerName.isNotEmpty ? b.providerName[0].toUpperCase() : '?';
//     final (statusBg, statusText) = _statusColors(b.status);
//
//     return FadeTransition(
//       opacity: _opacity,
//       child: SlideTransition(
//         position: _slide,
//         child: Material(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16.r),
//           elevation: 2,
//           shadowColor: Colors.black.withOpacity(0.08),
//           child: InkWell(
//             onTap: widget.onSelect,
//             borderRadius: BorderRadius.circular(16.r),
//             child: Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16.r),
//                 border: Border.all(color: const Color(0xFFF3F4F6)),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12.r),
//                         child: Container(
//                           width: 48.w,
//                           height: 48.h,
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [_gradientStart, _gradientEnd],
//                             ),
//                           ),
//                           child: b.providerAvatar.isNotEmpty && !_imageError
//                               ? CachedNetworkImage(
//                                   imageUrl: b.providerAvatar,
//                                   fit: BoxFit.cover,
//                                   placeholder: (_, __) => Center(
//                                     child: Text(
//                                       initial,
//                                       style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
//                                     ),
//                                   ),
//                                   errorWidget: (_, __, ___) {
//                                     WidgetsBinding.instance.addPostFrameCallback((_) {
//                                       if (mounted) setState(() => _imageError = true);
//                                     });
//                                     return Center(
//                                       child: Text(
//                                         initial,
//                                         style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
//                                       ),
//                                     );
//                                   },
//                                 )
//                               : Center(
//                                   child: Text(
//                                     initial,
//                                     style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
//                                   ),
//                                 ),
//                         ),
//                       ),
//                       SizedBox(width: 12.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               b.providerName,
//                               style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black87),
//                             ),
//                             SizedBox(height: 4.h),
//                             Text(
//                               b.categoryName,
//                               style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//                         decoration: BoxDecoration(
//                           color: statusBg,
//                           borderRadius: BorderRadius.circular(999.r),
//                         ),
//                         child: Text(
//                           _statusLabel(b.status),
//                           style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: statusText),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 12.h),
//                   Row(
//                     children: [
//                       Icon(Icons.calendar_today_outlined, size: 16.sp, color: Colors.grey.shade600),
//                       SizedBox(width: 6.w),
//                       Text(b.date, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
//                       SizedBox(width: 16.w),
//                       Icon(Icons.access_time, size: 16.sp, color: Colors.grey.shade600),
//                       SizedBox(width: 6.w),
//                       Text(b.time, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

////......<<<<>BookingScreen<<<<<<<<.........................................>

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/bookings/screens/booking_details_screen.dart';
import 'package:renizo/features/bookings/screens/task_submission_screen.dart';

import '../bookingsCard.dart';
import '../logic/bookingsMe_logic.dart';
import '../model/bookingsMe_model.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({
    super.key,
    this.townId,
    this.onCreateNew,
    this.onSelectBooking,
  });

  final String? townId; // ✅ optional
  final VoidCallback? onCreateNew;
  final void Function(String bookingId)? onSelectBooking;

  static const Color _bgBlue = Color(0xFF2384F4);

  BookingStatus _parseStatus(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'pending') return BookingStatus.pending;
    if (v == 'confirmed') return BookingStatus.confirmed;
    if (v == 'active') return BookingStatus.inProgress;
    if (v == 'inprogress' || v == 'in_progress')
      return BookingStatus.inProgress;
    if (v == 'completed') return BookingStatus.completed;
    if (v == 'cancelled' || v == 'canceled') return BookingStatus.cancelled;
    return BookingStatus.pending;
  }

  BookingDisplayItem _toDisplay(BookingsMeItem it) {
    return BookingDisplayItem(
      id: it.id,
      providerName: it.providerName.isEmpty ? '—' : it.providerName,
      providerAvatar: it.providerAvatar,
      categoryName: it.categoryName.isEmpty ? '—' : it.categoryName,
      status: _parseStatus(it.status),
      date: it.scheduledDate.isEmpty ? '—' : it.scheduledDate,
      time: it.scheduledTime.isEmpty ? '—' : it.scheduledTime,
    );
  }

  Future<void> _defaultCreateFlow(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskSubmissionScreen(
          selectedTownId: townId ?? '',
          onSubmit: (_) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Booking created')));
          },
        ),
      ),
    );

    // ✅ back/submit এর পর refresh
    ref.invalidate(bookingsMeProvider(townId));
  }

  Future<void> _openBookingDetails(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailsScreen(
          bookingId: bookingId,
          onBack: () => Navigator.of(context).pop(),
          onOpenChat: (id) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Open chat for $id')));
          },
          onUpdateBooking: (id, status) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Booking ${status.name}')));
          },
          userRole: UserRole.customer,
        ),
      ),
    );

    // ✅ details থেকে back হলে refresh
    ref.invalidate(bookingsMeProvider(townId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingsMeProvider(townId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: _bgBlue,
        body: Center(
          child: SizedBox(
            width: 48.w,
            height: 48.h,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bgBlue,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load bookings',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () => ref.invalidate(bookingsMeProvider(townId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (data) {
        final bookings = data.items.map(_toDisplay).toList();

        return Scaffold(
          backgroundColor: _bgBlue,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${data.meta.total} total bookings',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: bookings.isEmpty
                      ? _EmptyState(
                          onCreateNew: () {
                            if (onCreateNew != null) {
                              onCreateNew!.call();
                              return;
                            }
                            _defaultCreateFlow(context, ref);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          itemCount: bookings.length,
                          itemBuilder: (context, i) {
                            final b = bookings[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: BookingCard(
                                booking: b,
                                onSelect: () {
                                  if (onSelectBooking != null) {
                                    onSelectBooking!.call(b.id);
                                    return;
                                  }
                                  _openBookingDetails(context, ref, b.id);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateNew});
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              child: InkWell(
                onTap: onCreateNew,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 14.h,
                  ),
                  child: Text(
                    'Create Your First Booking',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF408AF1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
