enum NotificationItemType { booking, message, promotion, reminder, other }

NotificationItemType _typeFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'booking':
      return NotificationItemType.booking;
    case 'message':
      return NotificationItemType.message;
    case 'promotion':
      return NotificationItemType.promotion;
    case 'reminder':
      return NotificationItemType.reminder;
    default:
      return NotificationItemType.other;
  }
}

String _formatTimestamp(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$mm/$dd/${local.year}';
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.unread,
  });

  final String id;
  final NotificationItemType type;
  final String title;
  final String message;
  final String timestamp;
  final bool unread;

  NotificationItem copyWith({
    String? title,
    String? message,
    String? timestamp,
    NotificationItemType? type,
    bool? unread,
  }) {
    return NotificationItem(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      unread: unread ?? this.unread,
    );
  }

  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    final createdAt = json['createdAt']?.toString();
    final message = json['body'] ?? json['message'];
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final readAt = json['readAt'];
    return NotificationItem(
      id: id,
      type: _typeFromString(json['type']?.toString()),
      title: json['title']?.toString() ?? 'Notification',
      message: message?.toString() ?? '',
      timestamp: _formatTimestamp(createdAt),
      unread: readAt == null || readAt.toString().isEmpty,
    );
  }
}
