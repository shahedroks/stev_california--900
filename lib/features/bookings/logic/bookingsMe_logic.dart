import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/bookings_mock_data.dart';
import '../data/bookingsMe_data.dart';
import '../model/bookingsMe_model.dart';

final bookingsHttpClientProvider = Provider.autoDispose<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final bookingsMeRepositoryProvider = Provider.autoDispose<BookingsMeRepository>(
  (ref) {
    return BookingsMeRepository(ref.watch(bookingsHttpClientProvider));
  },
);

/// ✅ townId optional
final bookingsMeProvider = FutureProvider.autoDispose
    .family<BookingsMeData, String?>((ref, townId) async {
      final repo = ref.watch(bookingsMeRepositoryProvider);
      return repo.getMyBookings(townId: townId);
    });

/// Single booking by id – for BookingDetailsScreen (GET /bookings/:id).
final bookingByIdProvider = FutureProvider.autoDispose
    .family<BookingDetailsModel?, String>((ref, bookingId) async {
      final repo = ref.watch(bookingsMeRepositoryProvider);
      return repo.getBookingById(bookingId);
    });
