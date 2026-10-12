import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/memory.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import '../memory/widgets/share_card_modal.dart';
import 'cinematic_reel_view.dart';

/// Option B: Digital Hardcover Album View
///
/// Features:
/// - Archival gold foil embossed album cover
/// - Tangible fine-art album page spread with photo gallery matting
/// - Elegant serif typography for notes and quotes
/// - Direct keepsake export
/// - Switchable with Cinematic Reel
class HardcoverAlbumView extends StatefulWidget {
  final Capsule capsule;
  final List<Memory> memories;

  const HardcoverAlbumView({
    super.key,
    required this.capsule,
    required this.memories,
  });

  @override
  State<HardcoverAlbumView> createState() => _HardcoverAlbumViewState();
}

class _HardcoverAlbumViewState extends State<HardcoverAlbumView> {
  late PageController _pageController;
  late List<Memory> _sortedMemories;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _sortedMemories = List<Memory>.from(widget.memories)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _sortedMemories.length + 1; // 1 cover + N memories

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ARCHIVAL ALBUM',
          style: AppTypography.displayMedium.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.brightAccent,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Play Cinematic Reel',
            icon: const Icon(Icons.movie_creation_outlined, color: AppColors.brightAccent),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CinematicReelView(
                    capsule: widget.capsule,
                    memories: widget.memories,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top page progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentPage == 0
                        ? 'ALBUM COVER'
                        : 'MOMENT $_currentPage OF ${_sortedMemories.length}',
                    style: AppTypography.timestamp.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.brightAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _currentPage > 0
                            ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _currentPage < totalPages - 1
                            ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Page spread viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAlbumCover();
                  }
                  final memory = _sortedMemories[index - 1];
                  return _buildMemoryPage(memory, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 36,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold Embossed Emblem
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(color: AppColors.brightAccent, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.brightAccent,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                AppStrings.appName.toUpperCase(),
                style: AppTypography.displayLarge.copyWith(
                  letterSpacing: 4,
                  fontSize: 24,
                  color: AppColors.brightAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'OFFICIAL ARCHIVAL EDITION',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 3,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 36),

              Container(
                width: 60,
                height: 1,
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 36),

              Text(
                widget.capsule.title,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.capsule.shortCreatedDate}  —  ${widget.capsule.shortUnlockDate}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 36),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorderLight),
                ),
                child: Text(
                  '${_sortedMemories.length} MOMENTS PRESERVED',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.brightAccent,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              GlowingButton(
                label: 'OPEN FIRST PAGE',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryPage(Memory memory, int pageIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Large-Format Cinematic Exhibition Frame
              if (memory.hasPhoto) ...[
                GestureDetector(
                  onTap: () => _openFullscreenLightbox(memory),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0B08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Pinch-Zoomable Image Canvas
                        ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: 260,
                              maxHeight: MediaQuery.of(context).size.height * 0.52,
                            ),
                            width: double.infinity,
                            color: Colors.black,
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              clipBehavior: Clip.none,
                              child: _buildImage(memory.imageUrl!, fit: BoxFit.contain),
                            ),
                          ),
                        ),

                        // Subtle Fullscreen & Zoom Affordance Pill
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceBorderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.brightAccent),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinch / Tap',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.brightAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Fine-Art Archival Card
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                borderColor: memory.isImportant
                    ? AppColors.brightAccent.withValues(alpha: 0.45)
                    : AppColors.surfaceBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brightAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              memory.formattedDay.toUpperCase(),
                              style: AppTypography.timestamp.copyWith(
                                color: AppColors.brightAccent,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          memory.formattedTime,
                          style: AppTypography.timestamp.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.surfaceBorder, height: 20),

                    if (memory.title?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          if (memory.isImportant) ...[
                            const Icon(Icons.star_rounded, color: AppColors.brightAccent, size: 18),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              memory.title!,
                              style: AppTypography.titleLarge.copyWith(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    Text(
                      '“${memory.content}”',
                      style: AppTypography.emotionalHeadline.copyWith(
                        fontSize: 18,
                        height: 1.45,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Archival verification & Keepsake export footer
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Archived in Vault',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            ShareCardModal.show(
                              context,
                              memory: memory,
                              capsule: widget.capsule,
                            );
                          },
                          icon: const Icon(Icons.share_outlined, size: 14, color: AppColors.brightAccent),
                          label: Text(
                            'Keepsake Card',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.brightAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreenLightbox(Memory memory) {
    if (!memory.hasPhoto) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.96),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.brightAccent),
              actions: [
                IconButton(
                  tooltip: 'Share Keepsake',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    ShareCardModal.show(context, memory: memory, capsule: widget.capsule);
                  },
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: _buildImage(memory.imageUrl!, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
      );
    } else if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }
    return const Center(child: Icon(Icons.photo, color: Colors.white38));
  }
}
