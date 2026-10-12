import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_capsule/models/capsule.dart';
import 'package:time_capsule/repositories/local_capsule_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalCapsuleRepository Tests', () {
    test('Supports One Capsule -> Unlimited Daily Memories -> Future Unlock', () async {
      final repo = LocalCapsuleRepository(userId: 'traveler_42');

      final initialCapsule = await repo.getActiveCapsule();
      expect(initialCapsule, isNull);

      // 1. Create a 1-year Time Capsule
      final unlockAt = DateTime.now().toUtc().add(const Duration(days: 365));
      final capsule = await repo.createCapsule(
        title: 'Year of Reflection',
        unlockAtUtc: unlockAt,
      );

      expect(capsule.title, equals('Year of Reflection'));
      expect(capsule.userId, equals('traveler_42'));
      expect(capsule.status, equals(CapsuleStatus.locked));
      expect(capsule.isLocked, isTrue);

      // 2. Add multiple memories on Day 1 (No "one upload per capsule" limit!)
      final day1 = DateTime.utc(2026, 9, 9, 8, 0, 0);
      final mem1 = await repo.addMemory(
        capsuleId: capsule.id,
        title: 'Morning reflection',
        content: 'Starting this journey today.',
        capturedAtUtc: day1,
      );

      final day1Later = DateTime.utc(2026, 9, 9, 11, 30, 0);
      final mem2 = await repo.addMemory(
        capsuleId: capsule.id,
        title: 'Lunch walk',
        content: 'Saw a beautiful garden.',
        imageUrl: 'garden.jpg',
        isImportant: true,
        capturedAtUtc: day1Later,
      );

      // 3. Add memory on Day 2
      final day2 = DateTime.utc(2026, 9, 12, 11, 0, 0);
      final mem3 = await repo.addMemory(
        capsuleId: capsule.id,
        title: 'Work breakthrough',
        content: 'Finally solved the architecture problem.',
        capturedAtUtc: day2,
      );

      // Verify all 3 memories exist in the capsule
      final allMemories = await repo.getMemoriesForCapsule(capsule.id);
      expect(allMemories.length, equals(3));
      expect(allMemories.any((m) => m.id == mem1.id), isTrue);
      expect(allMemories.any((m) => m.id == mem2.id), isTrue);
      expect(allMemories.any((m) => m.id == mem3.id), isTrue);

      // 4. Verify Timeline grouping into DayGroups
      final timeline = await repo.getTimelineForCapsule(capsule.id);
      expect(timeline.length, equals(2)); // Day 1 (2 memories) and Day 2 (1 memory)

      // Day 1 group has 2 memories and marked hasImportant = true
      final day1Group = timeline.firstWhere((g) => g.memories.any((m) => m.id == mem1.id));
      expect(day1Group.count, equals(2));
      expect(day1Group.hasImportant, isTrue);

      // 5. Mark capsule opened
      final opened = await repo.markCapsuleOpened(capsule.id);
      expect(opened.status, equals(CapsuleStatus.opened));
      expect(opened.isOpened, isTrue);
      expect(opened.openedAt, isNotNull);

      // 6. Verify getCapsuleById
      final fetched = await repo.getCapsuleById(capsule.id);
      expect(fetched?.id, equals(capsule.id));
      expect(fetched?.isOpened, isTrue);

      repo.dispose();
    });
  });
}

