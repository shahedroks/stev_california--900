import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/services/push_notification_service.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// After splash: no auth → Login; customer → onboarding/town then BottomNav; provider → SellerBottomNav.
void loginCheck(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 2));
  if (!context.mounted) return;
  final user = await AuthLocalStorage.getCurrentUser();
  if (user == null) {
    context.go(LoginScreen.routeName);
    return;
  }
  unawaited(PushNotificationService.syncTokenToBackend());
  if (user.isProvider) {
    context.go(ProviderAppScreen.routeName);
    return;
  }
  final hasOnboarded = await AuthLocalStorage.hasOnboarded(user.id);
  if (!hasOnboarded) {
    context.go(OnboardingSlidesScreen.routeName);
    return;
  }
  final town = await AuthLocalStorage.getSelectedTown(user.id);
  if (town == null || town.isEmpty) {
    context.go(TownSelectionScreen.routeName);
    return;
  }
  context.go(BottomNavBar.routeName);
}
