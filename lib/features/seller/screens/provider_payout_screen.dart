import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Provider payout (Stripe Connect) setup screen.
class ProviderPayoutScreen extends StatefulWidget {
  const ProviderPayoutScreen({super.key});

  @override
  State<ProviderPayoutScreen> createState() => _ProviderPayoutScreenState();
}

class _ProviderPayoutScreenState extends State<ProviderPayoutScreen> {
  final _accountIdController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _accountIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final accountId = _accountIdController.text.trim();
    if (accountId.isEmpty || !accountId.startsWith('acct_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Stripe account ID')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final token = await AuthLocalStorage.getToken();
      final res = await http.patch(
        Uri.parse(ProviderApi.providerPayout),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'accountId': accountId}),
      );
      final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode >= 400) {
        final msg = (decoded?['message'] ?? 'HTTP ${res.statusCode}').toString();
        throw Exception(msg);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout account saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Provider Payout'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stripe Connect Account ID',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _accountIdController,
              decoration: InputDecoration(
                hintText: 'acct_1234abcd...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 18.h,
                        width: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Payout Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
