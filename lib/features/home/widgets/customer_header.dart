import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';

/// Header blue from Header.tsx (bg-[#0060CF]). Used for bar and location text/icon.
const Color _headerBlue = Color(0xFF0060CF);

/// Customer app header – converted from React Header.tsx.
/// Blue bar with logo left, notification bell + red badge, location selector (bg-white/10, white text).
class CustomerHeader extends StatelessWidget {
  const CustomerHeader({
    super.key,
    this.leading,
    this.selectedTownName,
    this.onChangeTown,
    this.onNotifications,
    this.logoPath = 'assets/Renizo.png',
    this.onLogoTap,
  });

  /// Optional leading widget (e.g. back button) shown before the logo.
  final Widget? leading;
  /// Display name of selected town (e.g. "Terrace"). When null, location button can be hidden or show placeholder.
  final String? selectedTownName;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;
  final String logoPath;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _headerBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        border: Border(
          bottom: BorderSide(color: AllColor.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: 12.w),
            ],
            // Logo left (clickable)
            Expanded(
              child: Row(
                children: [
                  AppLogoButton(
                    size: 40,
                    logoPath: logoPath,
                    onTap: onLogoTap,
                  ),
                ],
              ),
            ),
            // Notifications + Location right (Header.tsx: notification bell + location button)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onNotifications != null)
                  _NotificationButton(onTap: onNotifications!),
                if (onNotifications != null || onChangeTown != null)
                  SizedBox(width: 8.w),
                if (onChangeTown != null)
                  _LocationButton(
                    townName: selectedTownName ?? 'Select location',
                    onTap: onChangeTown!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 24.sp,
                color: AllColor.white,
              ),
              Positioned(
                top: 2.h,
                right: 2.w,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Location button – matches Header.tsx lines 37–44: bg-white/10, white icon/text, chevron white/80.
class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.townName,
    required this.onTap,
  });

  final String townName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AllColor.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        hoverColor: AllColor.white.withOpacity(0.2),
        splashColor: AllColor.white.withOpacity(0.2),
        highlightColor: AllColor.white.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: AllColor.white,
              ),
              SizedBox(width: 8.w),
              Text(
                townName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AllColor.white,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16.sp,
                color: AllColor.white.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
