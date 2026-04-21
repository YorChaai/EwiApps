class NotificationModel {
  final int id;
  final int userId;
  final int? actorId;
  final String actorName;
  final String actionType;
  final String targetType;
  final int targetId;
  final String message;
  final bool readStatus;
  final DateTime createdAt;
  final String? linkPath;

  NotificationModel({
    required this.id,
    required this.userId,
    this.actorId,
    required this.actorName,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    required this.message,
    required this.readStatus,
    required this.createdAt,
    this.linkPath,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      actorId: json['actor_id'],
      actorName: json['actor_name'] ?? 'System',
      actionType: json['action_type'] ?? '',
      targetType: json['target_type'] ?? '',
      targetId: json['target_id'] ?? 0,
      message: json['message'] ?? '',
      readStatus: json['read_status'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      linkPath: json['link_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'actor_name': actorName,
      'action_type': actionType,
      'target_type': targetType,
      'target_id': targetId,
      'message': message,
      'read_status': readStatus,
      'created_at': createdAt.toIso8601String(),
      'link_path': linkPath,
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    int? actorId,
    String? actorName,
    String? actionType,
    String? targetType,
    int? targetId,
    String? message,
    bool? readStatus,
    DateTime? createdAt,
    String? linkPath,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actionType: actionType ?? this.actionType,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      message: message ?? this.message,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
      linkPath: linkPath ?? this.linkPath,
    );
  }
}
