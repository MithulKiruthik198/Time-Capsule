import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/capsule.dart';
import '../models/day_group.dart';
import '../models/memory.dart';
import 'capsule_repository.dart';

/// Local offline vault repository storing capsules and unlimited daily memories on-device.
class LocalCapsuleRepository implements CapsuleRepository {
  static const String _capsulesKey = 'time_capsule_local_capsules_v2';
  static const String _memoriesKey = 'time_capsule_local_memories_v2';

  final StreamController<Capsule?> _activeCapsuleController = StreamController<Capsule?>.broadcast();
  final Map<String, StreamController<List<Memory>>> _memoriesControllers = {};

  List<Capsule> _capsulesCache = [];
  List<Memory> _memoriesCache = [];
  bool _isLoaded = false;
  final String localUserId;

  LocalCapsuleRepository({String? userId}) : localUserId = userId ?? 'local_time_traveler';

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Capsules
    final rawCapsules = prefs.getString(_capsulesKey);
    if (rawCapsules != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawCapsules);
        _capsulesCache = decoded
            .map((item) => Capsule.fromJson(item as Map<String, dynamic>))
            .where((c) => c.deletedAt == null)
            .toList();
      } catch (_) {
        _capsulesCache = [];
      }
    } else {
      _capsulesCache = [];
    }

    // 2. Load Memories
    final rawMemories = prefs.getString(_memoriesKey);
    if (rawMemories != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawMemories);
        _memoriesCache = decoded
            .map((item) => Memory.fromJson(item as Map<String, dynamic>))
            .where((m) => m.deletedAt == null)
            .toList();
      } catch (_) {
        _memoriesCache = [];
      }
    } else {
      _memoriesCache = [];
    }

    _isLoaded = true;
    _emitActiveCapsule();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _capsulesKey,
      jsonEncode(_capsulesCache.map((c) => c.toJson()).toList()),
    );
    await prefs.setString(
      _memoriesKey,
      jsonEncode(_memoriesCache.map((m) => m.toJson()).toList()),
    );
    _emitActiveCapsule();
    for (final capsule in _capsulesCache) {
      _emitMemories(capsule.id);
    }
  }

  void _emitActiveCapsule() {
    final active = _capsulesCache
        .where((c) => c.deletedAt == null)
        .toList();
    active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _activeCapsuleController.add(active.isNotEmpty ? active.first : null);
  }

  void _emitMemories(String capsuleId) {
    if (_memoriesControllers.containsKey(capsuleId)) {
      final list = _memoriesCache
          .where((m) => m.capsuleId == capsuleId && m.deletedAt == null)
          .toList();
      list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      _memoriesControllers[capsuleId]!.add(List.unmodifiable(list));
    }
  }

  @override
  Future<Capsule?> getActiveCapsule() async {
    await _ensureLoaded();
    final list = _capsulesCache.where((c) => c.deletedAt == null).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }

  @override
  Future<Capsule?> getCapsuleById(String capsuleId) async {
    await _ensureLoaded();
    try {
      return _capsulesCache.firstWhere(
        (c) => c.id == capsuleId && c.deletedAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Capsule>> getAllCapsules() async {
    await _ensureLoaded();
    final list = _capsulesCache.where((c) => c.deletedAt == null).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<Capsule> createCapsule({
    required String title,
    required DateTime unlockAtUtc,
  }) async {
    await _ensureLoaded();
    final nowUtc = DateTime.now().toUtc();

    final capsule = Capsule(
      id: const Uuid().v4(),
      userId: localUserId,
      title: title.trim().isEmpty ? 'My Future Self' : title.trim(),
      createdAt: nowUtc,
      unlockAt: unlockAtUtc,
      status: unlockAtUtc.isAfter(nowUtc) ? CapsuleStatus.locked : CapsuleStatus.ready,
    );

    _capsulesCache.insert(0, capsule);
    await _persist();
    return capsule;
  }

  @override
  Future<Memory> addMemory({
    required String capsuleId,
    String? title,
    required String content,
    String? imageUrl,
    String memoryType = 'note',
    bool isImportant = false,
    DateTime? capturedAtUtc,
  }) async {
    await _ensureLoaded();
    final nowUtc = DateTime.now().toUtc();

    final memory = Memory(
      id: const Uuid().v4(),
      capsuleId: capsuleId,
      userId: localUserId,
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      content: content.trim(),
      imageUrl: imageUrl,
      memoryType: memoryType,
      isImportant: isImportant,
      capturedAt: capturedAtUtc ?? nowUtc,
      createdAt: nowUtc,
    );

    _memoriesCache.insert(0, memory);
    await _persist();
    return memory;
  }

  @override
  Future<List<Memory>> getMemoriesForCapsule(String capsuleId) async {
    await _ensureLoaded();
    final list = _memoriesCache
        .where((m) => m.capsuleId == capsuleId && m.deletedAt == null)
        .toList();
    list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return List.unmodifiable(list);
  }

  @override
  Future<List<DayGroup>> getTimelineForCapsule(String capsuleId) async {
    await _ensureLoaded();
    final memories = await getMemoriesForCapsule(capsuleId);

    // Group memories by dayKey (yyyy-MM-dd)
    final Map<String, List<Memory>> groups = {};
    for (final m in memories) {
      groups.putIfAbsent(m.dayKey, () => []).add(m);
    }

    // Convert map to DayGroup list
    final List<DayGroup> dayGroups = [];
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final key in sortedKeys) {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(key);
      final mems = groups[key]!;
      // Sort individual memories within the day chronologically
      mems.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      dayGroups.add(DayGroup(date: parsedDate, memories: mems));
    }

    return dayGroups;
  }

  @override
  Future<Capsule> markCapsuleOpened(String capsuleId) async {
    await _ensureLoaded();
    final index = _capsulesCache.indexWhere((c) => c.id == capsuleId);
    if (index == -1) throw Exception('Capsule not found');

    final updated = _capsulesCache[index].copyWith(
      status: CapsuleStatus.opened,
      openedAt: DateTime.now().toUtc(),
    );
    _capsulesCache[index] = updated;
    await _persist();
    return updated;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await _ensureLoaded();
    _memoriesCache.removeWhere((m) => m.id == memoryId);
    await _persist();
  }

  @override
  Future<void> deleteCapsule(String capsuleId) async {
    await _ensureLoaded();
    _capsulesCache.removeWhere((c) => c.id == capsuleId);
    _memoriesCache.removeWhere((m) => m.capsuleId == capsuleId);
    await _persist();
  }

  @override
  Stream<Capsule?> watchActiveCapsule() {
    _ensureLoaded().then((_) => _emitActiveCapsule());
    Timer.run(() => _emitActiveCapsule());
    return _activeCapsuleController.stream;
  }

  @override
  Stream<List<Memory>> watchCapsuleMemories(String capsuleId) {
    _ensureLoaded();
    if (!_memoriesControllers.containsKey(capsuleId)) {
      _memoriesControllers[capsuleId] = StreamController<List<Memory>>.broadcast();
    }
    Timer.run(() => _emitMemories(capsuleId));
    return _memoriesControllers[capsuleId]!.stream;
  }

  @override
  void dispose() {
    _activeCapsuleController.close();
    for (final controller in _memoriesControllers.values) {
      controller.close();
    }
    _memoriesControllers.clear();
  }
}
