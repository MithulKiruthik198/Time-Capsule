import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/day_group.dart';
import '../models/memory.dart';
import 'glass_card.dart';

/// Compact Mystery Shielding Timeline Tile:
/// - Enforces strict secrecy: zero photo and zero text leakage while sealed.
/// - Ultra-compact space-saving rows (minimizes vertical footprint).
/// - Tactile sealed transmission indicators with gold wax emblems.
class JourneyTimelineTile extends StatelessWidget {
  final DayGroup dayGroup;
  final bool isCapsuleLocked;
  final VoidCallback? onAddMoment;
  final void Function(Memory memory)? onMemoryTap;

  const JourneyTimelineTile({
    super.key,
    required this.dayGroup,
    required this.isCapsuleLocked,
    this.onAddMoment,
    this.onMemoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dayGroup.isQuietDay) {
      return _buildQuietDay(context);
    }

    return _buildActiveDay(context);
  }

  Widget _buildQuietDay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.locked,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            dayGroup.shortDate,
            style: AppTypography.timestamp.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.quietDayLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: dayGroup.hasImportant
            ? AppColors.brightAccent.withValues(alpha: 0.35)
            : AppColors.surfaceBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Day Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dayGroup.hasImportant ? AppColors.brightAccent : AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dayGroup.formattedDate.toUpperCase(),
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),

                // Moment count pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dayGroup.count} ${dayGroup.count == 1 ? "sealed" : "sealed"}',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.brightAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Compact Moment Rows
            if (isCapsuleLocked) ...[
              // Mystery Sealed Rows: ZERO image & ZERO note leaks!
              ...dayGroup.memories.map((m) => _buildCompactSealedRow(context, m)),
            ] else ...[
              // Unlocked: Compact Keepsake Rows (Takes minimal space, clean & elegant)
              ...dayGroup.memories.map((m) => _buildCompactOpenedRow(context, m)),
            ],

            // If today, offer quick "+ Add moment"
            if (dayGroup.isToday && onAddMoment != null && isCapsuleLocked) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onAddMoment,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 13, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Add another today',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Compact Mystery Sealed Row (Takes minimal height, zero leak)
  Widget _buildCompactSealedRow(BuildContext context, Memory memory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceElevated,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.accent, width: 1),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded, color: AppColors.brightAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.mysteryTooltip,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: memory.isImportant
                    ? AppColors.brightAccent.withValues(alpha: 0.3)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              children: [
                // Enigmatic Gold Wax Seal Node
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: memory.isImportant ? AppColors.brightAccent : AppColors.accent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      memory.isImportant ? Icons.star_rounded : Icons.lock_outline_rounded,
                      size: 13,
                      color: memory.isImportant ? AppColors.brightAccent : AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Shrouded Mystery Title
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        memory.isImportant
                            ? AppStrings.mysteryKeyMomentTitle
                            : AppStrings.mysteryMemoryTitle,
                        style: AppTypography.badge.copyWith(
                          color: memory.isImportant
                              ? AppColors.brightAccent
                              : AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          memory.hasPhoto ? 'Photo sealed in time' : 'Note sealed in time',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                Text(
                  memory.formattedTime,
                  style: AppTypography.timestamp.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.shield_outlined, size: 12, color: AppColors.locked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Opened Row (Clean, takes minimal space, zero clutter)
  Widget _buildCompactOpenedRow(BuildContext context, Memory memory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMemoryTap != null ? () => onMemoryTap!(memory) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: memory.isImportant
                    ? AppColors.brightAccent.withValues(alpha: 0.3)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              children: [
                // Small thumbnail or icon
                if (memory.hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: _buildThumbnail(memory.imageUrl!),
                    ),
                  )
                else
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.brightAccent),
                  ),
                const SizedBox(width: 10),

                // Compact Title & Content snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (memory.title?.isNotEmpty == true) ...[
                        Row(
                          children: [
                            if (memory.isImportant) ...[
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.brightAccent),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                memory.title!,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                      ],
                      Text(
                        memory.content,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Text(
                  memory.formattedTime,
                  style: AppTypography.timestamp.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, size: 14, color: AppColors.textTertiary),
      );
    } else if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return const Icon(Icons.image_outlined, size: 14, color: AppColors.textTertiary);
  }
}
