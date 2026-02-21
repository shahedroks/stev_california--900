import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/bookings/model/booking_detail_api_model.dart';

import '../models/seller_bookings.dart';

class ProviderMyBookingsApi {
  /// GET /bookings/provider/:bookingId – single booking details for provider (seller).
  Future<BookingDetailsModel?> fetchBookingById(String bookingId) async {
    final token = await AuthLocalStorage.getToken();
    final uri = Uri.parse(ProviderApi.bookingById(bookingId));
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;

    final api = BookingDetailApiModel.fromJson(data);
    return _mapApiToDetailsModelForProvider(api);
  }

  static BookingStatus _statusFromApi(String s) {
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

  static PaymentStatus _paymentStatusFromApi(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'paid' || v == 'paid_in_app') return PaymentStatus.paidInApp;
    if (v == 'paid_outside') return PaymentStatus.paidOutside;
    return PaymentStatus.unpaid;
  }

  static (String date, String time) _parseScheduledAt(String scheduledAt) {
    if (scheduledAt.isEmpty) return ('', '');
    try {
      final dt = DateTime.tryParse(scheduledAt);
      if (dt == null) return ('', '');
      final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return (date, time);
    } catch (_) {
      return ('', '');
    }
  }

  static BookingDetailsModel _mapApiToDetailsModelForProvider(BookingDetailApiModel api) {
    final (scheduledDate, scheduledTime) = _parseScheduledAt(api.scheduledAt);
    final p = api.price;
    return BookingDetailsModel(
      id: api.id,
      providerName: api.customerName?.trim().isNotEmpty == true ? api.customerName! : '—',
      providerAvatar: api.customerAvatarUrl?.trim() ?? '',
      categoryName: api.serviceName?.trim().isNotEmpty == true ? api.serviceName! : '—',
      townName: api.townName?.trim().isNotEmpty == true ? api.townName! : (api.address.city.isNotEmpty ? api.address.city : '—'),
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      address: api.address.displayAddress,
      notes: api.notes,
      status: _statusFromApi(api.status),
      paymentStatus: _paymentStatusFromApi(api.paymentStatus),
      totalAmount: p.totalCents > 0 ? p.totalAmount : null,
      renizoFeeAmount: p.renizoFeeCents > 0 ? p.renizoFeeAmount : null,
      renizoFeePercent: p.renizoFeePercent > 0 ? p.renizoFeePercent : null,
      currency: p.currency.isNotEmpty ? p.currency : null,
      basePriceAmount: p.totalCents > 0 ? p.basePriceCents / 100.0 : null,
      addonsTotalAmount: p.totalCents > 0 ? p.addonsTotalCents / 100.0 : null,
      providerPayoutAmount: p.totalCents > 0 ? p.providerPayoutCents / 100.0 : null,
      basePriceCents: p.basePriceCents,
      addonsTotalCents: p.addonsTotalCents,
      totalCents: p.totalCents,
      renizoFeeCents: p.renizoFeeCents,
      providerPayoutCents: p.providerPayoutCents,
    );
  }

  /// PATCH /bookings/:id/accept – provider accepts the booking.
  Future<void> acceptBooking(String bookingId) async {
    final token = await AuthLocalStorage.getToken();
    final uri = Uri.parse(ProviderApi.bookingAccept(bookingId));
    final res = await http.patch(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }
  }

  /// PATCH /bookings/:id/rejected – provider declines the booking.
  Future<void> rejectBooking(String bookingId) async {
    final token = await AuthLocalStorage.getToken();
    final uri = Uri.parse(ProviderApi.bookingReject(bookingId));
    final res = await http.patch(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }
  }

  /// PATCH /bookings/:id/complete – provider marks the booking as completed.
  Future<void> completeBooking(String bookingId) async {
    final token = await AuthLocalStorage.getToken();
    final uri = Uri.parse(ProviderApi.bookingComplete(bookingId));
    final res = await http.patch(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }
  }

  Future<ProviderMyBookingsData> fetchMyBookings() async {
    final token = await AuthLocalStorage.getToken();

    final uri = Uri.parse(ProviderApi.myBookings);
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final parsed = ProviderMyBookingsResponse.fromJson(
        decoded as Map<String, dynamic>,
      );
      return parsed.data;
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode})';

    throw Exception(msg);
  }
}
