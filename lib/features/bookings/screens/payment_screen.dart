import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Price data from booking details API (price object).
class PaymentPriceData {
  const PaymentPriceData({
    required this.currency,
    required this.basePriceCents,
    required this.addonsTotalCents,
    required this.totalCents,
    required this.renizoFeePercent,
    required this.renizoFeeCents,
    required this.providerPayoutCents,
  });

  final String currency;
  final int basePriceCents;
  final int addonsTotalCents;
  final int totalCents;
  final int renizoFeePercent;
  final int renizoFeeCents;
  final int providerPayoutCents;

  double get basePriceAmount => basePriceCents / 100.0;
  double get addonsTotalAmount => addonsTotalCents / 100.0;
  double get totalAmount => totalCents / 100.0;
  double get renizoFeeAmount => renizoFeeCents / 100.0;
  double get providerPayoutAmount => providerPayoutCents / 100.0;
}

/// Payment screen – shows payment summary and checkout using API price data.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.providerName,
    required this.price,
  });

  static const String routeName = '/payment';

  final String providerName;
  final PaymentPriceData price;

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _cardBlueStart = Color(0xFF4F8EF7);
  static const Color _cardBlueEnd = Color(0xFF5A9BF8);

  /// API থেকে যে amount আসে সেটাই দেখায়; দশমিক জোর করা হয় না (২/৩ যত আছে তত).
  String _formatAmount(double amount) {
    final String raw = amount.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    final String value = raw.contains('.') ? raw : amount.toInt().toString();
    final code = price.currency;
    if (code == 'CAD' || code == 'USD') return '\$$value';
    return '$value $code';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: InkWell(
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
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Secure checkout',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                child: Column(
                  children: [
                    _buildPaymentToCard(),
                    SizedBox(height: 16.h),
                    _buildPaymentBreakdownCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5BD3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Pay ${_formatAmount(price.totalAmount)}',
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
    );
  }

  Widget _buildPaymentToCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBlueStart, _cardBlueEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment to',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            providerName,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Container(height: 1, color: Colors.white.withOpacity(0.25)),
          SizedBox(height: 12.h),
          Text(
            'Total Amount (${price.currency})',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatAmount(price.totalAmount),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, size: 20.sp, color: const Color(0xFF0B5BD3)),
              SizedBox(width: 8.w),
              Text(
                'Payment Breakdown (${price.currency})',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 12.h),
          _breakdownRow('Base Price', _formatAmount(price.basePriceAmount)),
          if (price.addonsTotalCents > 0) ...[
            SizedBox(height: 8.h),
            _breakdownRow('Add-ons', _formatAmount(price.addonsTotalAmount)),
          ],
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 12.h),
          _breakdownRow('Total Amount', _formatAmount(price.totalAmount)),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Renizo Service Fee', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
                  SizedBox(width: 6.w),
                  Icon(Icons.info_outline, size: 14.sp, color: Colors.grey.shade500),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatAmount(price.renizoFeeAmount),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  Text(' (${price.renizoFeePercent}%)', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _breakdownRow('Provider Payout', _formatAmount(price.providerPayoutAmount)),
          SizedBox(height: 16.h),
          _buildWarrantyBox(),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
        Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWarrantyBox() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 22.sp, color: const Color(0xFF10B981)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30-Day Workmanship Warranty',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                ),
                SizedBox(height: 6.h),
                Text(
                  'All services include free warranty coverage for workmanship issues within 30 days of completion.',
                  style: TextStyle(fontSize: 12.sp, color: const Color(0xFF047857), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
