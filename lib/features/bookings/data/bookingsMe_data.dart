import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

import '../model/bookingsMe_model.dart';

class BookingsMeRepository {
  final http.Client _client;
  BookingsMeRepository(this._client);

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
