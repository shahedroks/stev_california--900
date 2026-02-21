import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';

/// Stripe SDK bootstrap – fetch publishable key from backend and init Stripe.
class StripeService {
  static bool _initialized = false;
  static String? _publishableKey;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final key = await _fetchPublishableKey();
    if (key.isEmpty) {
      throw Exception('Stripe publishable key is not set');
    }
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  static Future<String> _fetchPublishableKey() async {
    if (_publishableKey != null && _publishableKey!.isNotEmpty) {
      return _publishableKey!;
    }
    final res = await http.get(Uri.parse(UserApi.paymentConfig));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
    if (res.statusCode >= 400) {
      final msg = (decoded?['message'] ?? 'HTTP ${res.statusCode}').toString();
      throw Exception(msg);
    }
    final data = decoded?['data'] as Map<String, dynamic>?;
    final key = (data?['publishableKey'] ?? '').toString();
    _publishableKey = key;
    return key;
  }
}
