import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

import '../data/bookings_mock_data.dart';
import '../model/booking_detail_api_model.dart';
import '../model/bookingsMe_model.dart';

class BookingsMeRepository {
  final http.Client _client;
  BookingsMeRepository(this._client);

  /// GET /bookings/:id – single booking details for BookingDetailsScreen.
  Future<BookingDetailsModel?> getBookingById(String bookingId) async {
    final uri = Uri.parse(UserApi.bookingById(bookingId));
    final req = http.Request('GET', uri);
    final headers = await AuthLocalStorage.authHeaders();
    if (headers != null) req.headers.addAll(headers);
    req.headers['Content-Type'] = 'application/json';

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;

    final api = BookingDetailApiModel.fromJson(data);
    return _mapApiToDetailsModel(api);
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

  static BookingDetailsModel _mapApiToDetailsModel(BookingDetailApiModel api) {
    final (scheduledDate, scheduledTime) = _parseScheduledAt(api.scheduledAt);
    final p = api.price;
    return BookingDetailsModel(
      id: api.id,
      providerName: api.providerName?.trim().isNotEmpty == true ? api.providerName! : '—',
      providerAvatar: api.providerLogoUrl?.trim() ?? '',
      categoryName: api.serviceName?.trim().isNotEmpty == true ? api.serviceName! : '—',
      townName: api.townName?.trim().isNotEmpty == true ? api.townName! : api.address.city.isNotEmpty ? api.address.city : '—',
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

  /// ✅ GET /bookings/me (townId optional; backend body নেয়)
  Future<BookingsMeData> getMyBookings({String? townId}) async {
    final uri = Uri.parse(UserApi.bookingsMe);

    final req = http.Request('GET', uri);

    final headers = await AuthLocalStorage.authHeaders();
    if (headers != null) {
      req.headers.addAll(headers);
    }

    // always set content-type so backend can parse JSON body
    req.headers['Content-Type'] = 'application/json';

    if (townId != null && townId.trim().isNotEmpty) {
      req.body = jsonEncode({'townId': townId.trim()});
    }

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);

    final decoded = jsonDecode(res.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const BookingsMeData(
        items: [],
        meta: BookingsMeMeta(total: 0, page: 1, limit: 20),
      );
    }

    return BookingsMeData.fromJson(data);
  }
}
