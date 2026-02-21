import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/profile/model/payment_method_model.dart';

/// Fetches GET /payments/methods and returns list of saved payment methods.
Future<List<PaymentMethodApiModel>> fetchPaymentMethods() async {
  final token = await AuthLocalStorage.getToken();
  final uri = Uri.parse(UserApi.paymentMethods);
  final res = await http.get(
    uri,
    headers: {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    final msg = (decoded != null && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load payment methods (${res.statusCode})';
    throw Exception(msg);
  }
  final data = decoded?['data'] as Map<String, dynamic>?;
  final list = data?['methods'] as List<dynamic>?;
  if (list == null) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => PaymentMethodApiModel.fromJson(e))
      .toList();
}

/// POST /payments/methods with { "paymentMethodId": "pm_xxx" }.
Future<void> addPaymentMethod(String paymentMethodId) async {
  final token = await AuthLocalStorage.getToken();
  final uri = Uri.parse(UserApi.paymentMethods);
  final res = await http.post(
    uri,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'paymentMethodId': paymentMethodId}),
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 201) {
    final msg = (decoded != null && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to add payment method (${res.statusCode})';
    throw Exception(msg);
  }
}

/// PATCH /payments/methods/:id/default.
Future<void> setDefaultPaymentMethod(String id) async {
  final token = await AuthLocalStorage.getToken();
  final uri = Uri.parse(UserApi.paymentMethodSetDefault(id));
  final res = await http.patch(
    uri,
    headers: {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    final msg = (decoded != null && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to set default (${res.statusCode})';
    throw Exception(msg);
  }
}

/// DELETE /payments/methods/:id.
Future<void> deletePaymentMethod(String id) async {
  final token = await AuthLocalStorage.getToken();
  final uri = Uri.parse(UserApi.paymentMethodById(id));
  final res = await http.delete(
    uri,
    headers: {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 204) {
    final msg = (decoded != null && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to remove payment method (${res.statusCode})';
    throw Exception(msg);
  }
}

/// Provider for saved payment methods list. Refetch via ref.invalidate.
final paymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethodApiModel>>((ref) {
  return fetchPaymentMethods();
});
