// lib/core/logic/towns_logic.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final townsControllerProvider = FutureProvider<List<Town>>((ref) async {
  final client = ref.watch(httpClientProvider);

  // ✅ token Future or String – দুটোই হলে কাজ করবে
  final token = await AuthLocalStorage.getToken();

  final res = await client.get(
    Uri.parse(UserApi.townApi),
    headers: {
      'Content-Type': 'application/json',
      if (token != null && token.toString().isNotEmpty)
        'Authorization': 'Bearer $token',
    },
  );

  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    throw Exception('Invalid response from server');
  }

  if (res.statusCode >= 400) {
    final msg = (decoded is Map<String, dynamic>)
        ? decoded['message']?.toString()
        : null;
    throw Exception(msg ?? 'Failed to load towns');
  }

  if (decoded is! Map<String, dynamic>) return <Town>[];
  final data = decoded['data'];
  if (data is! List) return <Town>[];

  return data.map((e) => Town.fromJson(e as Map<String, dynamic>)).toList();
});
