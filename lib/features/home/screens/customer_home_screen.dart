import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/features/bookings/screens/task_submission_screen.dart';
import 'package:renizo/features/home/logic/customer_home_logic.dart';
import 'package:renizo/features/home/models/customer_home_models.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/home/widgets/featured_providers.dart';
import 'package:renizo/features/home/widgets/service_categories.dart';
import 'package:renizo/features/home/widgets/welcome_banner.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// Customer main home – fully API-driven via GET /customer/home?townId=.
/// Header + WelcomeBanner → Create New Booking → Top Rated Providers → Services Available.
/// All sections rendered from API response only – no dummy / hardcoded data.
class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.selectedTownId,
    this.selectedTownName,
    this.onCreateBooking,
    this.onSelectProvider,
    this.onSelectService,
    this.onChangeTown,
    this.onNotifications,
  });

  static const String routeName = '/customer-home';

  final String? selectedTownId;

  /// Display name for header location (e.g. "Terrace").
  final String? selectedTownName;

  /// Called when user taps "Create New Booking" (task submission flow).
  final VoidCallback? onCreateBooking;

  /// Called when user selects a top-rated provider card.
  final void Function(ProviderCardModel provider)? onSelectProvider;

  /// Called when user selects a service category card.
  final void Function(ServiceModel service)? onSelectService;

  /// Called when user taps location in header (change town).
  final VoidCallback? onChangeTown;

  /// Called when user taps notification bell in header.
  final VoidCallback? onNotifications;

  @override
  ConsumerState<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  /// Local selected town when parent does not provide it.
  String? _selectedTownName;
  String? _selectedTownId;

  /// Main app background blue (bg-[#2384F4]).
  static const Color _bg = Color(0xFF2384F4);

  /// Create New Booking button blue (bg-[#003E93]).
  static const Color _createBtnBg = Color(0xFF003E93);

  /// Resolved townId for the provider call.
  String get _townId => widget.selectedTownId ?? _selectedTownId ?? '';

  // ── callbacks ──────────────────────────────────────────────────────────

  void _onCreateBooking() {
    widget.onCreateBooking?.call();
    if (widget.onCreateBooking != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TaskSubmissionScreen(
          selectedTownId: _townId,
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

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final townId = _townId;

    // No townId → show header + prompt to select location
    if (townId.isEmpty) {
      return Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            CustomerHeader(
              selectedTownName: widget.selectedTownName ?? _selectedTownName,
              onChangeTown: _onChangeTown,
              onNotifications: _onNotifications,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 48.sp, color: Colors.white.withOpacity(0.5)),
                      SizedBox(height: 12.h),
                      Text(
                        'Select a location to get started',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _onChangeTown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('Choose Location'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Watch API data
    final asyncHome = ref.watch(customerHomeControllerProvider(townId));

    return asyncHome.when(
      // ── Loading ──────────────────────────────────────────────────────
      loading: () => Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            CustomerHeader(
              selectedTownName:
                  widget.selectedTownName ?? _selectedTownName ?? '...',
              onChangeTown: _onChangeTown,
              onNotifications: _onNotifications,
            ),
            Expanded(
              child: _buildLoadingSkeleton(),
            ),
          ],
        ),
      ),
      // ── Error ────────────────────────────────────────────────────────
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            CustomerHeader(
              selectedTownName: widget.selectedTownName ?? _selectedTownName,
              onChangeTown: _onChangeTown,
              onNotifications: _onNotifications,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48.sp, color: Colors.white.withOpacity(0.7)),
                      SizedBox(height: 12.h),
                      Text(
                        'Failed to load home data',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        e.toString(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(
                          customerHomeControllerProvider(townId),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // ── Data ─────────────────────────────────────────────────────────
      data: (data) => _buildDataScaffold(data, townId),
    );
  }

  // ── Data scaffold ──────────────────────────────────────────────────────

  Widget _buildDataScaffold(CustomerHomeData data, String townId) {
    final displayUserName = data.user.fullName.isNotEmpty
        ? data.user.fullName
        : null;

    final displayTownName = data.town.name.isNotEmpty
        ? data.town.name
        : (widget.selectedTownName ?? _selectedTownName);

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          CustomerHeader(
            selectedTownName: displayTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(customerHomeControllerProvider(townId));
              },
              color: _bg,
              child: CustomScrollView(
                slivers: [
                  // Welcome banner (user fullName from API)
                  SliverToBoxAdapter(
                    child: WelcomeBanner(userName: displayUserName),
                  ),

                  // Create New Booking button
                  SliverToBoxAdapter(child: _buildCreateBookingButton()),

                  // Top Rated Providers (API data – hidden when empty)
                  SliverToBoxAdapter(
                    child: FeaturedProvidersWidget(
                      providers: data.topRatedProviders,
                      onSelectProvider: (p) {
                        widget.onSelectProvider?.call(p);
                        if (widget.onSelectProvider == null) {
                          debugPrint(
                              'Selected provider: ${p.name} (${p.id})');
                        }
                      },
                      lightHeader: true,
                    ),
                  ),

                  // Services Available (API data – hidden when empty)
                  SliverToBoxAdapter(
                    child: ServiceCategoriesWidget(
                      services: data.servicesAvailable,
                      onSelectService: (s) {
                        widget.onSelectService?.call(s);
                        if (widget.onSelectService == null) {
                          debugPrint(
                              'Selected service: ${s.name} (${s.id})');
                        }
                      },
                      lightTitle: true,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 25.h)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Booking button ──────────────────────────────────────────────

  Widget _buildCreateBookingButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Material(
        color: _createBtnBg,
        borderRadius: BorderRadius.circular(16.r),
        shadowColor: _createBtnBg.withOpacity(0.3),
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
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return CustomScrollView(
      slivers: [
        // Welcome banner skeleton
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            height: 100.h,
            decoration: BoxDecoration(
              color: AllColor.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ),
        // Create booking button skeleton
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            height: 52.h,
            decoration: BoxDecoration(
              color: AllColor.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
        // Providers skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24.h,
                  width: 192.w,
                  decoration: BoxDecoration(
                    color: AllColor.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 16.h),
                ...List.generate(
                  2,
                  (_) => Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    height: 96.h,
                    decoration: BoxDecoration(
                      color: AllColor.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Services skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24.h,
                  width: 128.w,
                  decoration: BoxDecoration(
                    color: AllColor.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 16.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: AllColor.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
