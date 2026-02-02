import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/seller/screens/seller_bookings_screen.dart';
import 'package:renizo/features/seller/screens/seller_earnings_screen.dart';
import 'package:renizo/features/seller/screens/seller_home_screen.dart';
import 'package:renizo/features/seller/screens/seller_messages_screen.dart';
import 'package:renizo/features/seller/screens/seller_profile_screen.dart';

final sellerSelectedIndexProvider = StateProvider<int>((ref) => 0);

/// Seller/Provider app bottom nav – converted from React ProviderApp + SellerBottomNav.
class SellerBottomNav extends ConsumerWidget {
  const SellerBottomNav({super.key});
  static const String routeName = '/seller';

  static const List<Widget> _pages = [
    SellerHomeScreen(),
    SellerBookingsScreen(),
    SellerMessagesScreen(),
    SellerEarningsScreen(),
    SellerProfileScreen(),

    
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(sellerSelectedIndexProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => ref.read(sellerSelectedIndexProvider.notifier).state = i,
        backgroundColor: AllColor.white,
        selectedItemColor: AllColor.primary,
        unselectedItemColor: AllColor.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
