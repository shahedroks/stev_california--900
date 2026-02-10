import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/providers/logic/provider_public_logic.dart';
import 'package:renizo/features/providers/models/provider_public_model.dart';

class ProviderPublicProfileScreen extends ConsumerWidget {
  const ProviderPublicProfileScreen({
    super.key,
    required this.providerUserId,
    this.initialName,
    this.initialLogoUrl,
  });

  final String providerUserId;
  final String? initialName;
  final String? initialLogoUrl;

  static const Color _bgBlue = Color(0xFF2384F4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providerPublicProfileProvider(providerUserId));

    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => _buildError(context, e.toString(), ref),
                data: (data) => _buildContent(data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load provider',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              msg,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () =>
                  ref.invalidate(providerPublicProfileProvider(providerUserId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProviderPublicData data) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _buildHeader(data),
        SizedBox(height: 18.h),
        _buildServicesCard(data.servicesOffered),
        SizedBox(height: 12.h),
        _buildResponseTimeCard(),
        SizedBox(height: 20.h),
        _buildReviewsSection(data.recentReviews),
      ],
    );
  }

  Widget _buildHeader(ProviderPublicData data) {
    final provider = data.provider;
    final name = provider.name.isNotEmpty
        ? provider.name
        : (initialName ?? 'Provider');
    final logoUrl =
        provider.logoUrl.isNotEmpty ? provider.logoUrl : (initialLogoUrl ?? '');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final serviceLabel = data.servicesOffered.isNotEmpty
        ? data.servicesOffered.first.name
        : 'Service';

    return Column(
      children: [
        _buildAvatar(logoUrl, initial),
        SizedBox(height: 10.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Text(
          serviceLabel,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(height: 8.h),
        _buildRatingRow(data.stats.rating, data.stats.reviewCount),
      ],
    );
  }

  Widget _buildAvatar(String imageUrl, String initial) {
    return Container(
      width: 78.w,
      height: 78.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarFallback(initial),
                errorWidget: (_, __, ___) => _avatarFallback(initial),
              )
            : _avatarFallback(initial),
      ),
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF408AF1), Color(0xFF5ca3f5)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRatingRow(double rating, int reviewCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, size: 16.sp, color: const Color(0xFFFBBF24)),
        SizedBox(width: 4.w),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (reviewCount > 0) ...[
          SizedBox(width: 6.w),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicesCard(List<ProviderPublicService> services) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18.sp, color: AllColor.primary),
              SizedBox(width: 8.w),
              Text(
                'Services Offered',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AllColor.foreground,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (services.isEmpty)
            Text(
              'No services listed',
              style: TextStyle(
                fontSize: 13.sp,
                color: AllColor.mutedForeground,
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: services
                  .map(
                    (s) => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AllColor.foreground,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.schedule, size: 18.sp, color: AllColor.primary),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Response Time',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AllColor.foreground,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Usually responds in 2-4 hours',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AllColor.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List<ProviderPublicReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        if (reviews.isEmpty)
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              'No reviews yet',
              style: TextStyle(fontSize: 13.sp, color: AllColor.mutedForeground),
            ),
          )
        else
          ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProviderPublicReview review;

  String _formatDate(String value) {
    final dt = DateTime.tryParse(value);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildStars(double rating) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star : Icons.star_border,
          size: 14.sp,
          color: const Color(0xFFFBBF24),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        review.customer.name.isNotEmpty ? review.customer.name : 'Customer';
    final date = _formatDate(review.createdAt);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AllColor.foreground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AllColor.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStars(review.rating),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 12.sp,
              color: AllColor.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
