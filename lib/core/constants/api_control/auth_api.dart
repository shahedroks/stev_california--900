import 'global_api.dart';

class AuthAPIController {
  static final String _base_api = "$api/users";
  static String allUsers = "$_base_api/all";
  static String singleUser(String id) => "$_base_api/$id";
  static String userLogin = "$_base_api/login";
  static String userSignUp = "$_base_api/signup";

  /// POST /api/v1/auth/login – email + password
  static String get authLogin => "$api/auth/login";

  /// PATCH /api/v1/users/me/fcm-token – save device token for push notifications.
  static String get meFcmToken => "$_base_api/me/fcm-token";
}
