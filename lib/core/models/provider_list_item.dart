/// UI-optimized provider list item – aligned with just_tsx_code domain/models.ts ProviderListItem.
/// For booking API use [userId] as providerId (not id); id is the provider document _id.
class ProviderListItem {
  const ProviderListItem({
    required this.id,
    required this.displayName,
    this.userId,
    this.avatar = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.distance = '',
    this.responseTime = '',
    this.availableToday = false,
    this.categoryNames = const [],
  });

  final String id;
  /// User id – use this as providerId when creating a booking (API expects userId).
  final String? userId;
  final String displayName;
  final String avatar;
  final double rating;
  final int reviewCount;
  final String distance;
  final String responseTime;
  final bool availableToday;
  final List<String> categoryNames;
}
