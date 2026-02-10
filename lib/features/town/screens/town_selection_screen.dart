import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/town/logic/towns_logic.dart';

/// Town selection – UI same, only API + selection functionality added.
class TownSelectionScreen extends ConsumerStatefulWidget {
  const TownSelectionScreen({
    super.key,
    required this.onSelectTown,
    this.canClose = false,
  });

  static const String routeName = '/town-selection';

  final void Function(Town town) onSelectTown;
  final bool canClose;

  @override
  ConsumerState<TownSelectionScreen> createState() =>
      _TownSelectionScreenState();
}

class _TownSelectionScreenState extends ConsumerState<TownSelectionScreen> {
  String _searchQuery = '';
  String? _selectedTownId;
  bool _isSaving = false;

  List<Town> _filter(List<Town> towns) {
    if (_searchQuery.isEmpty) return towns;
    final q = _searchQuery.toLowerCase();
    return towns.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  String _subtitle(Town t) => t.isActive ? 'Available' : 'Inactive';

  Future<void> _onContinue(List<Town> towns) async {
    final selectedId = _selectedTownId;
    if (selectedId == null || _isSaving) return;

    final town = towns.firstWhere(
      (t) => t.id == selectedId,
      orElse: () => towns.first,
    );

    final user = await AuthLocalStorage.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final headers = await AuthLocalStorage.authHeaders();
      final response = await http.patch(
        Uri.parse(UserApi.updateTown),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode({'townId': town.id}),
      );

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Invalid response from server');
      }

      final body =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode >= 400) {
        final msg = body['message']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }
      final status = (body['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        final msg = body['message']?.toString() ?? 'Unexpected status: $status';
        throw Exception(msg);
      }

      // ✅ state নাই, তাই id/name/isActive save করা হলো
      final payload = jsonEncode({
        'id': town.id,
        'name': town.name,
        'isActive': town.isActive,
      });
      await AuthLocalStorage.setSelectedTown(user.id, payload);

      widget.onSelectTown(town);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTowns = ref.watch(townsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            constraints: BoxConstraints(
              maxHeight: 0.9 * MediaQuery.sizeOf(context).height,
            ),
            decoration: BoxDecoration(
              color: AllColor.primary,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: asyncTowns.when(
              loading: () => Padding(
                padding: EdgeInsets.all(24.w),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load towns',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      e.toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 14.h),
                    TextButton(
                      onPressed: () => ref.invalidate(townsControllerProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (townsRaw) {
                final towns = townsRaw; // ✅ সব towns দেখাবে (active/inactive)
                final filtered = _filter(towns);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30.h),

                    if (widget.canClose)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: AllColor.white,
                            size: 24.sp,
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(32.w, 0, 32.w, 24.h),
                      child: Column(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: AllColor.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 32.sp,
                              color: AllColor.primary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Select Your Town',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: AllColor.white,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Choose your location to see available services',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AllColor.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search towns...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AllColor.mutedForeground,
                            size: 20.sp,
                          ),
                          filled: true,
                          fillColor: AllColor.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AllColor.white.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AllColor.white.withOpacity(0.2),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AllColor.foreground,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 8.h,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final town = filtered[i];
                          final selected = _selectedTownId == town.id;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Material(
                              color: selected
                                  ? AllColor.white
                                  : AllColor.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16.r),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedTownId = town.id),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AllColor.primary
                                              : AllColor.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          size: 20.sp,
                                          color: AllColor.white,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              town.name,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                                color: selected
                                                    ? AllColor.primary
                                                    : AllColor.white,
                                              ),
                                            ),
                                            Text(
                                              _subtitle(town),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: selected
                                                    ? AllColor.primary
                                                          .withOpacity(0.8)
                                                    : AllColor.white
                                                          .withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 24.w,
                                        height: 24.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? AllColor.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? AllColor.primary
                                                : AllColor.white.withOpacity(
                                                    0.5,
                                                  ),
                                            width: 2,
                                          ),
                                        ),
                                        child: selected
                                            ? Icon(
                                                Icons.check,
                                                size: 14.sp,
                                                color: AllColor.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_selectedTownId == null ||
                                  towns.isEmpty ||
                                  _isSaving)
                              ? null
                              : () => _onContinue(towns),
                          style: FilledButton.styleFrom(
                            backgroundColor: AllColor.white,
                            foregroundColor: AllColor.primary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            disabledBackgroundColor: AllColor.white.withOpacity(
                              0.5,
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Continue',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper so route/modal call sites can use TownSelectionScreenWithProvider.
class TownSelectionScreenWithProvider extends StatelessWidget {
  const TownSelectionScreenWithProvider({
    super.key,
    required this.onSelectTown,
    this.canClose = false,
  });

  final void Function(Town town) onSelectTown;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    return TownSelectionScreen(onSelectTown: onSelectTown, canClose: canClose);
  }
}
