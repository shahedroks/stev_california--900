import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/models/user.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Edit Profile – name editable; email and phone read-only (display only).
/// Save calls PATCH /users/me with { "fullName": "..." } only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    this.onBack,
    this.onSave,
  });

  final User user;
  final VoidCallback? onBack;
  final void Function({String? name, String? email, String? phone, String? avatar})? onSave;

  static const String routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _avatarUrl;
  bool _isChanged = false;

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _headerBlue = Color(0xFF0060CF);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _avatarUrl = widget.user.avatar;
    _nameController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_isChanged && _nameController.text != widget.user.name) {
      setState(() => _isChanged = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_isChanged) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pop();
              },
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    } else {
      _pop();
    }
  }

  void _pop() {
    widget.onBack?.call();
    if (widget.onBack != null) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    widget.onSave?.call(name: name);
    if (widget.onSave != null) {
      _pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uri = Uri.parse(UserApi.me);
      final headers = await AuthLocalStorage.authHeaders();
      final response = await http.patch(
        uri,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode({'fullName': name}),
      );

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> body =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

      if (response.statusCode >= 400) {
        final msg = body['message']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }
      final status = (body['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        final msg =
            body['message']?.toString() ?? 'Unexpected status: $status';
        throw Exception(msg);
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final fullName = (data['fullName'] ?? name).toString();
        final email = (data['email'] ?? widget.user.email).toString();
        final phone = (data['phone'] ?? widget.user.phone).toString();
        final avatarUrl = data['avatarUrl']?.toString();
        await AuthLocalStorage.updateProfile(
          name: fullName,
          email: email,
          phone: phone,
          avatar: avatarUrl?.isNotEmpty == true ? avatarUrl : null,
        );
        widget.onSave?.call(
          name: fullName,
          email: email,
          phone: phone,
          avatar: avatarUrl?.isNotEmpty == true ? avatarUrl : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      _pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onAvatarTap() async {
    // Same as TSX: file input / pick image. For now show coming soon; can add image_picker later.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change photo – coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    SizedBox(height: 32.h),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _onBack,
            icon: Icon(Icons.arrow_back_ios_new, size: 22.sp, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Material(
            color: (_isChanged && !_isSaving)
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: (_isChanged && !_isSaving) ? _onSave : null,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: (_isChanged && !_isSaving)
                        ? const Color(0xFF003E93)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Same as EditProfileScreen.tsx: use user.avatar when set, else show placeholder image.
  String _avatarImageUrl() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) return _avatarUrl!;
    final u = widget.user;
    final seed = u.id.isNotEmpty ? u.id : (u.email.isNotEmpty ? u.email : u.name);
    return 'https://i.pravatar.cc/300?u=$seed';
  }

  Widget _buildAvatarSection() {
    final size = 112.0;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _avatarImageUrl(),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _avatarPlaceholder(size),
                  errorWidget: (_, __, ___) => _avatarPlaceholder(size),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: _onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.camera_alt,
                      size: 20.sp,
                      color: _bgBlue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'Tap to change photo',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(double size) {
    final name = widget.user.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                initial,
                style: TextStyle(
                  fontSize: 44.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.person,
                size: 56.sp,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _nameController,
          placeholder: 'Enter your full name',
          keyboardType: TextInputType.name,
        ),
        SizedBox(height: 20.h),
        _buildLabel('Email Address'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _emailController,
          placeholder: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
        ),
        SizedBox(height: 20.h),
        _buildLabel('Phone Number'),
        SizedBox(height: 8.h),
        _buildTextField(
          controller: _phoneController,
          placeholder: '+1 (555) 123-4567',
          keyboardType: TextInputType.phone,
          readOnly: true,
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _headerBlue,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            'Note: Your email and phone number are used for account security and communication with service providers.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required TextInputType keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 16.sp,
        color: readOnly ? const Color(0xFF6B7280) : const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 16.sp, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: readOnly
                ? const Color(0xFFE5E7EB)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: readOnly ? const Color(0xFFE5E7EB) : Colors.white,
            width: readOnly ? 1 : 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}
