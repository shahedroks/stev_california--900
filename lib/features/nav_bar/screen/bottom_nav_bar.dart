import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/bookings/screens/bookings_screen.dart';
import 'package:renizo/features/home/screens/customer_home_screen.dart';
import 'package:renizo/features/messages/screens/messages_screen.dart';
import 'package:renizo/features/profile/screens/profile_screen.dart';
import 'package:renizo/features/search/screens/search_screen.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom nav colors and style – matches React BottomNav.tsx.
const Color _navBackground = Color(0xFF003E93);
const Color _navSelectedStart = Color(0xFF408AF1);
const Color _navSelectedEnd = Color(0xFF5ca3f5);
const Color _navUnselected = Color(0xB3FFFFFF); // white/70

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});
  static const String routeName = '/BottomNavBar';
  static List<Widget> _pages = [
    CustomerHomeScreen(),
    SearchScreen(),
    BookingsScreen(),
    //  BookingsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  /// Tabs and icons match image: Home, Search, Bookings, Messages, Profile.
  static const List<_NavItem> _tabs = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.search_rounded, label: 'Search'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _pages),
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: selectedIndex,
        onTabTap: (index) =>
            ref.read(selectedIndexProvider.notifier).state = index,
      ),
    );
  }
}

/// Reusable bottom nav bar – same look as BottomNavBar; use for CustomerHomeScreen-style screens.
class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;

  static const List<_NavItem> _tabs = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.search_rounded, label: 'Search'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _navBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 5, left: 16.w, right: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = currentIndex == index;
              return _NavBarItem(
                icon: tab.icon,
                label: tab.label,
                isActive: isActive,
                onTap: () => onTabTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: isActive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_navSelectedStart, _navSelectedEnd],
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: isActive ? Colors.white : _navUnselected,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  color: isActive ? Colors.white : _navUnselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
