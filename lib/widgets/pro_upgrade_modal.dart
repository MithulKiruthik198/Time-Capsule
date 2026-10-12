import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_strings.dart';
import '../core/services/subscription_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'glass_card.dart';
import 'glowing_button.dart';

/// Modal bottom sheet presenting the YESTERA PRO luxury upgrade.
/// Allows instant testing/upgrading between Free and Pro tiers.
class ProUpgradeModal extends StatefulWidget {
  final String? reasonMessage;

  const ProUpgradeModal({super.key, this.reasonMessage});

  static Future<bool?> show(BuildContext context, {String? reasonMessage}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProUpgradeModal(reasonMessage: reasonMessage),
    );
  }

  @override
  State<ProUpgradeModal> createState() => _ProUpgradeModalState();
}

class _ProUpgradeModalState extends State<ProUpgradeModal> {
  final SubscriptionService _sub = SubscriptionService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isPro = _sub.isPro;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header with Crown & Pro Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.brightAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppStrings.proModalTitle,
                            style: AppTypography.h3.copyWith(
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brightAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPro ? 'ACTIVE' : 'LOCKED',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.proModalSubtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                ),
              ],
            ),

            if (widget.reasonMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.brightAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.reasonMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Feature Comparison Cards
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.surfaceBorderLight,
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.hourglass_full_rounded,
                    title: 'Unlimited Time Capsules',
                    freeText: '1 active capsule',
                    proText: 'Unlimited',
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  _buildFeatureRow(
                    icon: Icons.photo_library_rounded,
                    title: 'Daily Media Memories',
                    freeText: '2 photos / day',
                    proText: 'Unlimited',
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  _buildFeatureRow(
                    icon: Icons.mic_none_rounded,
                    title: 'Audio Voice Transmissions',
                    freeText: 'Locked',
                    proText: 'Included',
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  _buildFeatureRow(
                    icon: Icons.videocam_outlined,
                    title: 'Video Memories',
                    freeText: 'Locked',
                    proText: 'Included',
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  _buildFeatureRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Cinematic Reel & Archival Album',
                    freeText: 'Locked',
                    proText: 'Included',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Button (Upgrade / Toggle)
            GlowingButton(
              label: isPro ? 'KEEP YESTERA PRO (ACTIVE)' : 'UPGRADE TO YESTERA PRO',
              icon: isPro ? Icons.check_circle_outline_rounded : Icons.lock_open_rounded,
              isLoading: _isLoading,
              color: isPro ? const Color(0xFF2E7D32) : AppColors.accent,
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isLoading = true);
                HapticFeedback.mediumImpact();
                await _sub.setPro(!isPro);
                if (mounted) {
                  setState(() => _isLoading = false);
                  navigator.pop(true);
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text(
                        !isPro
                            ? '✨ Welcome to YESTERA PRO! Unlimited vault unlocked.'
                            : 'Reverted to Free Tier.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.brightAccent),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Cancel anytime. Your sealed memories remain forever safe.',
                style: AppTypography.timestamp.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String freeText,
    required String proText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brightAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              proText,
              style: AppTypography.caption.copyWith(
                color: AppColors.brightAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              freeText,
              style: AppTypography.timestamp.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
