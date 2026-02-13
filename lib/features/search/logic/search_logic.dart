import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

import '../models/search_api_models.dart';

// ─── HTTP client (auto-dispose) ──────────────────────────────────────────────

final searchHttpClientProvider = Provider.autoDispose<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

// ─── Repository ──────────────────────────────────────────────────────────────

class SearchRepository {
  final http.Client _client;
  SearchRepository(this._client);

  /// GET /search?q=...&townId=...&type=all|providers|services
  Future<SearchApiData> search({
    required String q,
    required String townId,
    String type = 'all',
  }) async {
    final uri = UserApi.searchUri(q: q.trim(), townId: townId, type: type);

    try {
      final headers = await AuthLocalStorage.authHeaders();
      final response = await _client.get(
        uri,
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      // ── invalid JSON guard ─────────────────────────────────────────────
      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw const FormatException('Invalid JSON response from server');
      }

      final body =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

      // ── HTTP error ─────────────────────────────────────────────────────
      if (response.statusCode >= 400) {
        final msg =
            body['message']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }

      // ── API-level status check ─────────────────────────────────────────
      final status = (body['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        final msg = body['message']?.toString() ?? 'Unexpected status: $status';
        throw Exception(msg);
      }

      final parsed = SearchApiResponse.fromJson(body);
      return parsed.data;
    } on SocketException {
      throw Exception('ইন্টারনেট সংযোগ নেই। আপনার নেটওয়ার্ক চেক করুন।');
    } on FormatException catch (e) {
      throw Exception(e.message);
    }
  }

  /// GET /catalog/services – returns list of services (same shape as search services).
  Future<List<SearchApiService>> fetchCatalogServices() async {
    try {
      final headers = await AuthLocalStorage.authHeaders();
      final response = await _client.get(
        Uri.parse(ProviderApi.catalogServices),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw const FormatException('Invalid JSON response from server');
      }

      final body =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

      if (response.statusCode >= 400) {
        final msg =
            body['message']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }

      final status = (body['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        final msg = body['message']?.toString() ?? 'Unexpected status: $status';
        throw Exception(msg);
      }

      final data = body['data'];
      if (data is! List) return [];

      final list = data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((e) => e['isActive'] != false)
          .map(SearchApiService.fromJson)
          .toList();
      return list;
    } on SocketException {
      throw Exception('ইন্টারনেট সংযোগ নেই। আপনার নেটওয়ার্ক চেক করুন।');
    } on FormatException catch (e) {
      throw Exception(e.message);
    }
  }
}

final searchRepositoryProvider = Provider.autoDispose<SearchRepository>((ref) {
  return SearchRepository(ref.watch(searchHttpClientProvider));
});

// ─── Catalog services (for search screen – services from this API) ─────────────

final catalogServicesProvider = AsyncNotifierProvider.autoDispose
    <CatalogServicesController, List<SearchApiService>>(
  CatalogServicesController.new,
);

class CatalogServicesController
    extends AutoDisposeAsyncNotifier<List<SearchApiService>> {
  @override
  Future<List<SearchApiService>> build() async {
    final repo = ref.watch(searchRepositoryProvider);
    return repo.fetchCatalogServices();
  }
}

// ─── Controller (AsyncNotifier family keyed by SearchParams) ─────────────────

final searchControllerProvider = AsyncNotifierProvider.autoDispose
    .family<SearchController, SearchApiData, SearchParams>(
  SearchController.new,
);

class SearchController
    extends AutoDisposeFamilyAsyncNotifier<SearchApiData, SearchParams> {
  @override
  Future<SearchApiData> build(SearchParams arg) async {
    // If query is empty, return empty data immediately (no API call)
    if (arg.query.trim().isEmpty) {
      return const SearchApiData(providers: [], services: []);
    }

    final repo = ref.watch(searchRepositoryProvider);
    return repo.search(
      q: arg.query,
      townId: arg.townId,
      type: arg.type,
    );
  }

  /// Force-refresh for current params.
  Future<void> refresh() async {
    if (arg.query.trim().isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(searchRepositoryProvider).search(
            q: arg.query,
            townId: arg.townId,
            type: arg.type,
          ),
    );
  }
}
