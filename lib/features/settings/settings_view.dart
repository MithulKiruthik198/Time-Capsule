import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/pro_upgrade_modal.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onSignOut;

  const SettingsView({super.key, required this.onSignOut});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();

  void _showConfigureSupabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Connect Supabase', style: AppTypography.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your Supabase project URL and anon key to sync memories with your cloud database.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Project URL',
                  hintText: 'https://xyz.supabase.co',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _anonKeyController,
                obscureText: true,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Anon Public Key',
                  hintText: 'eyJhbGciOi...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.button),
          ),
          GlowingButton(
            label: 'Save & Connect',
            onPressed: () async {
              final url = _urlController.text.trim();
              final key = _anonKeyController.text.trim();
              if (url.isNotEmpty && key.isNotEmpty) {
                final success = await SupabaseService().configureCredentials(url, key);
                if (success) {
                  AppRepositoryManager().refreshRepository();
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService().requestPermissions();
    await NotificationService().showMemoryLockedNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sent test notification! Check your notification bar.'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = SupabaseService();
    final isCloudActive = supabase.isInitialized && supabase.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.displayLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // YESTERA PRO Membership Card
            GlassCard(
              borderColor: AppColors.accent,
              hasGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.brightAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppStrings.appName,
                                  style: AppTypography.titleLarge.copyWith(
                                    letterSpacing: 1.5,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    SubscriptionService().isPro ? 'PRO ACTIVE' : 'FREE TIER',
                                    style: AppTypography.badge.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              SubscriptionService().isPro
                                  ? 'Unlimited capsules, media & cinematic reels'
                                  : '1 active capsule • 2 photos/day limit',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlowingButton(
                    label: SubscriptionService().isPro
                        ? 'Manage Pro Benefits'
                        : 'Upgrade to Yestera Pro',
                    icon: Icons.star_rounded,
                    isSecondary: SubscriptionService().isPro,
                    onPressed: () async {
                      await ProUpgradeModal.show(context);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vault Storage Status
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCloudActive ? Icons.cloud_done_rounded : Icons.shield_rounded,
                        color: isCloudActive ? AppColors.opened : AppColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCloudActive ? 'Supabase Cloud Vault' : 'Local Private Vault',
                            style: AppTypography.titleLarge.copyWith(fontSize: 16),
                          ),
                          Text(
                            isCloudActive
                                ? 'Encrypted & synced with Row Level Security'
                                : 'Offline on-device encrypted storage',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlowingButton(
                    label: isCloudActive ? 'Connected to Cloud' : 'Connect Supabase Cloud',
                    isSecondary: isCloudActive,
                    icon: Icons.cloud_sync_rounded,
                    onPressed: _showConfigureSupabaseDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.accent, size: 22),
                      const SizedBox(width: 12),
                      Text('Time Machine Alerts', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Receive a signal when a moment in your timeline becomes ready to open.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  GlowingButton(
                    label: 'Send Test Alert',
                    icon: Icons.notifications_none_rounded,
                    isSecondary: true,
                    onPressed: _testNotification,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product Statement & Philosophy
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName.toUpperCase(),
                    style: AppTypography.heroSubtitle.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${AppStrings.tagline}”',
                    style: AppTypography.emotionalHeadline.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every life has moments worth preserving. Choose a future date, lock it in time, and meet yourself later.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign out
            GlowingButton(
              label: 'Sign Out / Switch Vault',
              icon: Icons.logout_rounded,
              isSecondary: true,
              onPressed: () async {
                await SupabaseService().signOut();
                widget.onSignOut();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
