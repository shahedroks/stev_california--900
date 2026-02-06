import 'package:renizo/core/constants/api_control/global_api.dart';

class UserApi {
  static final String _base_api = "$api/users";
  static final String me = "$_base_api/me";
  static final String townApi = "$api/towns/all";
}
