import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';
import 'memory_repository.dart';

/// Cloud Supabase implementation of MemoryRepository using RLS
class SupabaseMemoryRepository implements MemoryRepository {
  final SupabaseClient client;
  final StreamController<List<Memory>> _controller = StreamController<List<Memory>>.broadcast();
  StreamSubscription? _subscription;

  SupabaseMemoryRepository({required this.client}) {
    _initStream();
  }

  void _initStream() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = client
        .from('memories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final memories = data
                .where((map) => map['deleted_at'] == null)
                .map((map) => Memory.fromJson(map))
                .toList();
            _controller.add(memories);
          },
          onError: (error) {
            _controller.addError(error);
          },
        );
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final response = await client
        .from('memories')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Memory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Memory?> getMemoryById(String id) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final response = await client
        .from('memories')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromJson(response);
  }

  @override
  Future<Memory> createMemory({
    String? title,
    required String content,
    required DateTime unlockAtUtc,
    String? imageUrl,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User is not authenticated');

    final nowUtc = DateTime.now().toUtc();
    final status = unlockAtUtc.isAfter(nowUtc) ? 'locked' : 'ready';

    final insertData = {
      'user_id': userId,
      'title': title?.trim().isEmpty == true ? null : title?.trim(),
      'content': content.trim(),
      'image_url': imageUrl,
      'created_at': nowUtc.toIso8601String(),
      'unlock_at': unlockAtUtc.toIso8601String(),
      'status': status,
    };

    final response = await client
        .from('memories')
        .insert(insertData)
        .select()
        .single();

    return Memory.fromJson(response);
  }

  @override
  Future<Memory> markMemoryOpened(String id) async {
    final nowUtc = DateTime.now().toUtc();
    final response = await client
        .from('memories')
        .update({
          'status': 'opened',
          'opened_at': nowUtc.toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return Memory.fromJson(response);
  }

  @override
  Future<void> deleteMemory(String id) async {
    final nowUtc = DateTime.now().toUtc();
    await client.from('memories').update({
      'deleted_at': nowUtc.toIso8601String(),
    }).eq('id', id);
  }

  @override
  Stream<List<Memory>> watchMemories() {
    return _controller.stream;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
