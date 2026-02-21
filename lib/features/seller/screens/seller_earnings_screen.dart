import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';
import 'package:renizo/features/seller/data/earnings_api_service.dart';
import 'package:renizo/features/seller/models/seller_job_item.dart';
import 'package:renizo/features/seller/screens/provider_payout_screen.dart';

// TSX SellerEarningsScreen.tsx colors
class _EarningsColors {
  static const blueBg = Color(0xFF2384F4);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray200 = Color(0xFFF3F4F6);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);
  static const teal = Color(0xFF5DD9C1);
  static const tealLight = Color(0xFFE6FAF5);
  static const green100 = Color(0xFFDCFCE7);
  static const green700 = Color(0xFF15803D);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow700 = Color(0xFFA16207);
  static const blueGradientStart = Color(0xFF408AF1);
  static const blueGradientEnd = Color(0xFF5ca3f5);
}

/// Transaction item – mirrors TSX Transaction interface.
class _Transaction {
  final String id;
  final String customerName;
  final String categoryName;
  final double amount;
  /// Net amount (e.g. from API amountEarned). If null, UI uses amount * 0.90.
  final double? netAmount;
  final String date;
  final String status; // completed | pending | refunded
  final String bookingId;

  const _Transaction({
    required this.id,
    required this.customerName,
    required this.categoryName,
    required this.amount,
    this.netAmount,
    required this.date,
    required this.status,
    required this.bookingId,
  });
}

/// Seller earnings – full conversion from React SellerEarningsScreen.tsx.
/// Blue header, period selector (Today/Week/Month/All), performance stats, recent transactions, withdrawal button.
class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({
    super.key,
    this.showAppBar = true,
    this.bookings = const [],
  });

  final bool showAppBar;
  final List<SellerJobItem> bookings;

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  String _selectedPeriod = 'week'; // today | week | month | all
  bool _showEarningsBreakdown = false;

  bool _loading = true;
  String? _error;
  EarningsResponse? _data;
  final EarningsApiService _earningsApi = EarningsApiService();

  double get _netToday => _data?.summary.todayDouble ?? 0;
  double get _netWeek => _data?.summary.thisWeekDouble ?? 0;
  double get _netMonth => _data?.summary.thisMonthDouble ?? 0;
  double get _netTotal => _data?.summary.allTimeDouble ?? 0;

  List<_Transaction> get _transactions {
    if (_data == null) return [];
    return _data!.recentTransactions.map((t) {
      final dateStr = _formatCompletedAt(t.completedAt);
      return _Transaction(
        id: t.id,
        customerName: t.customerName,
        categoryName: t.serviceName,
        amount: t.totalAmountDouble,
        netAmount: t.amountEarnedDouble,
        date: dateStr,
        status: t.status,
        bookingId: t.bookingId,
      );
    }).toList();
  }

  static String _formatCompletedAt(String isoDate) {
    if (isoDate.isEmpty) return '—';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return 'Today, $time';
    if (d == yesterday) return 'Yesterday, $time';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $time';
  }

  /// [showFullScreenLoading] – when true (e.g. initial load), show full-screen spinner. When false (refresh), keep content visible.
  Future<void> _loadEarnings({bool showFullScreenLoading = true}) async {
    if (!mounted) return;
    setState(() {
      _error = null;
      if (showFullScreenLoading) _loading = true;
    });
    final response = await _earningsApi.getEarnings(transactionsLimit: 10);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response == null) {
        _error = 'Failed to load earnings. Check your connection.';
      } else {
        _data = response;
        _error = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header – TSX: px-4 py-6 text-white
        Container(
          width: double.infinity,
          color: _EarningsColors.blueBg,
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earnings', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(height: 8.h),
                Text('Track your revenue and performance', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ),
        // Scrollable – TSX: flex-1 overflow-y-auto px-4 space-y-4 pb-6
        Expanded(
          child: Container(
            color: _EarningsColors.blueBg,
            child: _loading
                ? Center(
                    child: SizedBox(
                      width: 48.w,
                      height: 48.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48.sp, color: Colors.white70),
                              SizedBox(height: 16.h),
                              Text(
                                _error!,
                                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              TextButton.icon(
                                onPressed: _loadEarnings,
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: Text('Retry', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadEarnings(showFullScreenLoading: false),
                        color: _EarningsColors.blueBg,
                        backgroundColor: Colors.white,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                          children: [
                            _PeriodCard(
                              selectedPeriod: _selectedPeriod,
                              onPeriodChanged: (id) => setState(() => _selectedPeriod = id),
                              showBreakdown: _showEarningsBreakdown,
                              onToggleBreakdown: () => setState(() => _showEarningsBreakdown = !_showEarningsBreakdown),
                              netToday: _netToday,
                              netWeek: _netWeek,
                              netMonth: _netMonth,
                              netTotal: _netTotal,
                            ),
                            SizedBox(height: 16.h),
                            _PerformanceCard(performance: _data?.performance),
                            SizedBox(height: 16.h),
                            _TransactionsCard(transactions: _transactions),
                            SizedBox(height: 16.h),
                            _PayoutButton(),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return content;
    return Scaffold(
      backgroundColor: _EarningsColors.blueBg,
      appBar: AppBar(
        title: Text('Earnings', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: _EarningsColors.blueBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 24.sp),
            onPressed: _loading ? null : () => _loadEarnings(showFullScreenLoading: false),
            tooltip: 'Refresh',
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: AppLogoButton(size: 34),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _PayoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProviderPayoutScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _EarningsColors.blueBg,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(
          'Set Provider Payout',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Period selector – TSX: white rounded-2xl p-4, Your Net Earnings, breakdown toggle, grid 2x2 period buttons.
class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.showBreakdown,
    required this.onToggleBreakdown,
    required this.netToday,
    required this.netWeek,
    required this.netMonth,
    required this.netTotal,
  });

  final String selectedPeriod;
  final void Function(String) onPeriodChanged;
  final bool showBreakdown;
  final VoidCallback onToggleBreakdown;
  final double netToday;
  final double netWeek;
  final double netMonth;
  final double netTotal;

  @override
  Widget build(BuildContext context) {
    final periods = [
      ('today', 'Today', netToday),
      ('week', 'This Week', netWeek),
      ('month', 'This Month', netMonth),
      ('all', 'All Time', netTotal),
    ];
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Net Earnings', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _EarningsColors.gray900)),
              IconButton(
                icon: Icon(Icons.info_outline, size: 20.sp, color: _EarningsColors.gray500),
                onPressed: onToggleBreakdown,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (showBreakdown) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: _EarningsColors.tealLight, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _EarningsColors.teal.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net Earnings = Your Earnings After Fees', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: _EarningsColors.gray700)),
                  SizedBox(height: 8.h),
                  Text('Renizo deducts a 10% service fee from each job. This fee covers platform maintenance and payment processing. You keep 90% of every job payment.', style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray600, height: 1.4)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.4,
            children: periods.map((p) {
              final id = p.$1;
              final label = p.$2;
              final amount = p.$3;
              final isSelected = selectedPeriod == id;
              return GestureDetector(
                onTap: () => onPeriodChanged(id),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [_EarningsColors.blueGradientStart, _EarningsColors.blueGradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: isSelected ? null : _EarningsColors.gray200,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: isSelected ? [BoxShadow(color: _EarningsColors.blueGradientStart.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 2))] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12.sp, color: isSelected ? Colors.white.withOpacity(0.85) : _EarningsColors.gray600)),
                      SizedBox(height: 4.h),
                      Text('\$${amount.toStringAsFixed(1)}', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _EarningsColors.gray700)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Performance stats – TSX: white rounded-2xl p-4, grid 2x2 (Completed, Rating, Response, Success).
class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({this.performance});

  final EarningsPerformance? performance;

  @override
  Widget build(BuildContext context) {
    final p = performance;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _EarningsColors.gray900)),
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.1,
            children: [
              _StatTile(icon: Icons.calendar_today_outlined, iconColor: Colors.green, label: 'Completed', value: '${p?.totalJobsCompleted ?? 0}', sublabel: 'Total Jobs'),
              _StatTile(icon: Icons.star_outline, iconColor: Colors.amber, label: 'Rating', value: p != null ? p.averageRating.toStringAsFixed(1) : '—', sublabel: 'Average Score'),
              _StatTile(icon: Icons.trending_up, iconColor: Colors.blue, label: 'Response', value: p?.averageResponseTime ?? '—', sublabel: 'Avg. Time'),
              _StatTile(icon: Icons.emoji_events_outlined, iconColor: Colors.purple, label: 'Success', value: p != null ? '${p.jobSuccessRate}%' : '—', sublabel: 'Job Success'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.iconColor, required this.label, required this.value, required this.sublabel});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _EarningsColors.blueGradientStart.withOpacity(0.3), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(8.r)),
                child: Icon(icon, size: 16.sp, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray600)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600, color: _EarningsColors.gray900)),
          SizedBox(height: 2.h),
          Text(sublabel, style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray500)),
        ],
      ),
    );
  }
}

/// Recent transactions list.
class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<_Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _EarningsColors.gray900)),
              Text('Your net earnings', style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray500)),
            ],
          ),
          SizedBox(height: 12.h),
          ...transactions.map((t) {
            final netAmount = (t.netAmount ?? t.amount * 0.90).toStringAsFixed(1);
            final statusColor = t.status == 'completed' ? (_EarningsColors.green100, _EarningsColors.green700) : t.status == 'pending' ? (_EarningsColors.yellow100, _EarningsColors.yellow700) : (_EarningsColors.gray100, _EarningsColors.gray700);
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: _EarningsColors.gray50, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _EarningsColors.gray100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.customerName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: _EarningsColors.gray900)),
                              SizedBox(height: 2.h),
                              Text(t.categoryName, style: TextStyle(fontSize: 14.sp, color: _EarningsColors.gray500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('+\$$netAmount', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _EarningsColors.teal)),
                            Text('of \$${t.amount.toStringAsFixed(1)}', style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray400)),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(color: statusColor.$1, borderRadius: BorderRadius.circular(12.r)),
                              child: Text(t.status[0].toUpperCase() + t.status.substring(1), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: statusColor.$2)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(t.date, style: TextStyle(fontSize: 12.sp, color: _EarningsColors.gray500)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
