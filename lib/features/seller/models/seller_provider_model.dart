class SellerProviderModel {
  final ProviderUser user;
  final ProviderStats stats;
  final List<String> serviceAreas;
  final List<ProviderService> servicesOffered;

  const SellerProviderModel({
    required this.user,
    required this.stats,
    required this.serviceAreas,
    required this.servicesOffered,
  });

  factory SellerProviderModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? {};
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    final statsJson = (data['stats'] as Map<String, dynamic>?) ?? {};

    final rawAreas = (data['serviceAreas'] as List?) ?? const [];
    final rawServices = (data['servicesOffered'] as List?) ?? const [];

    String toStr(dynamic v) => (v ?? '').toString();

    final areas = rawAreas
        .map((e) {
          if (e is String) return e;
          if (e is Map) return toStr(e['name']);
          return toStr(e);
        })
        .where((x) => x.trim().isNotEmpty)
        .toList();

    final services = rawServices
        .map((e) {
          if (e is Map) {
            return ProviderService.fromJson(e.cast<String, dynamic>());
          }
          if (e is String) {
            return ProviderService(id: '', name: e, description: '', iconUrl: '');
          }
          return ProviderService(
            id: '',
            name: toStr(e),
            description: '',
            iconUrl: '',
          );
        })
        .where((s) => s.name.trim().isNotEmpty)
        .toList();

    return SellerProviderModel(
      user: ProviderUser.fromJson(userJson),
      stats: ProviderStats.fromJson(statsJson),
      serviceAreas: areas,
      servicesOffered: services,
    );
  }
}

class ProviderUser {
  final String fullName;
  final String email;
  final String? badge;

  const ProviderUser({
    required this.fullName,
    required this.email,
    required this.badge,
  });

  factory ProviderUser.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => (v ?? '').toString();
    final badge = json['badge'];
    return ProviderUser(
      fullName: toStr(json['fullName']),
      email: toStr(json['email']),
      badge: badge == null ? null : toStr(badge),
    );
  }
}

class ProviderStats {
  final int jobsDone;
  final double rating;
  final int ratingCount;
  final int successRate;

  const ProviderStats({
    required this.jobsDone,
    required this.rating,
    required this.ratingCount,
    required this.successRate,
  });

  factory ProviderStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;

    return ProviderStats(
      jobsDone: toInt(json['jobsDone']),
      rating: toDouble(json['rating']),
      ratingCount: toInt(json['ratingCount']),
      successRate: toInt(json['successRate']),
    );
  }
}

class ProviderService {
  final String id;
  final String name;
  final String description;
  final String iconUrl;

  const ProviderService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => (v ?? '').toString();
    return ProviderService(
      id: toStr(json['_id'] ?? json['id']),
      name: toStr(json['name'] ?? json['title']),
      description: toStr(json['description'] ?? json['desc'] ?? ''),
      iconUrl: toStr(json['iconUrl'] ?? json['icon'] ?? json['image']),
    );
  }
}
