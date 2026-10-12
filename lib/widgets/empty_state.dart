import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'glowing_button.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onCaptureTap;

  const EmptyState({
    super.key,
    required this.onCaptureTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtle icon portal
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Center(
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              AppStrings.emptyVaultTitle,
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              '“${AppStrings.emptyVaultSubtitle}”',
              style: AppTypography.emotionalHeadline.copyWith(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            GlowingButton(
              label: AppStrings.emptyVaultCta,
              icon: Icons.add_circle_outline_rounded,
              onPressed: onCaptureTap,
            ),
            const SizedBox(height: 14),

            Text(
              AppStrings.emptyVaultNote,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
