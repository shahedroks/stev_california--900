import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/provider_list_item.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/bookings/screens/task_submission_screen.dart';
import 'package:renizo/features/search/logic/search_logic.dart';
import 'package:renizo/features/search/models/search_api_models.dart';

const Color _searchGradientStart = Color(0xFF408AF1);
const Color _searchGradientEnd = Color(0xFF5ca3f5);

/// Search tab – fully API-driven.
/// Blue background, search input, type filter chips, filtered results by town, query, and type.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.selectedTownId,
    this.onSelectProvider,
  });

  /// If null / empty, the screen loads the persisted town from AuthLocalStorage.
  final String? selectedTownId;
  final void Function(ProviderListItem provider)? onSelectProvider;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const Color _bgBlue = Color(0xFF2384F4);

  /// Debounce timer so we don't fire on every keystroke.
  Timer? _debounce;

  /// Current search query (debounced) that drives the provider.
  String _debouncedQuery = '';

  /// Resolved townId – loaded from storage if not passed via widget.
  String _resolvedTownId = '';

  /// Whether we've finished loading the persisted townId.
  bool _townIdLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTownId();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Load the selected town from AuthLocalStorage if the widget doesn't provide one.
  Future<void> _loadTownId() async {
    final fromWidget = widget.selectedTownId;
    if (fromWidget != null && fromWidget.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedTownId = fromWidget;
          _townIdLoaded = true;
        });
      }
      return;
    }

    // Load from storage
    final user = await AuthLocalStorage.getCurrentUser();
    if (user != null) {
      final townJson = await AuthLocalStorage.getSelectedTown(user.id);
      if (townJson != null && townJson.isNotEmpty) {
        try {
          final parsed = jsonDecode(townJson);
          if (parsed is Map<String, dynamic>) {
            final id =
                (parsed['id'] ?? parsed['_id'] ?? '').toString();
            if (id.isNotEmpty && mounted) {
              setState(() {
                _resolvedTownId = id;
                _townIdLoaded = true;
              });
              return;
            }
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    }

    if (mounted) {
      setState(() => _townIdLoaded = true);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      if (q != _debouncedQuery) {
        setState(() => _debouncedQuery = q);
      }
    });
  }

  SearchParams get _searchParams => SearchParams(
        query: _debouncedQuery,
        townId: _resolvedTownId,
        type: 'all',
      );

  void _onSelectProvider(SearchApiProvider p) {
    final item = ProviderListItem(
      id: p.id,
      userId: p.userId,
      displayName: p.name,
      avatar: p.avatar,
      rating: p.rating,
      reviewCount: p.reviewCount,
      distance: p.distance,
      responseTime: p.responseTime,
      availableToday: false,
      categoryNames: p.categoryName.isNotEmpty ? [p.categoryName] : [],
    );
    widget.onSelectProvider?.call(item);
    if (widget.onSelectProvider == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected ${p.name}')),
      );
    }
  }

  void _onSelectService(SearchApiService service) {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TaskSubmissionScreen(
          selectedTownId: _resolvedTownId,
          initialCategoryId: service.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSearchField(),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    // Still loading the persisted town
    if (!_townIdLoaded) {
      return Center(
        child: SizedBox(
          width: 36.w,
          height: 36.h,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_debouncedQuery.isEmpty) return _buildEmptyPrompt();

    // Services: from catalog API, filtered by query. Providers: from search API.
    final asyncCatalog = ref.watch(catalogServicesProvider);
    final asyncSearch = ref.watch(searchControllerProvider(_searchParams));

    const useCatalogForServices = true;
    const useSearchForProviders = true;

    if (useCatalogForServices && useSearchForProviders) {
      // All: need both catalog (services) and search (providers)
      return asyncCatalog.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildErrorState(e),
        data: (allServices) {
          final filteredServices = _filterServicesByQuery(allServices);
          return asyncSearch.when(
            loading: () => _buildLoading(),
            error: (e, _) => _buildErrorState(e),
            data: (searchData) => _buildDataState(
              services: filteredServices,
              providers: searchData.providers,
            ),
          );
        },
      );
    }
  }

  List<SearchApiService> _filterServicesByQuery(List<SearchApiService> list) {
    final q = _debouncedQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.slug.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: 36.w,
        height: 36.h,
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildDataState({
    required List<SearchApiService> services,
    required List<SearchApiProvider> providers,
  }) {
    if (services.isEmpty && providers.isEmpty) return _buildNoResults();
    return _buildResults(services, providers);
  }

  // ── Combined results ────────────────────────────────────────────────────────

  Widget _buildResults(
    List<SearchApiService> services,
    List<SearchApiProvider> providers,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Providers section
          if (providers.isNotEmpty) ...[
            Text(
              'Providers',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            ...List.generate(
              providers.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: _SearchProviderCard(
                  provider: providers[index],
                  index: index,
                  onTap: () => _onSelectProvider(providers[index]),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ] else ...[
            // _buildInlineEmpty('No provider found'),
            SizedBox(height: 16.h),
          ],

          // Services section
          if (services.isNotEmpty) ...[
            Text(
              'Services',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            ...List.generate(
              services.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: _ServiceTile(
                  service: services[index],
                  index: index,
                  onTap: () => _onSelectService(services[index]),
                ),
              ),
            ),
          ] else ...[
            _buildInlineEmpty('No service found.'),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search services or providers...',
          hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded,
              size: 22.sp, color: Colors.grey.shade400),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20.sp, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _debouncedQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                size: 48.sp, color: Colors.white.withOpacity(0.5)),
            SizedBox(height: 12.h),
            Text(
              'Search for a service or provider',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48.sp, color: Colors.white.withOpacity(0.5)),
            SizedBox(height: 12.h),
            Text(
              'No results found.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Inline empty text inside the combined results.
  Widget _buildInlineEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.white.withOpacity(0.7),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44.sp, color: Colors.white.withOpacity(0.7)),
            SizedBox(height: 12.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(searchControllerProvider(_searchParams)),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Try again',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service / Category tile ─────────────────────────────────────────────────

class _ServiceTile extends StatefulWidget {
  const _ServiceTile({
    required this.service,
    required this.index,
    this.onTap,
  });

  final SearchApiService service;
  final int index;
  final VoidCallback? onTap;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(-0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final hasIconUrl = s.iconUrl.isNotEmpty;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        gradient: hasIconUrl
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _searchGradientStart,
                                  _searchGradientEnd,
                                ],
                              ),
                      ),
                      child: hasIconUrl
                          ? CachedNetworkImage(
                              imageUrl: s.iconUrl,
                              fit: BoxFit.cover,
                              width: 36.w,
                              height: 36.h,
                              placeholder: (_, __) => Center(
                                child: Icon(Icons.category_rounded,
                                    size: 18.sp, color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.category_rounded,
                                    size: 18.sp, color: Colors.white),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.category_rounded,
                                  size: 18.sp, color: Colors.white),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                        if (s.description.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            s.description,
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        size: 20.sp, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Provider card ───────────────────────────────────────────────────────────

class _SearchProviderCard extends StatefulWidget {
  const _SearchProviderCard({
    required this.provider,
    required this.index,
    required this.onTap,
  });

  final SearchApiProvider provider;
  final int index;
  final VoidCallback onTap;

  @override
  State<_SearchProviderCard> createState() => _SearchProviderCardState();
}

class _SearchProviderCardState extends State<_SearchProviderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(-0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Material(
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
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_searchGradientStart, _searchGradientEnd],
                          ),
                        ),
                        child: p.avatar.isNotEmpty && !_imageError
                            ? CachedNetworkImage(
                                imageUrl: p.avatar,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: Text(initial,
                                      style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ),
                                errorWidget: (_, __, ___) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() => _imageError = true);
                                    }
                                  });
                                  return Center(
                                    child: Text(initial,
                                        style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  );
                                },
                              )
                            : Center(
                                child: Text(initial,
                                    style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87),
                          ),
                          if (p.categoryName.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              p.categoryName,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                          if (p.rating > 0) ...[
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 14.sp,
                                    color: const Color(0xFFFBBF24)),
                                SizedBox(width: 4.w),
                                Text(
                                  p.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (p.reviewCount > 0) ...[
                                  SizedBox(width: 6.w),
                                  Text(
                                    '(${p.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 22.sp, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
