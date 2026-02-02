import 'package:go_router/go_router.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/core/widget/global_snack_bar.dart';
import 'package:renizo/features/auth/screens/home_screen.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/auth/screens/register_screen.dart';
import 'package:renizo/features/auth/screens/splash_screen.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';
import 'package:renizo/features/home/screens/customer_home_screen.dart';

import 'error_screen.dart';

class AppRouter {
  static final String initial = SplashScreen.routeName;

  static final GoRouter appRouter = GoRouter(
    initialLocation: initial,
    errorBuilder: (context, state) {
      final String badPath = state.uri.toString();
      return CustomGoErrorPage(
        location: badPath,
        error: state.error,
        onRetry: () => context.go(initial),
        onReport: () {
          GlobalSnackBar.show(
            context,
            title: "We're sorry",
            message: "Thanks, we'll look into this.",
          );
        },
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: HomeScreen.routeName,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routeName,
        name: RegisterScreen.routeName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: BottomNavBar.routeName,
        name: BottomNavBar.routeName,
        builder: (context, state) => const BottomNavBar(),
      ),
      GoRoute(
        path: OnboardingSlidesScreen.routeName,
        name: OnboardingSlidesScreen.routeName,
        builder: (context, state) {
          void onComplete() {
            () async {
              final user = await AuthLocalStorage.getCurrentUser();
              if (user != null) await AuthLocalStorage.setOnboarded(user.id);
              if (context.mounted) context.go(TownSelectionScreen.routeName);
            }();
          }

          return OnboardingSlidesScreen(onComplete: onComplete);
        },
      ),
      GoRoute(
        path: TownSelectionScreen.routeName,
        name: TownSelectionScreen.routeName,
        builder: (context, state) => TownSelectionScreen(
          onSelectTown: (_) => context.go(BottomNavBar.routeName),
          canClose: false,
        ),
      ),
      GoRoute(
        path: CustomerHomeScreen.routeName,
        name: CustomerHomeScreen.routeName,
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: SplashScreen.routeName,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: ProviderAppScreen.routeName,
        name: ProviderAppScreen.routeName,
        builder: (context, state) => const ProviderAppScreen(),
      ),
    ],
  );
}
