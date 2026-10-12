import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/capsule.dart';

void main() {
  group('Capsule Model Tests', () {
    test('JSON serialization round-trip works accurately', () {
      final created = DateTime.utc(2026, 9, 9, 12, 0, 0);
      final unlock = DateTime.utc(2027, 9, 9, 12, 0, 0);

      final capsule = Capsule(
        id: 'cap-101',
        userId: 'traveler-01',
        title: '365 Days of Life',
        createdAt: created,
        unlockAt: unlock,
        status: CapsuleStatus.locked,
      );

      final json = capsule.toJson();
      expect(json['id'], equals('cap-101'));
      expect(json['title'], equals('365 Days of Life'));
      expect(json['status'], equals('locked'));

      final reconstructed = Capsule.fromJson(json);
      expect(reconstructed.id, equals(capsule.id));
      expect(reconstructed.userId, equals(capsule.userId));
      expect(reconstructed.title, equals(capsule.title));
      expect(reconstructed.createdAt, equals(capsule.createdAt));
      expect(reconstructed.unlockAt, equals(capsule.unlockAt));
      expect(reconstructed.status, equals(CapsuleStatus.locked));
      expect(reconstructed.isLocked, isTrue);
      expect(reconstructed.isReady, isFalse);
    });

    test('effectiveStatus transitions automatically when unlock date arrives', () {
      final now = DateTime.now().toUtc();

      // Future date -> locked
      final lockedCapsule = Capsule(
        id: 'c-locked',
        userId: 'u1',
        createdAt: now.subtract(const Duration(days: 30)),
        unlockAt: now.add(const Duration(days: 60)),
        status: CapsuleStatus.locked,
      );
      expect(lockedCapsule.effectiveStatus, equals(CapsuleStatus.locked));
      expect(lockedCapsule.isLocked, isTrue);
      expect(lockedCapsule.isReady, isFalse);

      // Past date -> ready
      final readyCapsule = Capsule(
        id: 'c-ready',
        userId: 'u1',
        createdAt: now.subtract(const Duration(days: 365)),
        unlockAt: now.subtract(const Duration(seconds: 10)),
        status: CapsuleStatus.locked, // Even if persisted status was locked, real-time date makes it ready!
      );
      expect(readyCapsule.effectiveStatus, equals(CapsuleStatus.ready));
      expect(readyCapsule.isReady, isTrue);
      expect(readyCapsule.isLocked, isFalse);

      // Opened status
      final openedCapsule = readyCapsule.copyWith(
        status: CapsuleStatus.opened,
        openedAt: now,
      );
      expect(openedCapsule.effectiveStatus, equals(CapsuleStatus.opened));
      expect(openedCapsule.isOpened, isTrue);
    });

    test('Computes progressRatio, countdown, and formatted strings', () {
      final created = DateTime.now().toUtc().subtract(const Duration(days: 50));
      final unlock = DateTime.now().toUtc().add(const Duration(days: 50));

      final capsule = Capsule(
        id: 'c1',
        userId: 'u1',
        title: 'Midpoint Capsule',
        createdAt: created,
        unlockAt: unlock,
        status: CapsuleStatus.locked,
      );

      expect(capsule.totalDays, greaterThanOrEqualTo(99));
      expect(capsule.progressRatio, inInclusiveRange(0.4, 0.6));
      expect(capsule.heroCountdown.count, greaterThan(0));
      expect(capsule.heroCountdown.unit, equals('DAYS'));
      expect(capsule.formattedUnlockDate, isNotEmpty);
      expect(capsule.formattedCreatedDate, isNotEmpty);
    });
  });
}
