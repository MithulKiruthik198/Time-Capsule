import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_strings.dart';
import 'core/services/notification_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_view.dart';
import 'features/main_navigation_shell.dart';
import 'features/memory/capsule_reveal_view.dart';
import 'features/onboarding/onboarding_view.dart';
import 'repositories/app_repository_manager.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF08090D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Core Services
  await SupabaseService().init();
  await SubscriptionService().init();
  await NotificationService().init(
    onNotificationOpened: (capsuleId) async {
      if (capsuleId != null) {
        final repo = AppRepositoryManager().capsuleRepository;
        final capsule = await repo.getCapsuleById(capsuleId) ?? await repo.getActiveCapsule();
        if (capsule != null) {
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => CapsuleRevealView(capsule: capsule),
            ),
          );
        }
      }
    },
  );

  runApp(const TimeCapsuleApp());
}

class TimeCapsuleApp extends StatefulWidget {
  const TimeCapsuleApp({super.key});

  @override
  State<TimeCapsuleApp> createState() => _TimeCapsuleAppState();
}

class _TimeCapsuleAppState extends State<TimeCapsuleApp> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_completed') ?? false;

    // Check auth status
    final supabase = SupabaseService();
    final isCloudAuthed = supabase.isInitialized && supabase.isAuthenticated;
    final hasLocalVaultAccess = prefs.getBool('local_vault_active') ?? true;

    setState(() {
      _onboardingCompleted = onboarded;
      _isAuthenticated = isCloudAuthed || hasLocalVaultAccess;
      _isLoading = false;
    });
  }

  void _onSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('local_vault_active', false);
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoading
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          : !_onboardingCompleted
              ? OnboardingView(
                  onComplete: () {
                    setState(() => _onboardingCompleted = true);
                  },
                )
              : !_isAuthenticated
                  ? AuthView(
                      onAuthenticated: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('local_vault_active', true);
                        setState(() => _isAuthenticated = true);
                      },
                    )
                  : MainNavigationShell(
                      onSignOut: _onSignOut,
                    ),
    );
  }
}
