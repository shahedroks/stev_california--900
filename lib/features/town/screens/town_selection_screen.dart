import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Town selection – converted from React TownSelectionModal.tsx.
/// Uses confirmed primary #408AF1 (AllColor.primary).
class TownSelectionScreen extends StatefulWidget {
  const TownSelectionScreen({
    super.key,
    required this.onSelectTown,
    this.canClose = false,
  });

  static const String routeName = '/town-selection';

  final void Function(Town town) onSelectTown;
  final bool canClose;

  @override
  State<TownSelectionScreen> createState() => _TownSelectionScreenState();
}

class _TownSelectionScreenState extends State<TownSelectionScreen> {
  String _searchQuery = '';
  String? _selectedTownId;
  List<Town> _towns = [];
  bool _loading = true;

  static const List<Town> _mockTowns = [
    Town(id: '1', name: 'Los Angeles', state: 'CA'),
    Town(id: '2', name: 'San Francisco', state: 'CA'),
    Town(id: '3', name: 'San Diego', state: 'CA'),
    Town(id: '4', name: 'Sacramento', state: 'CA'),
    Town(id: '5', name: 'Oakland', state: 'CA'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTowns();
  }

  Future<void> _loadTowns() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _towns = _mockTowns;
      _loading = false;
    });
  }

  List<Town> get _filteredTowns {
    if (_searchQuery.isEmpty) return _towns;
    final q = _searchQuery.toLowerCase();
    return _towns
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.state.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _onContinue() async {
    Town? town;
    for (final t in _towns) {
      if (t.id == _selectedTownId) {
        town = t;
        break;
      }
    }
    if (town == null) return;
    final user = await AuthLocalStorage.getCurrentUser();
    if (user != null) {
      await AuthLocalStorage.setSelectedTown(
        user.id,
        '{"id":"${town.id}","name":"${town.name}","state":"${town.state}"}',
      );
    }
    widget.onSelectTown(town);
  }

  @override
  Widget build(BuildContext context) {
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 30.h),
                if (widget.canClose)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        if (_towns.isNotEmpty)
                          widget.onSelectTown(_towns.first);
                      },
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
                  child: _loading
                      ? Padding(
                          padding: EdgeInsets.all(24.w),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 8.h,
                          ),
                          itemCount: _filteredTowns.length,
                          itemBuilder: (context, i) {
                            final town = _filteredTowns[i];
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
                                                : AllColor.white.withOpacity(
                                                    0.2,
                                                  ),
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
                                                town.state,
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
                      onPressed: _selectedTownId == null ? null : _onContinue,
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
                        'Continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    return TownSelectionScreen(
      onSelectTown: onSelectTown,
      canClose: canClose,
    );
  }
}
