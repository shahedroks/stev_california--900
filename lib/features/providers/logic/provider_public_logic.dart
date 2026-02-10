import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/providers/models/provider_public_model.dart';

class ProviderPublicApi {
  Future<ProviderPublicData> fetchProvider(String providerUserId) async {
    final uri = Uri.parse(ProviderApi.publicProfile(providerUserId));
    final headers = await AuthLocalStorage.authHeaders();
    final res = await http.get(
      uri,
      headers: headers ?? {'Accept': 'application/json'},
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      throw Exception('Invalid JSON response from server');
    }

    final body =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (res.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }
    final status = (body['status'] ?? '').toString().toLowerCase();
    if (status != 'success') {
      final msg = body['message']?.toString() ?? 'Unexpected status: $status';
      throw Exception(msg);
    }

    return ProviderPublicResponse.fromJson(body).data;
  }
}

final providerPublicApiProvider = Provider<ProviderPublicApi>((ref) {
  return ProviderPublicApi();
});

final providerPublicProfileProvider =
    FutureProvider.family<ProviderPublicData, String>((ref, providerUserId) {
  return ref.watch(providerPublicApiProvider).fetchProvider(providerUserId);
});
