import 'package:intl/intl.dart';
import 'memory.dart';

/// Represents a single day in the user's capsule journey.
/// May contain 0 memories ("A quiet day"), 1 memory, or multiple memories.
class DayGroup {
  final DateTime date; // Local date
  final List<Memory> memories;

  const DayGroup({
    required this.date,
    required this.memories,
  });

  bool get isQuietDay => memories.isEmpty;
  int get count => memories.length;
  bool get hasImportant => memories.any((m) => m.isImportant);

  String get formattedDate => DateFormat('MMMM d, y').format(date);
  String get shortDate => DateFormat('MMM d').format(date);
  String get dayOfWeek => DateFormat('EEEE').format(date);
  String get year => date.year.toString();

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
