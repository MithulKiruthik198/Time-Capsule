import 'package:intl/intl.dart';

/// Robust date, timezone, and calendar calculations for Time Capsule.
class CapsuleDateUtils {
  CapsuleDateUtils._();

  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static int daysInMonth(int year, int month) {
    switch (month) {
      case 2:
        return isLeapYear(year) ? 29 : 28;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      default:
        return 31;
    }
  }

  /// Safely adds calendar months, clamping day if target month has fewer days.
  /// Example: Jan 31 + 1 month -> Feb 28 (or Feb 29 in leap year).
  static DateTime addCalendarMonths(DateTime from, int months) {
    int totalMonths = (from.year * 12) + (from.month - 1) + months;
    int targetYear = totalMonths ~/ 12;
    int targetMonth = (totalMonths % 12) + 1;
    int maxDays = daysInMonth(targetYear, targetMonth);
    int targetDay = from.day > maxDays ? maxDays : from.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
    );
  }

  /// Safely adds calendar years.
  /// Handles Feb 29 correctly (e.g. Feb 29, 2024 + 1 year -> Feb 28, 2025).
  static DateTime addCalendarYears(DateTime from, int years) {
    int targetYear = from.year + years;
    int maxDays = daysInMonth(targetYear, from.month);
    int targetDay = from.day > maxDays ? maxDays : from.day;

    return DateTime(
      targetYear,
      from.month,
      targetDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
    );
  }

  /// Generates quick preset date from current local time.
  static DateTime getPresetTomorrow([DateTime? now]) {
    final base = now ?? DateTime.now();
    return base.add(const Duration(days: 1));
  }

  static DateTime getPresetOneMonth([DateTime? now]) {
    final base = now ?? DateTime.now();
    return addCalendarMonths(base, 1);
  }

  static DateTime getPresetSixMonths([DateTime? now]) {
    final base = now ?? DateTime.now();
    return addCalendarMonths(base, 6);
  }

  static DateTime getPresetOneYear([DateTime? now]) {
    final base = now ?? DateTime.now();
    return addCalendarYears(base, 1);
  }

  static DateTime getPresetFiveYears([DateTime? now]) {
    final base = now ?? DateTime.now();
    return addCalendarYears(base, 5);
  }

  /// Test preset (30 seconds from now) for rapid MVP verification
  static DateTime getPresetQuickTest([DateTime? now]) {
    final base = now ?? DateTime.now();
    return base.add(const Duration(seconds: 30));
  }

  /// Formatted date in user local timezone: "September 9, 2027"
  static String formatFullDate(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    return DateFormat('MMMM d, y').format(local);
  }

  /// Formatted date with short month: "Sep 9, 2026"
  static String formatShortDate(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    return DateFormat('MMM d, y').format(local);
  }

  /// Formatted date and time: "Sep 9, 2026 at 4:30 PM"
  static String formatDateTime(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    return DateFormat('MMM d, y \'at\' h:mm a').format(local);
  }

  /// Countdown structured for the Hero Centerpiece:
  /// Returns a record with the major integer quantity and label unit.
  /// E.g. (count: 184, unit: 'DAYS')
  static ({int count, String unit}) getHeroCountdown(DateTime unlockAtUtc, [DateTime? nowUtc]) {
    final now = (nowUtc ?? DateTime.now().toUtc());
    final diff = unlockAtUtc.difference(now);

    if (diff.isNegative) {
      return (count: 0, unit: 'DAYS');
    }

    if (diff.inDays >= 1) {
      return (count: diff.inDays, unit: diff.inDays == 1 ? 'DAY' : 'DAYS');
    } else if (diff.inHours >= 1) {
      return (count: diff.inHours, unit: diff.inHours == 1 ? 'HOUR' : 'HOURS');
    } else if (diff.inMinutes >= 1) {
      return (count: diff.inMinutes, unit: diff.inMinutes == 1 ? 'MINUTE' : 'MINUTES');
    } else {
      return (count: diff.inSeconds > 0 ? diff.inSeconds : 0, unit: 'SECONDS');
    }
  }

  /// Countdown string: "183 days", "5 hours", "12 minutes", "Ready now"
  static String formatCountdown(DateTime unlockAtUtc, [DateTime? nowUtc]) {
    final now = (nowUtc ?? DateTime.now().toUtc());
    final diff = unlockAtUtc.difference(now);

    if (diff.isNegative || diff.inSeconds <= 0) {
      return 'Ready now';
    }

    if (diff.inDays > 365) {
      final years = diff.inDays ~/ 365;
      final remainingDays = diff.inDays % 365;
      if (remainingDays == 0) {
        return '$years ${years == 1 ? "year" : "years"}';
      }
      return '$years ${years == 1 ? "year" : "years"}, $remainingDays days';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"}';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"}';
    } else {
      return '${diff.inSeconds} seconds';
    }
  }

  /// Relative origin text for reveal experience:
  /// "One year ago…", "2 years ago…", "6 months ago…", "Yesterday…"
  static String formatRelativeOrigin(DateTime createdAtUtc, [DateTime? nowUtc]) {
    final now = (nowUtc ?? DateTime.now().toUtc()).toLocal();
    final created = createdAtUtc.toLocal();

    final diff = now.difference(created);
    final days = diff.inDays;

    if (days >= 365 * 2) {
      final years = days ~/ 365;
      return '$years years ago…';
    } else if (days >= 300) {
      return 'One year ago…';
    } else if (days >= 60) {
      final months = (days / 30.4).round();
      return '$months months ago…';
    } else if (days >= 25) {
      return 'One month ago…';
    } else if (days >= 2) {
      return '$days days ago…';
    } else if (days == 1) {
      return 'Yesterday…';
    } else {
      return 'Earlier today…';
    }
  }

  /// Formats exact elapsed duration for emotional reveal:
  /// "one year ago", "6 months ago", "3 weeks ago", "12 days ago", etc.
  static String formatElapsedDuration(DateTime fromUtc, [DateTime? toUtc]) {
    final to = (toUtc ?? DateTime.now().toUtc());
    final diff = to.difference(fromUtc);
    final days = diff.inDays;

    if (days >= 365 * 2) {
      final years = days ~/ 365;
      return '$years years ago';
    } else if (days >= 300) {
      return 'one year ago';
    } else if (days >= 60) {
      final months = (days / 30.4).round();
      return '$months months ago';
    } else if (days >= 25) {
      return 'one month ago';
    } else if (days >= 14) {
      final weeks = days ~/ 7;
      return '$weeks weeks ago';
    } else if (days >= 2) {
      return '$days days ago';
    } else if (days == 1) {
      return 'yesterday';
    } else {
      return 'earlier today';
    }
  }

  /// Checks if memory corresponds to "On This Day" (same month & day, earlier year)
  static bool isOnThisDay(DateTime createdAtUtc, [DateTime? nowUtc]) {
    final now = (nowUtc ?? DateTime.now().toUtc()).toLocal();
    final created = createdAtUtc.toLocal();

    return created.month == now.month &&
        created.day == now.day &&
        created.year < now.year;
  }
}
