import 'package:flutter/foundation.dart';

/// Minimal, privacy-friendly analytics tracker for Time Capsule MVP
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final List<Map<String, dynamic>> _loggedEvents = [];
  List<Map<String, dynamic>> get loggedEvents => List.unmodifiable(_loggedEvents);

  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    final payload = {
      'event': eventName,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...?parameters,
    };
    _loggedEvents.add(payload);
    debugPrint('[Analytics] $eventName: $parameters');
  }

  void accountCreated() => logEvent('account_created');
  void onboardingCompleted() => logEvent('onboarding_completed');
  void memoryCreated({required bool hasPhoto}) => logEvent('memory_created', {'has_photo': hasPhoto});
  void photoAdded() => logEvent('photo_added');
  void memoryLocked({required int durationInDays}) => logEvent('memory_locked', {'duration_days': durationInDays});
  void memoryOpened({required String memoryId}) => logEvent('memory_opened', {'memory_id': memoryId});
  void memoryShared({required String memoryId}) => logEvent('memory_shared', {'memory_id': memoryId});
  void memoryDeleted({required String memoryId}) => logEvent('memory_deleted', {'memory_id': memoryId});
  void notificationOpened({required String memoryId}) => logEvent('notification_opened', {'memory_id': memoryId});
}
