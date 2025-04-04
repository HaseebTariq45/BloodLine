class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool read;
  final String createdAt;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.metadata = const {},
  });

  // Create a notification model from a map
  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      read: map['read'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Convert notification model to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }

  // Get notification icon based on type
  String get iconAsset {
    switch (type) {
      case 'blood_request_response':
        return 'assets/icons/blood_drop.svg';
      case 'donation_reminder':
        return 'assets/icons/calendar.svg';
      case 'urgent_request':
        return 'assets/icons/emergency.svg';
      default:
        return 'assets/icons/notification.svg';
    }
  }

  // Get time since notification was created
  String get timeAgo {
    final now = DateTime.now();
    final createdDateTime = DateTime.parse(createdAt);
    final difference = now.difference(createdDateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdDateTime.day}/${createdDateTime.month}/${createdDateTime.year}';
    }
  }

  // Helper method to create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? read,
    String? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
