import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_strings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init({void Function(String? memoryId)? onNotificationOpened}) async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');
      final windowsSettings = WindowsInitializationSettings(
        appName: 'Time Capsule',
        appUserModelId: 'com.timecapsule.app',
        guid: '9c5d1e2e-8367-4e01-923f-42e18501e35a',
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _notifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && onNotificationOpened != null) {
            onNotificationOpened(response.payload);
          }
        },
      );

      _isInitialized = true;
      debugPrint('[NotificationService] Local notifications initialized');
    } catch (e) {
      debugPrint('[NotificationService] Notification init failed: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!_isInitialized) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
    }
  }

  /// Sends immediate notification when memory is locked
  Future<void> showMemoryLockedNotification() async {
    if (!_isInitialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'time_capsule_status',
          'Memory Status',
          channelDescription: 'Updates about your locked memories',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _notifications.show(
        id: 0,
        title: AppStrings.notificationScheduledTitle,
        body: AppStrings.notificationScheduledBody,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show locked notification: $e');
    }
  }

  /// Schedules notification for future unlock date
  Future<void> scheduleUnlockNotification({
    required String memoryId,
    required DateTime unlockAtUtc,
  }) async {
    if (!_isInitialized) return;
    try {
      final scheduledDate = tz.TZDateTime.from(unlockAtUtc, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduledDate.isBefore(now)) return;

      final notificationId = memoryId.hashCode & 0x7FFFFFFF;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'time_capsule_unlock',
          'Unlocked Memories',
          channelDescription: 'Alerts when your scheduled time capsule is ready',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

      await _notifications.zonedSchedule(
        id: notificationId,
        title: AppStrings.notificationUnlockTitle,
        body: AppStrings.notificationUnlockBody,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: memoryId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[NotificationService] Scheduled unlock notification for $scheduledDate');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule notification: $e');
    }
  }

  /// Schedules anticipation milestone notifications that fall strictly between now and unlock date.
  Future<void> scheduleCapsuleMilestones({
    required String capsuleId,
    required String capsuleTitle,
    required DateTime createdAtUtc,
    required DateTime unlockAtUtc,
  }) async {
    if (!_isInitialized) return;

    final now = DateTime.now().toUtc();
    if (unlockAtUtc.isBefore(now)) return;

    // First cancel any existing notifications for this capsule
    await cancelCapsuleMilestones(capsuleId);

    final title = capsuleTitle.trim().isNotEmpty ? capsuleTitle.trim() : 'Your Time Capsule';
    final totalDuration = unlockAtUtc.difference(createdAtUtc);

    // List of candidate milestones
    final candidates = <({String key, DateTime date, String body})>[];

    // 1. 7 Days after creation
    final day7 = createdAtUtc.add(const Duration(days: 7));
    if (day7.isAfter(now) && day7.isBefore(unlockAtUtc.subtract(const Duration(days: 2)))) {
      candidates.add((
        key: 'created_plus_7d',
        date: day7,
        body: '7 days ago, you left something for yourself.',
      ));
    }

    // 2. Halfway point (if total duration is at least 6 days)
    if (totalDuration.inDays >= 6) {
      final halfway = createdAtUtc.add(Duration(milliseconds: totalDuration.inMilliseconds ~/ 2));
      if (halfway.isAfter(now) && halfway.isBefore(unlockAtUtc.subtract(const Duration(days: 2)))) {
        candidates.add((
          key: 'halfway',
          date: halfway,
          body: 'Halfway there. Your capsule is waiting.',
        ));
      }
    }

    // 3. 30 Days before unlock (only if created more than 30 days before unlock)
    final daysBefore30 = unlockAtUtc.subtract(const Duration(days: 30));
    if (daysBefore30.isAfter(now) && daysBefore30.isAfter(createdAtUtc)) {
      candidates.add((
        key: 'before_30d',
        date: daysBefore30,
        body: 'Your past self is getting closer.',
      ));
    }

    // 4. 7 Days before unlock
    final daysBefore7 = unlockAtUtc.subtract(const Duration(days: 7));
    if (daysBefore7.isAfter(now) && daysBefore7.isAfter(createdAtUtc)) {
      candidates.add((
        key: 'before_7d',
        date: daysBefore7,
        body: 'One week until you meet yourself again.',
      ));
    }

    // 5. 1 Day before unlock
    final daysBefore1 = unlockAtUtc.subtract(const Duration(days: 1));
    if (daysBefore1.isAfter(now) && daysBefore1.isAfter(createdAtUtc)) {
      candidates.add((
        key: 'before_1d',
        date: daysBefore1,
        body: "Tomorrow, you'll open something you once wanted to remember.",
      ));
    }

    // 6. Unlock day
    candidates.add((
      key: 'unlock_day',
      date: unlockAtUtc,
      body: 'Your memory is ready.',
    ));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'time_capsule_milestones',
        'Time Capsule Anticipation',
        channelDescription: 'Anticipation reminders for your sealed memories',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    for (final m in candidates) {
      try {
        final scheduledDate = tz.TZDateTime.from(m.date, tz.local);
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

        final notificationId = ('$capsuleId:${m.key}').hashCode & 0x7FFFFFFF;
        await _notifications.zonedSchedule(
          id: notificationId,
          title: title,
          body: m.body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          payload: capsuleId,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('[NotificationService] Scheduled milestone [${m.key}] for $scheduledDate');
      } catch (e) {
        debugPrint('[NotificationService] Error scheduling milestone [${m.key}]: $e');
      }
    }
  }

  /// Cancels all candidate milestone notifications for a given capsule
  Future<void> cancelCapsuleMilestones(String capsuleId) async {
    if (!_isInitialized) return;
    const keys = [
      'created_plus_7d',
      'halfway',
      'before_30d',
      'before_7d',
      'before_1d',
      'unlock_day',
    ];
    for (final k in keys) {
      try {
        final id = ('$capsuleId:$k').hashCode & 0x7FFFFFFF;
        await _notifications.cancel(id: id);
      } catch (_) {}
    }
  }

  Future<void> cancelNotification(String memoryId) async {
    if (!_isInitialized) return;
    try {
      final notificationId = memoryId.hashCode & 0x7FFFFFFF;
      await _notifications.cancel(id: notificationId);
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel notification: $e');
    }
  }
}
