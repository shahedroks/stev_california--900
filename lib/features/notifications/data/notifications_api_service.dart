import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/notifications_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/notifications/data/notifications_api_models.dart';

/// Notifications API service – list, mark read, mark all read.
class NotificationsApiService {
  Future<Map<String, String>?> _headers() async =>
      await AuthLocalStorage.authHeaders();

  /// GET /notifications – returns { data: { items: [...] } }
  Future<List<NotificationItem>> getNotifications() async {
    final headers = await _headers();
    if (headers == null) return [];
    final res = await http.get(
      Uri.parse(NotificationsApi.list),
      headers: headers,
    );
    if (res.statusCode != 200) return [];
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'];
      final items = data is Map ? data['items'] : null;
      if (items is! List) return [];
      return items
          .map(
            (e) => NotificationItem.fromApi(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// PATCH /notifications/:id/read – mark a single notification as read.
  Future<bool> markRead(String notificationId) async {
    if (notificationId.isEmpty) return false;
    final headers = await _headers();
    if (headers == null) return false;
    final res = await http.patch(
      Uri.parse(NotificationsApi.read(notificationId)),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  /// PATCH /notifications/read-all – mark all notifications as read.
  Future<bool> markAllRead() async {
    final headers = await _headers();
    if (headers == null) return false;
    final res = await http.patch(
      Uri.parse(NotificationsApi.readAll),
      headers: headers,
    );
    return res.statusCode == 200;
  }
}
