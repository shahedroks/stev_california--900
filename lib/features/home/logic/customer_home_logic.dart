import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

import '../models/customer_home_models.dart';

// ─── HTTP client (auto-dispose) ──────────────────────────────────────────────

final customerHomeHttpClientProvider = Provider.autoDispose<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

// ─── Repository ──────────────────────────────────────────────────────────────

class CustomerHomeRepository {
  final http.Client _client;
  CustomerHomeRepository(this._client);

  /// GET /customer/home?townId=<townId>
  Future<CustomerHomeData> fetchCustomerHome({required String townId}) async {
    final uri = UserApi.customerHomeUri(townId);

    final headers = await AuthLocalStorage.authHeaders();
    final response = await _client.get(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'},
    );

    // ── invalid JSON guard ───────────────────────────────────────────────
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid JSON response from server');
    }

    final body =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    // ── HTTP error ───────────────────────────────────────────────────────
    if (response.statusCode >= 400) {
      final msg = body['message']?.toString() ?? 'HTTP ${response.statusCode}';
      throw Exception(msg);
    }

    // ── API-level status check ───────────────────────────────────────────
    final status = (body['status'] ?? '').toString().toLowerCase();
    if (status != 'success') {
      final msg = body['message']?.toString() ?? 'Unexpected status: $status';
      throw Exception(msg);
    }

    final parsed = CustomerHomeResponse.fromJson(body);
    return parsed.data;
  }
}

final customerHomeRepositoryProvider =
    Provider.autoDispose<CustomerHomeRepository>((ref) {
  return CustomerHomeRepository(ref.watch(customerHomeHttpClientProvider));
});

// ─── Controller (AsyncNotifier family keyed by townId) ───────────────────────

final customerHomeControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerHomeController, CustomerHomeData, String>(
  CustomerHomeController.new,
);

class CustomerHomeController
    extends AutoDisposeFamilyAsyncNotifier<CustomerHomeData, String> {
  @override
  Future<CustomerHomeData> build(String arg) async {
    final repo = ref.watch(customerHomeRepositoryProvider);
    return repo.fetchCustomerHome(townId: arg);
  }

  /// Force-refresh data for the current townId.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(customerHomeRepositoryProvider)
          .fetchCustomerHome(townId: arg),
    );
  }
}
