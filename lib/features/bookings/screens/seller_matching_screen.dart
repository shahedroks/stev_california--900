import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/provider_list_item.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// Seller matching – full conversion from React SellerMatching.tsx.
/// Shows available providers for category/town; user chooses a provider.
/// Uses common CustomerHeader and CustomerBottomNavBar like CustomerHomeScreen.
class SellerMatchingScreen extends ConsumerStatefulWidget {
  const SellerMatchingScreen({
    super.key,
    required this.categoryId,
    required this.selectedTownId,
    required this.bookingId,
    this.selectedTownName,
    this.onChangeTown,
    this.onNotifications,
    this.onSelectProvider,
    this.onAutoAssign,
  });

  static const String routeName = '/seller-matching';

  final String categoryId;
  final String selectedTownId;
  final String bookingId;
  final String? selectedTownName;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;
  final void Function(ProviderListItem provider)? onSelectProvider;
  final VoidCallback? onAutoAssign;

  @override
  ConsumerState<SellerMatchingScreen> createState() =>
      _SellerMatchingScreenState();
}

class _SellerMatchingScreenState extends ConsumerState<SellerMatchingScreen> {
  List<ProviderListItem> _providers = [];
  bool _loading = true;

  /// Local town name when user picks from header (same as CustomerHomeScreen).
  String? _selectedTownName;

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _gradientStart = Color(0xFF408AF1);
  static const Color _gradientEnd = Color(0xFF5ca3f5);

  /// Mock providers for category/town – mirrors getProvidersForCategory.
  static List<ProviderListItem> _mockProvidersForCategory(
    String categoryId,
    String townId,
  ) {
    const avatar1 =
        'https://images.unsplash.com/photo-1667328549104-c125874407be?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjbGVhbmluZyUyMHByb2Zlc3Npb25hbCUyMHBvcnRyYWl0fGVufDF8fHx8MTc2OTE0MTE1M3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral';
    const avatar2 =
        'https://images.unsplash.com/photo-1762341119317-fb5417c18407?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvZmZpY2UlMjB3b3JrZXIlMjBwcm9mZXNzaW9uYWx8ZW58MXx8fHwxNzY5MTgxNTM4fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral';
    const avatar3 =
        'https://images.unsplash.com/photo-1759521296144-fe6f2d2dc769?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwcm9mZXNzaW9uYWwlMjBzZXJ2aWNlJTIwd29ya2VyJTIwcG9ydHJhaXR8ZW58MXx8fHwxNzY5MTgxNTM3fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral';
    return [
      const ProviderListItem(
        id: 'p1',
        displayName: 'Sparkle Home Cleaning',
        avatar: avatar1,
        rating: 4.9,
        reviewCount: 108,
        distance: '2.1 mi',
        responseTime: 'Within 2 hrs',
        availableToday: true,
        categoryNames: ['Cleaning'],
      ),
      const ProviderListItem(
        id: 'p2',
        displayName: 'Floor Care Experts',
        avatar: avatar1,
        rating: 4.9,
        reviewCount: 63,
        distance: '3.0 mi',
        responseTime: 'Within 1 hr',
        availableToday: true,
        categoryNames: ['Cleaning'],
      ),
      const ProviderListItem(
        id: 'p3',
        displayName: 'Pro Office Clean',
        avatar: avatar2,
        rating: 4.8,
        reviewCount: 159,
        distance: '1.5 mi',
        responseTime: 'Within 3 hrs',
        availableToday: true,
        categoryNames: ['Cleaning'],
      ),
      const ProviderListItem(
        id: 'p4',
        displayName: 'Elite Home Cleaning',
        avatar: avatar3,
        rating: 4.7,
        reviewCount: 82,
        distance: '2.5 mi',
        responseTime: 'Within 2 hrs',
        availableToday: true,
        categoryNames: ['Cleaning'],
      ),
    ];
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _providers = _mockProvidersForCategory(
        widget.categoryId,
        widget.selectedTownId,
      );
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void didUpdateWidget(covariant SellerMatchingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.selectedTownId != widget.selectedTownId) {
      _loadProviders();
    }
  }

  static const int _bookingsTabIndex = 2;

  /// Header location + notifications – same behaviour as CustomerHomeScreen so header looks same.
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
      setState(() => _selectedTownName = town.name);
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
      backgroundColor: _bgBlue,
      body: Column(
        children: [
          CustomerHeader(
            leading: _buildBackButton(),
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: widget.onChangeTown ?? _onChangeTown,
            onNotifications: widget.onNotifications ?? _onNotifications,
          ),
          _buildTitleSection(),
          if (!_loading) _buildBanner(),
          Expanded(
            child: _loading ? const SizedBox.shrink() : _buildProviderList(),
          ),
        ],
      ),
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: _bookingsTabIndex,
        onTabTap: (index) {
          if (index == _bookingsTabIndex) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(selectedIndexProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 24.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              'Back',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Available Providers',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _loading
                ? 'Loading...'
                : '${_providers.length} providers ready to help',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_gradientStart, _gradientEnd],
        ),
      ),
      child: Text(
        'Choose a Provider',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProviderList() {
    if (_providers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.w,
                height: 64.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.access_time, size: 32.sp, color: Colors.grey),
              ),
              SizedBox(height: 16.h),
              Text(
                'No providers available right now',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Try selecting a different time or we can notify you when someone becomes available',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _ProviderCard(
            provider: provider,
            onTap: () {
              widget.onSelectProvider?.call(provider);
              if (widget.onSelectProvider == null && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected ${provider.displayName}')),
                );
              } else if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      },
    );
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ProviderListItem provider;
  final VoidCallback onTap;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final initial = p.displayName.isNotEmpty
        ? p.displayName[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF408AF1), Color(0xFF5ca3f5)],
                        ),
                      ),
                      child: p.avatar.isNotEmpty && !_imageError
                          ? CachedNetworkImage(
                              imageUrl: p.avatar,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted)
                                    setState(() => _imageError = true);
                                });
                                return Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16.sp,
                              color: const Color(0xFFFBBF24),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              p.rating.toString(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${p.reviewCount} reviews',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      p.responseTime,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
