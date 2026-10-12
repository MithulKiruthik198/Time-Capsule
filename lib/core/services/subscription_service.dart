import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription Service for YESTERA PRO
///
/// Free Tier:
/// - 1 Active Time Capsule
/// - 2 Media (Photos) captured per calendar day
/// - Unlimited text notes
///
/// Pro Tier (YESTERA PRO):
/// - Unlimited Time Capsules
/// - Unlimited daily media (photos & memories)
/// - Audio Voice transmissions
/// - Video moments
/// - In-App Cinematic Documentary Reel & Archival Keepsake Album
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String _keyIsPro = 'yestera_is_pro_tier';
  static const String _keyDailyMediaPrefix = 'yestera_media_count_';
  static const int freeDailyMediaLimit = 2;
  static const int freeCapsuleLimit = 1;

  bool _isPro = false;
  bool _isInitialized = false;

  bool get isPro => _isPro;
  bool get isInitialized => _isInitialized;

  /// Initialize and load cached subscription state
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool(_keyIsPro) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SubscriptionService] Init error: $e');
    }
  }

  /// Upgrade / Downgrade Pro status (supports sandbox / toggle)
  Future<void> setPro(bool value) async {
    _isPro = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsPro, value);
    } catch (e) {
      debugPrint('[SubscriptionService] setPro error: $e');
    }
  }

  /// Helper to toggle Pro status for demo/testing
  Future<void> togglePro() async {
    await setPro(!_isPro);
  }

  /// Check whether user can create another capsule
  bool canCreateCapsule(int currentActiveCapsuleCount) {
    if (_isPro) return true;
    return currentActiveCapsuleCount < freeCapsuleLimit;
  }

  /// Check whether user can add media today (Photo)
  Future<bool> canAddMediaToday({DateTime? date}) async {
    if (_isPro) return true;
    final count = await getMediaCountToday(date: date);
    return count < freeDailyMediaLimit;
  }

  /// Get remaining free media quota today
  Future<int> getRemainingFreeMediaToday({DateTime? date}) async {
    if (_isPro) return 999;
    final count = await getMediaCountToday(date: date);
    final remaining = freeDailyMediaLimit - count;
    return remaining < 0 ? 0 : remaining;
  }

  /// Get how many media moments were saved today
  Future<int> getMediaCountToday({DateTime? date}) async {
    final key = _dayKey(date ?? DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting media count: $e');
      return 0;
    }
  }

  /// Record a media upload for today
  Future<void> recordMediaAddedToday({DateTime? date}) async {
    final key = _dayKey(date ?? DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + 1);
      notifyListeners();
    } catch (e) {
      debugPrint('[SubscriptionService] Error recording media: $e');
    }
  }

  bool get canUseVideo => _isPro;
  bool get canUseAudio => _isPro;
  bool get canUseCinematicReel => _isPro;

  String _dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$_keyDailyMediaPrefix${y}_${m}_$d';
  }
}
