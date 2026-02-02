import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/user.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/profile/screens/edit_profile_screen.dart';
import 'package:renizo/features/profile/screens/payment_methods_screen.dart';
import 'package:renizo/features/profile/screens/settings_screen.dart';
import 'package:renizo/features/profile/screens/help_support_screen.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/core/models/town.dart';

/// Profile – full conversion from React ProfileScreen.tsx.
/// Blue bg, profile card (avatar, name, email, stats), menu tiles, Log Out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.onChangeTown,
    this.onLogout,
    this.user,
    this.selectedTownName,
    this.selectedTownId,
  });

  final VoidCallback? onChangeTown;
  final VoidCallback? onLogout;
  final User? user;
  final String? selectedTownName;
  final String? selectedTownId;

  static const String routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _primaryBlue = Color(0xFF408AF1);

  Future<void> _onChangeTownHeader() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
        _selectedTownId = town.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing services in ${town.name}')),
        );
      }
    }
  }

  void _onNotifications() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthLocalStorage.getCurrentUser();
    if (mounted) setState(() => _user = user ?? widget.user);
  }

  User? get _displayUser => _user ?? widget.user;

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Town updated')));
    }
  }

  void _onLogout() async {
    widget.onLogout?.call();
    if (widget.onLogout != null) return;
    await AuthLocalStorage.clearSession();
    if (!mounted) return;
    context.go(LoginScreen.routeName);
  }

  void _onEditProfile() {
    if (!mounted) return;
    final user = _displayUser;
    if (user == null) return;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (context) => EditProfileScreen(
              user: user,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        )
        .then((_) {
          if (mounted) _loadUser();
        });
  }

  void _onPaymentMethods() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            PaymentMethodsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _onSettings() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            SettingsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _onHelpSupport() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            HelpSupportScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _displayUser;
    return Scaffold(
      backgroundColor: _bgBlue,
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTownHeader,
            onNotifications: _onNotifications,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(user),
                  SizedBox(height: 24.h),
                  _buildMenuTiles(),
                  SizedBox(height: 16.h),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'John Doe',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.email ?? 'john.doe@email.com',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Row(
              children: [
                _buildStat('12', 'Bookings'),
                Container(
                  width: 1,
                  height: 32.h,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStat('8', 'Reviews'),
                Container(
                  width: 1,
                  height: 32.h,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStat('4', 'Favorites'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    final size = 80.0;
    // Same as ProfileScreen.tsx: user.avatar ? <img src={user.avatar} /> : show placeholder image
    final String imageUrl;
    if (user?.avatar != null && user!.avatar!.isNotEmpty) {
      imageUrl = user.avatar!;
    } else {
      imageUrl = _placeholderAvatarUrl(user);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _avatarPlaceholder(size, user),
        errorWidget: (_, __, ___) => _avatarPlaceholder(size, user),
      ),
    );
  }

  /// Placeholder image URL when user has no avatar – shows a consistent profile image (same as TSX img fallback).
  String _placeholderAvatarUrl(User? user) {
    final seed = user?.id ?? user?.email ?? user?.name ?? 'profile';
    return 'https://i.pravatar.cc/300?u=$seed';
  }

  Widget _avatarPlaceholder(double size, User? user) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: user?.name != null && user!.name.isNotEmpty
          ? Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : Icon(Icons.person, size: 40.sp, color: Colors.white),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTiles() {
    final items = [
      _MenuItem(
        icon: Icons.person_outline,
        label: 'Edit Profile',
        iconColor: _primaryBlue,
        iconBg: _primaryBlue.withOpacity(0.1),
        onTap: _onEditProfile,
      ),
      _MenuItem(
        icon: Icons.location_on_outlined,
        label: 'Change Town',
        iconColor: const Color(0xFF16A34A),
        iconBg: const Color(0xFFF0FDF4),
        onTap: _onChangeTown,
      ),
      _MenuItem(
        icon: Icons.credit_card_outlined,
        label: 'Payment Methods',
        iconColor: const Color(0xFFDB2777),
        iconBg: const Color(0xFFFDF2F8),
        onTap: _onPaymentMethods,
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        iconColor: const Color(0xFF4B5563),
        iconBg: const Color(0xFFF9FAFB),
        onTap: _onSettings,
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Help & Support',
        iconColor: const Color(0xFFCA8A04),
        iconBg: const Color(0xFFFEFCE8),
        onTap: _onHelpSupport,
      ),
    ];
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _MenuTile(
                icon: item.icon,
                label: item.label,
                iconColor: item.iconColor,
                iconBg: item.iconBg,
                onTap: item.onTap,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: _onLogout,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20.sp, color: const Color(0xFFDC2626)),
              SizedBox(width: 8.w),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: iconColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AllColor.foreground,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: AllColor.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
