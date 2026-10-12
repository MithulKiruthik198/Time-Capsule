import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/core/utils/date_utils.dart';

void main() {
  group('CapsuleDateUtils Tests', () {
    test('isLeapYear identifies leap years correctly', () {
      expect(CapsuleDateUtils.isLeapYear(2024), isTrue);
      expect(CapsuleDateUtils.isLeapYear(2025), isFalse);
      expect(CapsuleDateUtils.isLeapYear(2000), isTrue);
      expect(CapsuleDateUtils.isLeapYear(1900), isFalse);
    });

    test('addCalendarYears handles Feb 29 leap-year edge cases safely', () {
      final leapDate = DateTime(2024, 2, 29, 12, 0, 0);
      final oneYearLater = CapsuleDateUtils.addCalendarYears(leapDate, 1);

      // 2025 is not a leap year, so it must clamp to Feb 28, 2025!
      expect(oneYearLater.year, equals(2025));
      expect(oneYearLater.month, equals(2));
      expect(oneYearLater.day, equals(28));
    });

    test('addCalendarMonths handles month day-clamping safely', () {
      // Jan 31 + 1 month in non-leap year (2025) -> Feb 28
      final jan31 = DateTime(2025, 1, 31, 10, 0);
      final nextMonth = CapsuleDateUtils.addCalendarMonths(jan31, 1);

      expect(nextMonth.year, equals(2025));
      expect(nextMonth.month, equals(2));
      expect(nextMonth.day, equals(28));

      // Aug 31 + 1 month -> Sep 30
      final aug31 = DateTime(2025, 8, 31);
      final sepResult = CapsuleDateUtils.addCalendarMonths(aug31, 1);
      expect(sepResult.month, equals(9));
      expect(sepResult.day, equals(30));
    });

    test('getHeroCountdown returns accurate count and label unit', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0, 0);

      // 184 days away
      final unlockDate = DateTime.utc(2027, 3, 12, 12, 0, 0);
      final countdown = CapsuleDateUtils.getHeroCountdown(unlockDate, now);
      expect(countdown.count, equals(184));
      expect(countdown.unit, equals('DAYS'));

      // 5 hours away
      final fiveHours = now.add(const Duration(hours: 5, minutes: 10));
      final countdownHours = CapsuleDateUtils.getHeroCountdown(fiveHours, now);
      expect(countdownHours.count, equals(5));
      expect(countdownHours.unit, equals('HOURS'));

      // Past date
      final pastDate = now.subtract(const Duration(days: 1));
      final countdownPast = CapsuleDateUtils.getHeroCountdown(pastDate, now);
      expect(countdownPast.count, equals(0));
    });

    test('formatRelativeOrigin formats archival dates with emotional microcopy', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0, 0);

      final oneYearAgo = DateTime.utc(2025, 9, 9, 12, 0, 0);
      expect(CapsuleDateUtils.formatRelativeOrigin(oneYearAgo, now), equals('One year ago…'));

      final twoYearsAgo = DateTime.utc(2024, 9, 9, 12, 0, 0);
      expect(CapsuleDateUtils.formatRelativeOrigin(twoYearsAgo, now), equals('2 years ago…'));

      final today = DateTime.utc(2026, 9, 9, 8, 0, 0);
      expect(CapsuleDateUtils.formatRelativeOrigin(today, now), equals('Earlier today…'));
    });

    test('isOnThisDay verifies month and day match for earlier years', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0, 0);

      final createdLastYear = DateTime.utc(2025, 9, 9, 10, 0, 0);
      expect(CapsuleDateUtils.isOnThisDay(createdLastYear, now), isTrue);

      final createdToday = DateTime.utc(2026, 9, 9, 10, 0, 0);
      expect(CapsuleDateUtils.isOnThisDay(createdToday, now), isFalse); // Same year is not earlier year

      final differentDay = DateTime.utc(2025, 9, 10, 10, 0, 0);
      expect(CapsuleDateUtils.isOnThisDay(differentDay, now), isFalse);
    });
  });
}
