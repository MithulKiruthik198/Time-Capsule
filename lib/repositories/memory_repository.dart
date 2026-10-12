import '../models/memory.dart';

abstract class MemoryRepository {
  Future<List<Memory>> getAllMemories();
  Future<Memory?> getMemoryById(String id);
  Future<Memory> createMemory({
    String? title,
    required String content,
    required DateTime unlockAtUtc,
    String? imageUrl,
  });
  Future<Memory> markMemoryOpened(String id);
  Future<void> deleteMemory(String id);
  Stream<List<Memory>> watchMemories();
  void dispose();
}
