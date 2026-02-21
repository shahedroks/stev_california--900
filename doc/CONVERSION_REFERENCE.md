# Screen conversion: React → Flutter (Frame/lib)

**Source:** `just for confirm the color./src` (React app)  
**Target:** `Frame/lib` (Flutter app)

**Colors:** All screens use the confirmed palette from `just for confirm the color./src/styles/theme.css`.  
See `lib/core/constants/color_control/all_color.dart` and `theme_color_controller.dart`.

---

## Full app flow (first → last)

1. **Splash** (`/splash`) → checks auth.
2. **Not logged in** → **Login** (`/login`). Demo: `customer@demo.com` / `password` (customer), `provider@demo.com` / `password` (provider). Or **Create Account** → **Register** (`/register`).
3. **Customer after login** → **Onboarding** (`/onboarding`) → **Town selection** (`/town-selection`) → **Customer app** (`/BottomNavBar`) with tabs: **Home** (WelcomeBanner + ServiceCategories), **Bookings**, **Messages**, **Notifications**, **Profile**.
4. **Provider after login** → **Seller app** (`/seller`) with tabs: **Home**, **Bookings**, **Messages**, **Earnings**, **Profile**.
5. **Profile** (customer or seller) → Log out → back to **Login**.

---

## Color reference (confirmed from theme.css)

| Token        | Hex       | Flutter constant              |
|-------------|-----------|-------------------------------|
| primary     | #408AF1   | `AllColor.primary`            |
| foreground  | #1f2937   | `AllColor.foreground`        |
| background  | #ffffff   | `AllColor.background`        |
| secondary   | #f3f4f6   | `AllColor.secondary`         |
| muted       | #f3f4f6   | `AllColor.muted`             |
| muted-foreground | #6b7280 | `AllColor.mutedForeground`   |
| accent      | #eff6ff   | `AllColor.accent`            |
| destructive | #dc2626   | `AllColor.destructive`       |
| success     | #10B981   | `AllColor.success`           |
| warning     | #F59E0B   | `AllColor.warning`           |
| ring        | #408AF1   | `AllColor.ring`              |

---

## Auth & entry

| React (just for confirm the color./src) | Flutter (Frame/lib) | Status   |
|----------------------------------------|---------------------|----------|
| auth/LoginScreen.tsx                   | features/auth/screens/login_screen.dart | ✅ Exists |
| auth/RegisterScreen.tsx                | features/auth/screens/register_screen.dart | ✅ Exists |
| SplashScreen.tsx                       | features/auth/screens/splash_screen.dart | ✅ Exists |
| OnboardingSlides.tsx                   | features/onboarding/screens/onboarding_slides_screen.dart | ✅ Done |
| TownSelectionModal.tsx                 | features/town/screens/town_selection_screen.dart | ✅ Done |
| TownSelectionGate.tsx                  | —                   | 🔲 To add |
| TownChangeBottomSheet.tsx              | —                   | 🔲 To add |

---

## Customer app (main flow)

| React screen / component | Flutter target | Status   |
|--------------------------|----------------|----------|
| CustomerApp.tsx (shell)  | HomeScreen / BottomNavBar + CustomerHomeScreen | ✅ Done |
| BottomNav.tsx            | features/nav_bar/screen/bottom_nav_bar.dart | ✅ Exists |
| Header.tsx               | — (widget)     | 🔲 To add |
| WelcomeBanner.tsx        | features/home/widgets/welcome_banner.dart | ✅ Done |
| ServiceCategories.tsx    | features/home/widgets/service_categories.dart | ✅ Done |
| FeaturedProviders.tsx    | —              | 🔲 To add |
| ProviderList.tsx         | —              | 🔲 To add |
| ProviderProfile.tsx      | —              | 🔲 To add |
| ProviderMatchingScreen.tsx | —            | 🔲 To add |
| TaskSubmission.tsx       | —              | 🔲 To add |
| SellerMatching.tsx       | —              | 🔲 To add |
| BookingFlow.tsx          | —              | 🔲 To add |
| NewBookingFlow.tsx       | —              | 🔲 To add |
| BookingFormScreen.tsx    | —              | 🔲 To add |
| AddonsSelectionScreen.tsx | —             | 🔲 To add |
| ServiceSelectionScreen.tsx | —            | 🔲 To add |
| BookingDetails.tsx       | —              | 🔲 To add |
| PaymentScreen.tsx        | —              | 🔲 To add |
| PaymentBreakdown.tsx     | — (widget)     | 🔲 To add |
| PaymentMethodsScreen.tsx | —              | 🔲 To add |
| Calendar.tsx             | —              | 🔲 To add |
| ChatScreen.tsx           | —              | 🔲 To add |
| BookingsScreen.tsx       | features/bookings/screens/bookings_screen.dart | ✅ Done |
| MessagesScreen.tsx       | features/messages/screens/messages_screen.dart | ✅ Done |
| NotificationsScreen.tsx  | features/notifications/screens/notifications_screen.dart | ✅ Done |
| ProfileScreen.tsx        | features/profile/screens/profile_screen.dart | ✅ Done |
| SearchScreen.tsx         | —              | 🔲 To add |

---

## Profile & settings

| React screen | Flutter target | Status   |
|-------------|----------------|----------|
| EditProfileScreen.tsx   | — | 🔲 To add |
| ChangePasswordScreen.tsx | — | 🔲 To add |
| SettingsScreen.tsx      | — | 🔲 To add |
| HelpSupportScreen.tsx   | — | 🔲 To add |
| PrivacyPolicyScreen.tsx | — | 🔲 To add |
| TermsOfServiceScreen.tsx | — | 🔲 To add |

---

## Seller (provider) app

| React screen | Flutter target | Status   |
|-------------|----------------|----------|
| ProviderApp.tsx (shell) | features/seller/screens/seller_bottom_nav.dart | ✅ Done |
| seller/SellerBottomNav.tsx | features/seller/screens/seller_bottom_nav.dart | ✅ Done |
| seller/SellerHome.tsx  | features/seller/screens/seller_home_screen.dart | ✅ Done |
| seller/SellerServiceSetup.tsx | — | 🔲 To add |
| seller/SellerAvailabilitySetup.tsx | — | 🔲 To add |
| seller/SellerPricingScreen.tsx | — | 🔲 To add |
| seller/SellerBookingsScreen.tsx | features/seller/screens/seller_bookings_screen.dart | ✅ Done |
| seller/SellerMessagesScreen.tsx | features/seller/screens/seller_messages_screen.dart | ✅ Done |
| seller/SellerEarningsScreen.tsx | features/seller/screens/seller_earnings_screen.dart | ✅ Done |
| seller/SellerProfileScreen.tsx | features/seller/screens/seller_profile_screen.dart | ✅ Done |

---

## Shared / modals & UI

| React | Flutter | Status   |
|-------|---------|----------|
| ContactWarningModal.tsx | — | 🔲 To add |
| common/WarrantyBadge.tsx | — | 🔲 To add |
| common/WarrantyInfoModal.tsx | — | 🔲 To add |
| MockDataToggle.tsx | — | 🔲 To add (dev) |
| ui/* (shadcn-style) | Material / custom widgets | Use AllColor.* in Frame |

---

## Routes (Frame)

Current routes in `lib/routes/app_routes.dart`:

- `LoginScreen`
- `RegisterScreen`
- `HomeScreen`

Add routes for each new screen as you convert them; keep using the confirmed colors from `AllColor` and `ThemeColorController`.
