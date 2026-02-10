import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/user.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/providers/auth_provider.dart';
import 'package:renizo/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';

/// Register – converted from React RegisterScreen.tsx.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  static const String routeName = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  UserRole _role = UserRole.customer;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    // Reset previous state
    ref.read(signupProvider.notifier).reset();

    // Call signup API
    await ref.read(signupProvider.notifier).signup(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          role: _role == UserRole.provider ? 'provider' : 'user',
        );

    if (!mounted) return;

    final signupState = ref.read(signupProvider);

    if (signupState.isSuccess) {
      // Navigate based on role
      final user = await AuthLocalStorage.getCurrentUser();
      if (user == null) return;
      if (user.isProvider) {
        context.push(ProviderAppScreen.routeName);
      } else {
        context.push(OnboardingSlidesScreen.routeName);
      }
    } else if (signupState.error != null) {
      _showError(signupState.error!);
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AllColor.destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupProvider);

    return Scaffold(
      backgroundColor: AllColor.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: AllColor.white, size: 20.sp),
                label: Text('Back to Login', style: TextStyle(color: AllColor.white, fontSize: 14.sp)),
              ),
              SizedBox(height: 16.h),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(color: AllColor.white, borderRadius: BorderRadius.circular(24.r)),
                      child: Icon(Icons.person_add, size: 40.sp, color: AllColor.primary),
                    ),
                    SizedBox(height: 16.h),
                    Text('Create Account', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AllColor.white)),
                    SizedBox(height: 8.h),
                    Text('Join our service marketplace', style: TextStyle(fontSize: 14.sp, color: AllColor.white.withOpacity(0.9))),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text('I want to:', style: TextStyle(fontSize: 14.sp, color: AllColor.white)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      emoji: '👤',
                      title: 'Find Services',
                      sub: 'Customer',
                      selected: _role == UserRole.customer,
                      onTap: () => setState(() => _role = UserRole.customer),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _roleCard(
                      emoji: '🔧',
                      title: 'Offer Services',
                      sub: 'Provider',
                      selected: _role == UserRole.provider,
                      onTap: () => setState(() => _role = UserRole.provider),
                    ),
                  ),
                ],
              ),
              if (signupState.error != null) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: AllColor.destructive.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)),
                  child: Text(signupState.error!, style: TextStyle(fontSize: 14.sp, color: AllColor.white)),
                ),
              ],
              SizedBox(height: 16.h),
              _input('Full Name', _nameController, Icons.person),
              SizedBox(height: 12.h),
              _input('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
              SizedBox(height: 12.h),
              _input('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              SizedBox(height: 12.h),
              _input('Password', _passwordController, Icons.lock, obscure: _obscurePassword, onSuffix: () => setState(() => _obscurePassword = !_obscurePassword)),
              SizedBox(height: 12.h),
              _input('Confirm Password', _confirmController, Icons.lock, obscure: true),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: signupState.isLoading ? null : _register,
                  style: FilledButton.styleFrom(backgroundColor: AllColor.white, foregroundColor: AllColor.primary, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                  child: signupState.isLoading ? SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(strokeWidth: 2, color: AllColor.primary)) : Text('Create Account', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({required String emoji, required String title, required String sub, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected ? AllColor.white : AllColor.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? AllColor.white : AllColor.white.withOpacity(0.4), width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24.sp)),
            SizedBox(height: 4.h),
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: selected ? AllColor.primary : AllColor.white)),
            Text(sub, style: TextStyle(fontSize: 12.sp, color: selected ? AllColor.primary.withOpacity(0.8) : AllColor.white70)),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, IconData icon, {bool obscure = false, VoidCallback? onSuffix, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AllColor.mutedForeground),
        suffixIcon: onSuffix != null ? IconButton(icon: Icon(Icons.visibility, color: AllColor.mutedForeground), onPressed: onSuffix) : null,
        filled: true,
        fillColor: AllColor.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
      style: TextStyle(fontSize: 16.sp, color: AllColor.foreground),
    );
  }
}
