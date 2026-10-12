import 'package:intl/intl.dart';
import '../core/utils/date_utils.dart';

/// Strongly typed domain model representing a single memory moment inside a Capsule.
class Memory {
  final String id;
  final String capsuleId;
  final String userId;
  final String? title;
  final String content;
  final String? imageUrl;
  final String memoryType; // 'note', 'photo', 'voice', 'video'
  final bool isImportant;  // ⭐ "Moments that mattered"
  final DateTime capturedAt; // In UTC
  final DateTime createdAt;  // In UTC
  final DateTime? deletedAt;

  const Memory({
    required this.id,
    required this.capsuleId,
    required this.userId,
    this.title,
    required this.content,
    this.imageUrl,
    this.memoryType = 'note',
    this.isImportant = false,
    required this.capturedAt,
    required this.createdAt,
    this.deletedAt,
  });

  /// Key used to group memories under the same calendar date in the timeline
  String get dayKey => DateFormat('yyyy-MM-dd').format(capturedAt.toLocal());

  /// Formatted day label: "September 9, 2026"
  String get formattedDay => DateFormat('MMMM d, y').format(capturedAt.toLocal());

  /// Short day label: "Sep 9"
  String get shortDay => DateFormat('MMM d').format(capturedAt.toLocal());

  /// Formatted time: "4:15 PM"
  String get formattedTime => DateFormat('h:mm a').format(capturedAt.toLocal());

  /// Relative origin text for reveal experience: "One year ago…", "Yesterday…"
  String get relativeOriginText => CapsuleDateUtils.formatRelativeOrigin(capturedAt);

  /// Full created date string
  String get formattedCreatedDate => CapsuleDateUtils.formatFullDate(capturedAt);
  String get formattedDate => formattedDay;

  bool get hasPhoto => imageUrl != null && imageUrl!.isNotEmpty;

  Memory copyWith({
    String? id,
    String? capsuleId,
    String? userId,
    String? title,
    String? content,
    String? imageUrl,
    String? memoryType,
    bool? isImportant,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Memory(
      id: id ?? this.id,
      capsuleId: capsuleId ?? this.capsuleId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      memoryType: memoryType ?? this.memoryType,
      isImportant: isImportant ?? this.isImportant,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      capsuleId: json['capsule_id'] as String? ?? '',
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      memoryType: json['memory_type'] as String? ?? (json['image_url'] != null ? 'photo' : 'note'),
      isImportant: json['is_important'] as bool? ?? false,
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'] as String).toUtc()
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String).toUtc()
              : DateTime.now().toUtc()),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String).toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capsule_id': capsuleId,
      'user_id': userId,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'memory_type': memoryType,
      'is_important': isImportant,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
