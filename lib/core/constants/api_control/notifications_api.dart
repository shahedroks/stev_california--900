import 'package:renizo/core/constants/api_control/global_api.dart';

/// Notifications API endpoints – GET list, PATCH read and read-all.
/// Auth: Bearer token required on all requests.
class NotificationsApi {
  static String get _base => '$api/notifications';
  static String get list => _base;
  static String read(String notificationId) => '$_base/$notificationId/read';
  static String get readAll => '$_base/read-all';
}
