class ProviderPublicResponse {
  final String status;
  final ProviderPublicData data;

  const ProviderPublicResponse({
    required this.status,
    required this.data,
  });

  factory ProviderPublicResponse.fromJson(Map<String, dynamic> json) {
    return ProviderPublicResponse(
      status: _s(json['status']),
      data: json['data'] is Map<String, dynamic>
          ? ProviderPublicData.fromJson(json['data'] as Map<String, dynamic>)
          : const ProviderPublicData.empty(),
    );
  }
}

class ProviderPublicData {
  final ProviderPublicProvider provider;
  final ProviderPublicStats stats;
  final List<ProviderPublicArea> serviceAreas;
  final List<ProviderPublicService> servicesOffered;
  final List<ProviderPublicReview> recentReviews;

  const ProviderPublicData({
    required this.provider,
    required this.stats,
    required this.serviceAreas,
    required this.servicesOffered,
    required this.recentReviews,
  });

  const ProviderPublicData.empty()
      : provider = const ProviderPublicProvider(id: '', name: '', logoUrl: ''),
        stats = const ProviderPublicStats(rating: 0, reviewCount: 0),
        serviceAreas = const [],
        servicesOffered = const [],
        recentReviews = const [];

  factory ProviderPublicData.fromJson(Map<String, dynamic> json) {
    return ProviderPublicData(
      provider: json['provider'] is Map<String, dynamic>
          ? ProviderPublicProvider.fromJson(
              json['provider'] as Map<String, dynamic>,
            )
          : const ProviderPublicProvider(id: '', name: '', logoUrl: ''),
      stats: json['stats'] is Map<String, dynamic>
          ? ProviderPublicStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const ProviderPublicStats(rating: 0, reviewCount: 0),
      serviceAreas: _safeList(
        json['serviceAreas'],
        ProviderPublicArea.fromJson,
      ),
      servicesOffered: _safeList(
        json['servicesOffered'],
        ProviderPublicService.fromJson,
      ),
      recentReviews: _safeList(
        json['recentReviews'],
        ProviderPublicReview.fromJson,
      ),
    );
  }
}

class ProviderPublicProvider {
  final String id;
  final String name;
  final String logoUrl;

  const ProviderPublicProvider({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  factory ProviderPublicProvider.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return ProviderPublicProvider(
      id: id,
      name: _s(json['name']),
      logoUrl: _s(json['logoUrl']),
    );
  }
}

class ProviderPublicStats {
  final double rating;
  final int reviewCount;

  const ProviderPublicStats({
    required this.rating,
    required this.reviewCount,
  });

  factory ProviderPublicStats.fromJson(Map<String, dynamic> json) {
    return ProviderPublicStats(
      rating: _asDouble(json['rating'], 0),
      reviewCount: _asInt(json['reviewCount'], 0),
    );
  }
}

class ProviderPublicArea {
  final String id;
  final String name;

  const ProviderPublicArea({required this.id, required this.name});

  factory ProviderPublicArea.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return ProviderPublicArea(id: id, name: _s(json['name']));
  }
}

class ProviderPublicService {
  final String id;
  final String name;

  const ProviderPublicService({required this.id, required this.name});

  factory ProviderPublicService.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    final name = _s(json['name']).isNotEmpty ? _s(json['name']) : _s(json['title']);
    return ProviderPublicService(id: id, name: name);
  }
}

class ProviderPublicReview {
  final String id;
  final double rating;
  final String comment;
  final String createdAt;
  final ProviderPublicCustomer customer;

  const ProviderPublicReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.customer,
  });

  factory ProviderPublicReview.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return ProviderPublicReview(
      id: id,
      rating: _asDouble(json['rating'], 0),
      comment: _s(json['comment']),
      createdAt: _s(json['createdAt']),
      customer: json['customer'] is Map<String, dynamic>
          ? ProviderPublicCustomer.fromJson(
              json['customer'] as Map<String, dynamic>,
            )
          : const ProviderPublicCustomer(id: '', name: '', avatarUrl: ''),
    );
  }
}

class ProviderPublicCustomer {
  final String id;
  final String name;
  final String avatarUrl;

  const ProviderPublicCustomer({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory ProviderPublicCustomer.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return ProviderPublicCustomer(
      id: id,
      name: _s(json['name']),
      avatarUrl: _s(json['avatarUrl']),
    );
  }
}

String _s(dynamic v) => (v == null) ? '' : v.toString();

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic v, double fallback) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

List<T> _safeList<T>(dynamic v, T Function(Map<String, dynamic>) parser) {
  if (v is! List) return [];
  return v
      .whereType<Map>()
      .map((e) => parser(e.cast<String, dynamic>()))
      .toList();
}
