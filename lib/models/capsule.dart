import '../core/utils/date_utils.dart';

enum CapsuleStatus {
  locked,
  ready,
  opened;

  static CapsuleStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'ready':
        return CapsuleStatus.ready;
      case 'opened':
        return CapsuleStatus.opened;
      case 'locked':
      default:
        return CapsuleStatus.locked;
    }
  }

  String get value => name;
}

/// Represents a Time Capsule container spanning a period of time.
/// Can hold unlimited daily memories until unlocked.
class Capsule {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt; // In UTC
  final DateTime unlockAt;  // In UTC
  final CapsuleStatus status;
  final DateTime? openedAt; // In UTC
  final DateTime? deletedAt;

  const Capsule({
    required this.id,
    required this.userId,
    this.title = 'My Future Self',
    required this.createdAt,
    required this.unlockAt,
    required this.status,
    this.openedAt,
    this.deletedAt,
  });

  /// Evaluates real-time status
  CapsuleStatus get effectiveStatus {
    if (openedAt != null || status == CapsuleStatus.opened) {
      return CapsuleStatus.opened;
    }
    final nowUtc = DateTime.now().toUtc();
    if (unlockAt.isBefore(nowUtc) || unlockAt.isAtSameMomentAs(nowUtc)) {
      return CapsuleStatus.ready;
    }
    return CapsuleStatus.locked;
  }

  bool get isLocked => effectiveStatus == CapsuleStatus.locked;
  bool get isReady => effectiveStatus == CapsuleStatus.ready;
  bool get isOpened => effectiveStatus == CapsuleStatus.opened;

  /// User facing countdown string
  String get countdownString => CapsuleDateUtils.formatCountdown(unlockAt);

  /// Hero countdown record (count: 365, unit: 'DAYS')
  ({int count, String unit}) get heroCountdown =>
      CapsuleDateUtils.getHeroCountdown(unlockAt);

  /// Calendar days metrics for subtle progress indicator
  int get totalDays {
    final diff = unlockAt.difference(createdAt).inDays;
    return diff > 0 ? diff : 1;
  }

  int get daysElapsed {
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(createdAt).inDays;
    if (elapsed < 0) return 0;
    if (elapsed > totalDays) return totalDays;
    return elapsed;
  }

  /// Exact progress ratio between 0.0 (sealed) and 1.0 (unlocked)
  double get progressRatio {
    final totalMs = unlockAt.difference(createdAt).inMilliseconds;
    if (totalMs <= 0) return 1.0;
    final elapsedMs = DateTime.now().toUtc().difference(createdAt).inMilliseconds;
    if (elapsedMs <= 0) return 0.0;
    if (elapsedMs >= totalMs) return 1.0;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  String get formattedUnlockDate => CapsuleDateUtils.formatFullDate(unlockAt);
  String get formattedCreatedDate => CapsuleDateUtils.formatFullDate(createdAt);
  String get shortCreatedDate => CapsuleDateUtils.formatShortDate(createdAt);
  String get shortUnlockDate => CapsuleDateUtils.formatShortDate(unlockAt);
  String get relativeOriginText => CapsuleDateUtils.formatRelativeOrigin(createdAt);

  Capsule copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? unlockAt,
    CapsuleStatus? status,
    DateTime? openedAt,
    DateTime? deletedAt,
  }) {
    return Capsule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Capsule.fromJson(Map<String, dynamic> json) {
    return Capsule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] as String?)?.isNotEmpty == true
          ? json['title'] as String
          : 'My Future Self',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      unlockAt: DateTime.parse(json['unlock_at'] as String).toUtc(),
      status: CapsuleStatus.fromString(json['status'] as String? ?? 'locked'),
      openedAt: json['opened_at'] != null
          ? DateTime.parse(json['opened_at'] as String).toUtc()
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String).toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'unlock_at': unlockAt.toIso8601String(),
      'status': status.value,
      'opened_at': openedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
