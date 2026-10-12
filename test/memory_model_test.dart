import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/memory.dart';

void main() {
  group('Memory Model Tests', () {
    test('Correctly serializes to and from JSON', () {
      final nowUtc = DateTime.utc(2026, 9, 9, 12, 0, 0);

      final memory = Memory(
        id: 'test-uuid-1',
        capsuleId: 'capsule-uuid-1',
        userId: 'user-uuid-1',
        title: 'Letter to Future Me',
        content: 'I hope we achieved our goals.',
        imageUrl: 'https://example.com/photo.jpg',
        memoryType: 'photo',
        isImportant: true,
        capturedAt: nowUtc,
        createdAt: nowUtc,
      );

      final json = memory.toJson();
      expect(json['id'], equals('test-uuid-1'));
      expect(json['capsule_id'], equals('capsule-uuid-1'));
      expect(json['title'], equals('Letter to Future Me'));
      expect(json['is_important'], isTrue);
      expect(json['memory_type'], equals('photo'));

      final fromJson = Memory.fromJson(json);
      expect(fromJson.id, equals(memory.id));
      expect(fromJson.capsuleId, equals(memory.capsuleId));
      expect(fromJson.userId, equals(memory.userId));
      expect(fromJson.title, equals(memory.title));
      expect(fromJson.content, equals(memory.content));
      expect(fromJson.imageUrl, equals(memory.imageUrl));
      expect(fromJson.isImportant, isTrue);
      expect(fromJson.hasPhoto, isTrue);
      expect(fromJson.dayKey, equals('2026-09-09'));
    });

    test('Helper getters format day, time, and photo detection correctly', () {
      final captured = DateTime.utc(2026, 9, 9, 16, 30, 0);

      final memory = Memory(
        id: 'm1',
        capsuleId: 'c1',
        userId: 'u1',
        content: 'Coffee with friends.',
        imageUrl: null,
        isImportant: false,
        capturedAt: captured,
        createdAt: captured,
      );

      expect(memory.hasPhoto, isFalse);
      expect(memory.formattedDay, contains('2026'));
      expect(memory.formattedTime, isNotEmpty);
      expect(memory.dayKey, isNotEmpty);
    });
  });
}

