class BookingsMeData {
  final List<BookingsMeItem> items;
  final BookingsMeMeta meta;

  const BookingsMeData({required this.items, required this.meta});

  factory BookingsMeData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final metaJson = json['meta'];

    return BookingsMeData(
      items: (itemsJson is List)
          ? itemsJson
                .whereType<Map>()
                .map((e) => BookingsMeItem.fromJson(e.cast<String, dynamic>()))
                .toList()
          : <BookingsMeItem>[],
      meta: (metaJson is Map<String, dynamic>)
          ? BookingsMeMeta.fromJson(metaJson)
          : const BookingsMeMeta(total: 0, page: 1, limit: 20),
    );
  }
}

class BookingsMeMeta {
  final int total;
  final int page;
  final int limit;

  const BookingsMeMeta({
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BookingsMeMeta.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return BookingsMeMeta(
      total: _asInt(json['total'], 0),
      page: _asInt(json['page'], 1),
      limit: _asInt(json['limit'], 20),
    );
  }
}

class BookingsMeItem {
  final String id;
  final String providerName;
  final String providerAvatar;
  final String categoryName;
  final String status;
  final String scheduledDate;
  final String scheduledTime;

  const BookingsMeItem({
    required this.id,
    required this.providerName,
    required this.providerAvatar,
    required this.categoryName,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  static String _s(dynamic v) => (v == null) ? '' : v.toString();

  factory BookingsMeItem.fromJson(Map<String, dynamic> json) {
    // id fallback
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    // provider object fallback
    final provider = json['provider'];
    final providerName = _s(json['providerName']).isNotEmpty
        ? _s(json['providerName'])
        : (provider is Map ? _s(provider['name']) : '');

    final providerAvatar = _s(json['providerAvatar']).isNotEmpty
        ? _s(json['providerAvatar'])
        : (provider is Map ? _s(provider['avatar']) : '');

    // category fallback
    final category = json['category'];
    final categoryName = _s(json['categoryName']).isNotEmpty
        ? _s(json['categoryName'])
        : (category is Map ? _s(category['name']) : '');

    return BookingsMeItem(
      id: id,
      providerName: providerName,
      providerAvatar: providerAvatar,
      categoryName: categoryName,
      status: _s(json['status']),
      scheduledDate: _s(json['scheduledDate']),
      scheduledTime: _s(json['scheduledTime']),
    );
  }
}
