import 'package:flutter/foundation.dart';
import '../core/services/supabase_service.dart';
import 'capsule_repository.dart';
import 'local_capsule_repository.dart';
import 'supabase_capsule_repository.dart';

/// Manages repository state, seamlessly switching between Cloud Supabase and Local Vault
class AppRepositoryManager extends ChangeNotifier {
  static final AppRepositoryManager _instance = AppRepositoryManager._internal();
  factory AppRepositoryManager() => _instance;
  AppRepositoryManager._internal();

  CapsuleRepository? _capsuleRepository;
  bool _isUsingSupabase = false;

  CapsuleRepository get capsuleRepository {
    if (_capsuleRepository == null) {
      _initDefault();
    }
    return _capsuleRepository!;
  }

  // Alias for backward compatibility
  CapsuleRepository get repository => capsuleRepository;

  bool get isUsingSupabase => _isUsingSupabase;

  void _initDefault() {
    final supabase = SupabaseService();
    if (supabase.isInitialized && supabase.isAuthenticated && supabase.client != null) {
      _capsuleRepository = SupabaseCapsuleRepository(client: supabase.client!);
      _isUsingSupabase = true;
    } else {
      _capsuleRepository = LocalCapsuleRepository();
      _isUsingSupabase = false;
    }
  }

  void refreshRepository() {
    _capsuleRepository?.dispose();
    _capsuleRepository = null;
    _initDefault();
    notifyListeners();
  }

  void forceLocalVault() {
    _capsuleRepository?.dispose();
    _capsuleRepository = LocalCapsuleRepository();
    _isUsingSupabase = false;
    notifyListeners();
  }
}
