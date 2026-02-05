import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/profile/model/user_model.dart';

class UserMeApi {
  Future<UserMeModel> fetchMe() async {
    final token = await AuthLocalStorage.getToken();

    final uri = Uri.parse(UserApi.me);

    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return UserMeModel.fromJson(decoded as Map<String, dynamic>);
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode})';

    throw Exception(msg);
  }
}

/// ✅ API instance provider
final userMeApiProvider = Provider<UserMeApi>((ref) {
  return UserMeApi();
});

/// ✅ Future provider (this is what you watch in UI)
final userMeProvider = FutureProvider<UserMeModel>((ref) async {
  return ref.watch(userMeApiProvider).fetchMe();
});
