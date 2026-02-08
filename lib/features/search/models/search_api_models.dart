/// Models for GET /search?q=...&townId=...&type=all
/// Response shape:
/// {
///   "status": "success",
///   "message": "Search results",
///   "data": {
///     "providers": [ ... ],
///     "services": [ ... ]
///   }
/// }

class SearchApiResponse {
  final String status;
  final String message;
  final SearchApiData data;

  const SearchApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SearchApiResponse.fromJson(Map<String, dynamic> json) {
    return SearchApiResponse(
      status: _s(json['status']),
      message: _s(json['message']),
      data: json['data'] is Map<String, dynamic>
          ? SearchApiData.fromJson(json['data'] as Map<String, dynamic>)
          : const SearchApiData(providers: [], services: []),
    );
  }
}

class SearchApiData {
  final List<SearchApiProvider> providers;
  final List<SearchApiService> services;

  const SearchApiData({
    required this.providers,
    required this.services,
  });

  factory SearchApiData.fromJson(Map<String, dynamic> json) {
    return SearchApiData(
      providers: _safeList(json['providers'], SearchApiProvider.fromJson),
      services: _safeList(json['services'], SearchApiService.fromJson),
    );
  }

  bool get isEmpty => providers.isEmpty && services.isEmpty;
}

/// A provider returned from the search API.
class SearchApiProvider {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final int reviewCount;
  final String categoryId;
  final String categoryName;
  final String distance;
  final String responseTime;

  const SearchApiProvider({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
    required this.categoryName,
    required this.distance,
    required this.responseTime,
  });

  factory SearchApiProvider.fromJson(Map<String, dynamic> json) {
    // id fallback: _id → id
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    // name fallback: name → fullName → businessName
    final name = _s(json['name']).isNotEmpty
        ? _s(json['name'])
        : _s(json['fullName']).isNotEmpty
            ? _s(json['fullName'])
            : _s(json['businessName']);

    // avatar fallback
    final avatar = _s(json['avatar']).isNotEmpty
        ? _s(json['avatar'])
        : _s(json['avatarUrl']);

    // category
    final category = json['category'];
    final categoryId = _s(json['categoryId']).isNotEmpty
        ? _s(json['categoryId'])
        : (category is Map ? _s(category['_id'] ?? category['id']) : '');
    final categoryName = _s(json['categoryName']).isNotEmpty
        ? _s(json['categoryName'])
        : (category is Map ? _s(category['name']) : '');

    return SearchApiProvider(
      id: id,
      name: name,
      avatar: avatar,
      rating: _asDouble(json['rating'], 0.0),
      reviewCount: _asInt(json['reviewCount'] ?? json['reviews'], 0),
      categoryId: categoryId,
      categoryName: categoryName,
      distance: _s(json['distance']),
      responseTime: _s(json['responseTime']),
    );
  }
}

/// A service/category returned from the search API.
class SearchApiService {
  final String id;
  final String name;
  final String description;
  final String icon;

  const SearchApiService({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory SearchApiService.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return SearchApiService(
      id: id,
      name: _s(json['name']),
      description: _s(json['description']),
      icon: _s(json['icon']),
    );
  }
}

// ── Search params (used as family key) ───────────────────────────────────────

class SearchParams {
  final String query;
  final String townId;
  final String type;

  const SearchParams({
    required this.query,
    required this.townId,
    this.type = 'all',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          other.query == query &&
          other.townId == townId &&
          other.type == type;

  @override
  int get hashCode => Object.hash(query, townId, type);
}

// ── helpers ──────────────────────────────────────────────────────────────────

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
