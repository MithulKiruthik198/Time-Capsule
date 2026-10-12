import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import 'widgets/share_card_modal.dart';

class MemoryDetailView extends StatelessWidget {
  final Memory memory;

  const MemoryDetailView({super.key, required this.memory});

  void _shareCard(BuildContext context) {
    AnalyticsService().memoryShared(memoryId: memory.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareCardModal(memory: memory),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Memory?', style: AppTypography.titleLarge),
        content: Text(
          'This moment will be removed permanently.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTypography.button),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AppRepositoryManager().repository.deleteMemory(memory.id);
      AnalyticsService().memoryDeleted(memoryId: memory.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareCard(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Relative timestamp badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.opened.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      memory.relativeOriginText.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.opened,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Captured ${memory.formattedCreatedDate}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              if (memory.title?.isNotEmpty == true) ...[
                Text(
                  memory.title!,
                  style: AppTypography.displayLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 16),
              ],

              // Photo
              if (memory.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _buildImage(memory.imageUrl!),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  memory.content,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 17,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              GlowingButton(
                label: 'Create Keepsake Card',
                icon: Icons.auto_awesome_rounded,
                isSecondary: true,
                onPressed: () => _shareCard(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textTertiary),
        ),
      );
    } else if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return const Center(child: Icon(Icons.image_outlined, color: AppColors.textTertiary));
  }
}
