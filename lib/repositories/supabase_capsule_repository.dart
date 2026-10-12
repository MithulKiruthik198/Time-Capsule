import 'dart:async';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/capsule.dart';
import '../models/day_group.dart';
import '../models/memory.dart';
import 'capsule_repository.dart';

/// Cloud Supabase implementation of CapsuleRepository using Row Level Security
class SupabaseCapsuleRepository implements CapsuleRepository {
  final SupabaseClient client;
  final StreamController<Capsule?> _activeCapsuleController = StreamController<Capsule?>.broadcast();
  final Map<String, StreamController<List<Memory>>> _memoriesControllers = {};
  StreamSubscription? _capsulesSubscription;

  SupabaseCapsuleRepository({required this.client}) {
    _initCapsulesStream();
  }

  void _initCapsulesStream() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _capsulesSubscription = client
        .from('capsules')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final capsules = data
                .where((map) => map['deleted_at'] == null)
                .map((map) => Capsule.fromJson(map))
                .toList();
            _activeCapsuleController.add(capsules.isNotEmpty ? capsules.first : null);
          },
          onError: (error) {
            _activeCapsuleController.addError(error);
          },
        );
  }

  @override
  Future<Capsule?> getActiveCapsule() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final response = await client
        .from('capsules')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Capsule.fromJson(response);
  }

  @override
  Future<Capsule?> getCapsuleById(String capsuleId) async {
    final response = await client
        .from('capsules')
        .select()
        .eq('id', capsuleId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return Capsule.fromJson(response);
  }

  @override
  Future<List<Capsule>> getAllCapsules() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final response = await client
        .from('capsules')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Capsule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Capsule> createCapsule({
    required String title,
    required DateTime unlockAtUtc,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final nowUtc = DateTime.now().toUtc();
    final status = unlockAtUtc.isAfter(nowUtc) ? 'locked' : 'ready';

    final insertData = {
      'user_id': userId,
      'title': title.trim().isEmpty ? 'My Future Self' : title.trim(),
      'created_at': nowUtc.toIso8601String(),
      'unlock_at': unlockAtUtc.toIso8601String(),
      'status': status,
    };

    final response = await client.from('capsules').insert(insertData).select().single();
    return Capsule.fromJson(response);
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
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final nowUtc = DateTime.now().toUtc();

    final insertData = {
      'capsule_id': capsuleId,
      'user_id': userId,
      'title': title?.trim().isEmpty == true ? null : title?.trim(),
      'content': content.trim(),
      'image_url': imageUrl,
      'memory_type': memoryType,
      'is_important': isImportant,
      'captured_at': (capturedAtUtc ?? nowUtc).toIso8601String(),
      'created_at': nowUtc.toIso8601String(),
    };

    final response = await client.from('memories').insert(insertData).select().single();
    return Memory.fromJson(response);
  }

  @override
  Future<List<Memory>> getMemoriesForCapsule(String capsuleId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final response = await client
        .from('memories')
        .select()
        .eq('capsule_id', capsuleId)
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('captured_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Memory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DayGroup>> getTimelineForCapsule(String capsuleId) async {
    final memories = await getMemoriesForCapsule(capsuleId);

    final Map<String, List<Memory>> groups = {};
    for (final m in memories) {
      groups.putIfAbsent(m.dayKey, () => []).add(m);
    }

    final List<DayGroup> dayGroups = [];
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final key in sortedKeys) {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(key);
      final mems = groups[key]!;
      mems.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      dayGroups.add(DayGroup(date: parsedDate, memories: mems));
    }

    return dayGroups;
  }

  @override
  Future<Capsule> markCapsuleOpened(String capsuleId) async {
    final nowUtc = DateTime.now().toUtc();
    final response = await client
        .from('capsules')
        .update({
          'status': 'opened',
          'opened_at': nowUtc.toIso8601String(),
        })
        .eq('id', capsuleId)
        .select()
        .single();

    return Capsule.fromJson(response);
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    final nowUtc = DateTime.now().toUtc();
    await client.from('memories').update({
      'deleted_at': nowUtc.toIso8601String(),
    }).eq('id', memoryId);
  }

  @override
  Future<void> deleteCapsule(String capsuleId) async {
    final nowUtc = DateTime.now().toUtc();
    await client.from('capsules').update({
      'deleted_at': nowUtc.toIso8601String(),
    }).eq('id', capsuleId);
  }

  @override
  Stream<Capsule?> watchActiveCapsule() {
    return _activeCapsuleController.stream;
  }

  @override
  Stream<List<Memory>> watchCapsuleMemories(String capsuleId) {
    if (!_memoriesControllers.containsKey(capsuleId)) {
      final controller = StreamController<List<Memory>>.broadcast();
      _memoriesControllers[capsuleId] = controller;

      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        client
            .from('memories')
            .stream(primaryKey: ['id'])
            .eq('capsule_id', capsuleId)
            .order('captured_at', ascending: false)
            .listen((data) {
              final list = data
                  .where((map) => map['deleted_at'] == null)
                  .map((map) => Memory.fromJson(map))
                  .toList();
              controller.add(list);
            });
      }
    }
    return _memoriesControllers[capsuleId]!.stream;
  }

  @override
  void dispose() {
    _capsulesSubscription?.cancel();
    _activeCapsuleController.close();
    for (final controller in _memoriesControllers.values) {
      controller.close();
    }
    _memoriesControllers.clear();
  }
}
