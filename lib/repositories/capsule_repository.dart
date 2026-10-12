import '../models/capsule.dart';
import '../models/day_group.dart';
import '../models/memory.dart';

abstract class CapsuleRepository {
  Future<Capsule?> getActiveCapsule();
  Future<Capsule?> getCapsuleById(String capsuleId);
  Future<List<Capsule>> getAllCapsules();
  Future<Capsule> createCapsule({
    required String title,
    required DateTime unlockAtUtc,
  });
  Future<Memory> addMemory({
    required String capsuleId,
    String? title,
    required String content,
    String? imageUrl,
    String memoryType = 'note',
    bool isImportant = false,
    DateTime? capturedAtUtc,
  });
  Future<List<Memory>> getMemoriesForCapsule(String capsuleId);
  Future<List<DayGroup>> getTimelineForCapsule(String capsuleId);
  Future<Capsule> markCapsuleOpened(String capsuleId);
  Future<void> deleteMemory(String memoryId);
  Future<void> deleteCapsule(String capsuleId);
  Stream<Capsule?> watchActiveCapsule();
  Stream<List<Memory>> watchCapsuleMemories(String capsuleId);
  void dispose();
}
