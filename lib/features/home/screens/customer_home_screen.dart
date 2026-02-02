import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/provider_list_item.dart';
import 'package:renizo/core/models/service_category.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/features/bookings/screens/task_submission_screen.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/home/widgets/featured_providers.dart';
import 'package:renizo/features/home/widgets/service_categories.dart';
import 'package:renizo/features/home/widgets/welcome_banner.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// Customer main home – converted from React CustomerApp.tsx home content.
/// Header + WelcomeBanner → Create New Booking → FeaturedProviders → ServiceCategories.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.userName,
    this.selectedTownId,
    this.selectedTownName,
    this.onCreateBooking,
    this.onSelectCategory,
    this.onSelectProvider,
    this.onChangeTown,
    this.onNotifications,
  });

  static const String routeName = '/customer-home';

  final String? userName;
  final String? selectedTownId;

  /// Display name for header location (e.g. "Terrace").
  final String? selectedTownName;

  /// Called when user taps "Create New Booking" (task submission flow).
  final VoidCallback? onCreateBooking;

  /// Called when user selects a service category (task submission flow).
  final void Function(ServiceCategory category)? onSelectCategory;

  /// Called when user selects a provider (provider profile / booking flow).
  final void Function(ProviderListItem provider)? onSelectProvider;

  /// Called when user taps location in header (change town).
  final VoidCallback? onChangeTown;

  /// Called when user taps notification bell in header.
  final VoidCallback? onNotifications;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  /// Local selected town when parent does not provide it (e.g. after picking from TownSelectionScreen).
  String? _selectedTownName;
  String? _selectedTownId;

  /// Main app background blue from CustomerApp.tsx (bg-[#2384F4]).
  static const Color _customerAppBackground = Color(0xFF2384F4);

  /// Create New Booking button blue from CustomerApp.tsx (bg-[#003E93]).
  static const Color _createBookingButtonBg = Color(0xFF003E93);

  void _onSelectCategory(ServiceCategory category) {
    widget.onSelectCategory?.call(category);
    if (widget.onSelectCategory == null) {
      debugPrint('Selected category: ${category.name}');
    }
  }

  void _onSelectProvider(ProviderListItem provider) {
    widget.onSelectProvider?.call(provider);
    if (widget.onSelectProvider == null) {
      debugPrint('Selected provider: ${provider.displayName} (${provider.id})');
    }
  }

  void _onCreateBooking() {
    widget.onCreateBooking?.call();
    if (widget.onCreateBooking != null) return;
    if (!mounted) return;
    final townId = widget.selectedTownId ?? _selectedTownId ?? '';
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TaskSubmissionScreen(
          selectedTownId: townId,
          onSubmit: (data) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Finding providers for ${data.date} at ${data.address}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onChangeTown() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now showing services in ${town.name}')),
      );
    }
  }

  void _onNotifications() {
    widget.onNotifications?.call();
    if (widget.onNotifications != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _customerAppBackground,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: WelcomeBanner(userName: widget.userName),
                ),
                // Quick Action: Create New Booking (from CustomerApp.tsx)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: Material(
                      color: _createBookingButtonBg,
                      borderRadius: BorderRadius.circular(16.r),
                      shadowColor: _createBookingButtonBg.withOpacity(0.3),
                      elevation: 8,
                      child: InkWell(
                        onTap: _onCreateBooking,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AllColor.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Create New Booking',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AllColor.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FeaturedProvidersWidget(
                    selectedTownId:
                        widget.selectedTownId ?? _selectedTownId ?? '',
                    onSelectProvider: _onSelectProvider,
                    lightHeader: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ServiceCategoriesWidget(
                    selectedTownId:
                        widget.selectedTownId ?? _selectedTownId ?? '',
                    onSelectCategory: _onSelectCategory,
                    lightTitle: true,
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 25.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
