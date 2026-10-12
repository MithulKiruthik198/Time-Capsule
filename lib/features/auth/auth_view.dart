import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';

class AuthView extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthView({super.key, required this.onAuthenticated});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final supabase = SupabaseService();

    if (!supabase.isInitialized) {
      // If Supabase is not connected yet, authenticate to Local Vault
      AppRepositoryManager().forceLocalVault();
      AnalyticsService().accountCreated();
      setState(() => _isLoading = false);
      widget.onAuthenticated();
      return;
    }

    try {
      if (_isSignUp) {
        final res = await supabase.signUp(email: email, password: password);
        if (res?.user != null) {
          AnalyticsService().accountCreated();
          AppRepositoryManager().refreshRepository();
          widget.onAuthenticated();
        } else {
          setState(() => _errorMessage = 'Sign up submitted. Please verify your email.');
        }
      } else {
        final res = await supabase.signIn(email: email, password: password);
        if (res?.user != null) {
          AppRepositoryManager().refreshRepository();
          widget.onAuthenticated();
        } else {
          setState(() => _errorMessage = AppStrings.errorAuth);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = '$e'.replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueWithLocalVault() {
    AppRepositoryManager().forceLocalVault();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final isSupabaseReady = SupabaseService().isInitialized;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand glyph
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.surfaceBorderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 36,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  AppStrings.appName,
                  style: AppTypography.displayLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '“${AppStrings.conceptStatement}”',
                  style: AppTypography.emotionalHeadline.copyWith(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 38),

                // Inputs
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                GlowingButton(
                  label: _isSignUp ? 'Create Time Vault' : 'Enter Time Machine',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                // Switch between sign in / sign up
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'Don\'t have an account? Create one',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.accent),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Offline / Local Vault option
                GlowingButton(
                  label: 'Use Local Vault (Offline & Private)',
                  icon: Icons.shield_outlined,
                  isSecondary: true,
                  onPressed: _continueWithLocalVault,
                ),

                if (!isSupabaseReady) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Local Vault stores memories securely on-device.\nYou can connect Supabase anytime in Settings.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
