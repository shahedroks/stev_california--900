import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Result of creating a payment intent: clientSecret to confirm on client,
/// or [alreadySucceeded] true when the server already confirmed the payment.
class PaymentIntentResult {
  const PaymentIntentResult({
    required this.clientSecret,
    this.alreadySucceeded = false,
  });
  final String clientSecret;
  final bool alreadySucceeded;
}

/// POST /payments/intent – returns clientSecret for Stripe confirmation.
/// Retries once on network/5xx errors.
/// If the API returns data.status == 'succeeded', payment is already done.
Future<PaymentIntentResult> createPaymentIntent({
  required String bookingId,
  String? paymentMethodId,
}) async {
  Future<PaymentIntentResult> attempt() async {
    final token = await AuthLocalStorage.getToken();
    final url = UserApi.paymentIntent;
    debugPrint('PaymentIntent: POST $url bookingId=$bookingId');
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'bookingId': bookingId,
            if (paymentMethodId != null && paymentMethodId.isNotEmpty)
              'paymentMethodId': paymentMethodId,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Payment request timed out'),
        );

    debugPrint('PaymentIntent: status=${res.statusCode} body=${res.body}');

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      throw Exception('Invalid response from server. Please try again.');
    }

    if (res.statusCode >= 400) {
      final msg =
          (decoded?['message'] ?? 'HTTP ${res.statusCode}').toString();
      throw Exception(msg);
    }

    final data = decoded?['data'] as Map<String, dynamic>?;
    final clientSecret = (data?['clientSecret'] ?? '').toString();
    if (clientSecret.isEmpty) {
      throw Exception('Missing payment details. Please try again.');
    }
    final alreadySucceeded =
        (data?['status'] ?? '').toString().toLowerCase() == 'succeeded';
    return PaymentIntentResult(
      clientSecret: clientSecret,
      alreadySucceeded: alreadySucceeded,
    );
  }

  try {
    return await attempt();
  } on SocketException {
    throw Exception('No internet connection. Check your network and try again.');
  } on TimeoutException {
    try {
      return await attempt();
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    }
  } on FormatException {
    throw Exception('Invalid response. Please try again.');
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception(e.toString());
  }
}
