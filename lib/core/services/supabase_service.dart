import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service managing Supabase connectivity and authentication.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _prefUrlKey = 'supabase_url';
  static const String _prefAnonKey = 'supabase_anon_key';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;
  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Default public test instance or blank to allow Local Vault fallback
  static String? _configuredUrl;
  static String? _configuredAnonKey;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _configuredUrl = prefs.getString(_prefUrlKey);
      _configuredAnonKey = prefs.getString(_prefAnonKey);

      if (_configuredUrl != null &&
          _configuredUrl!.isNotEmpty &&
          _configuredAnonKey != null &&
          _configuredAnonKey!.isNotEmpty) {
        await Supabase.initialize(
          url: _configuredUrl!,
          publishableKey: _configuredAnonKey!,
          debug: kDebugMode,
        );
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Initialization skipped or failed: $e');
      _isInitialized = false;
    }
  }

  Future<bool> configureCredentials(String url, String anonKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUrlKey, url.trim());
      await prefs.setString(_prefAnonKey, anonKey.trim());
      _configuredUrl = url.trim();
      _configuredAnonKey = anonKey.trim();

      await Supabase.initialize(
        url: _configuredUrl!,
        publishableKey: _configuredAnonKey!,
        debug: kDebugMode,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Failed to configure: $e');
      return false;
    }
  }

  Future<AuthResponse?> signUp({required String email, required String password}) async {
    if (!isInitialized || client == null) return null;
    return await client!.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse?> signIn({required String email, required String password}) async {
    if (!isInitialized || client == null) return null;
    return await client!.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    if (isInitialized && client != null) {
      await client!.auth.signOut();
    }
  }

  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;
}
