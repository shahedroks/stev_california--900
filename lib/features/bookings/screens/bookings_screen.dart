
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
    if (v == 'pending' || v == 'pending_payment') return BookingStatus.pending;
    if (v == 'rejected') return BookingStatus.rejected;
    if (v == 'accepted') return BookingStatus.accepted;
    if (v == 'paid' || v == 'confirmed') return BookingStatus.confirmed;
    if (v == 'active' || v == 'inprogress' || v == 'in_progress') return BookingStatus.inProgress;
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
