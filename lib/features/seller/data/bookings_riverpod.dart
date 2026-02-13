import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:renizo/features/bookings/data/bookings_mock_data.dart';

import '../logic/sellter_bookings_logic.dart';
import '../models/seller_bookings.dart';

final providerMyBookingsApiProvider = Provider<ProviderMyBookingsApi>((ref) {
  return ProviderMyBookingsApi();
});

final providerMyBookingsProvider =
    FutureProvider.autoDispose<ProviderMyBookingsData>((ref) async {
      final api = ref.watch(providerMyBookingsApiProvider);
      return api.fetchMyBookings();
    });

/// Single provider booking by id – GET /bookings/provider/:id for SellerBookingDetailsScreen.
final providerBookingByIdProvider = FutureProvider.autoDispose
    .family<BookingDetailsModel?, String>((ref, bookingId) async {
  final api = ref.watch(providerMyBookingsApiProvider);
  return api.fetchBookingById(bookingId);
});
