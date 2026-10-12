import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/memory.dart';
import '../memory/widgets/share_card_modal.dart';
import 'hardcover_album_view.dart';

/// Option A: In-App Cinematic "Memory Reel" Player
///
/// Features:
/// - Ken Burns slow zoom & pan animation
/// - Segmented stories-style progress indicators
/// - Ambient tone toggle
/// - Tap to skip / hold to pause
/// - Emotional typography overlay
/// - Keepsake export at end of reel
class CinematicReelView extends StatefulWidget {
  final Capsule capsule;
  final List<Memory> memories;

  const CinematicReelView({
    super.key,
    required this.capsule,
    required this.memories,
  });

  @override
  State<CinematicReelView> createState() => _CinematicReelViewState();
}

class _CinematicReelViewState extends State<CinematicReelView>
    with SingleTickerProviderStateMixin {
  late List<Memory> _sortedMemories;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isMuted = false;
  late AnimationController _progressController;

  static const Duration _slideDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    // Sort memories chronologically for narrative progression
    _sortedMemories = List<Memory>.from(widget.memories)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    _progressController = AnimationController(
      vsync: this,
      duration: _slideDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextSlide();
      }
    });

    if (_sortedMemories.isNotEmpty) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentIndex < _sortedMemories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _showReelCompletionSheet();
    }
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  void _showReelCompletionSheet() {
    _progressController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.brightAccent, width: 1.5),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.brightAccent, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'DOCUMENTARY COMPLETE',
                style: AppTypography.displayMedium.copyWith(
                  letterSpacing: 2,
                  fontSize: 20,
                  color: AppColors.brightAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You just replayed ${_sortedMemories.length} moments from ${widget.capsule.title}.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.surfaceBorderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _currentIndex = 0;
                        });
                        _progressController.reset();
                        _progressController.forward();
                      },
                      icon: const Icon(Icons.replay_rounded, color: AppColors.textPrimary, size: 18),
                      label: Text('Replay', style: AppTypography.button),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HardcoverAlbumView(
                              capsule: widget.capsule,
                              memories: widget.memories,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Open Album',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedMemories.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Cinematic Reel')),
        body: const Center(child: Text('No memories available to replay.')),
      );
    }

    final currentMemory = _sortedMemories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.35) {
            _previousSlide();
          } else {
            _nextSlide();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ken Burns background visual
            _buildKenBurnsBackground(currentMemory),

            // Subtle dark vignette overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),

            // Top Header: Segmented Progress Bar & Controls
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Segmented bars
                    _buildSegmentedProgressBar(),
                    const SizedBox(height: 12),

                    // Top Bar with App Branding and close
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.movie_creation_outlined,
                                  size: 14, color: AppColors.brightAccent),
                              const SizedBox(width: 6),
                              Text(
                                '${AppStrings.appName} REEL',
                                style: AppTypography.badge.copyWith(
                                  letterSpacing: 1.5,
                                  color: AppColors.brightAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isPaused) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pause_rounded, size: 12, color: AppColors.brightAccent),
                                const SizedBox(width: 4),
                                Text(
                                  'PAUSED',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: AppColors.brightAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Audio ambience toggle button
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.music_note_rounded,
                            color: _isMuted ? AppColors.textTertiary : AppColors.brightAccent,
                            size: 20,
                          ),
                          tooltip: _isMuted ? 'Ambient Unmuted' : 'Ambient Tone Active',
                          onPressed: () {
                            setState(() => _isMuted = !_isMuted);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        // Close
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content Overlay (Title, quote note, timestamp)
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Memory Date & Origin
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentMemory.formattedDay.toUpperCase(),
                            style: AppTypography.timestamp.copyWith(
                              color: AppColors.brightAccent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentMemory.formattedTime,
                          style: AppTypography.timestamp.copyWith(color: AppColors.textSecondary),
                        ),
                        if (currentMemory.isImportant) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.brightAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title if exists
                    if (currentMemory.title?.isNotEmpty == true) ...[
                      Text(
                        currentMemory.title!,
                        style: AppTypography.displayMedium.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            const Shadow(color: Colors.black, blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Emotional Content
                    Text(
                      '“${currentMemory.content}”',
                      style: AppTypography.emotionalHeadline.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        height: 1.4,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Keepsake Share button
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.surface.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: AppColors.surfaceBorderLight),
                            ),
                          ),
                          onPressed: () {
                            _pause();
                            ShareCardModal.show(
                              context,
                              memory: currentMemory,
                              capsule: widget.capsule,
                            ).then((_) => _resume());
                          },
                          icon: const Icon(Icons.auto_awesome, size: 15, color: AppColors.brightAccent),
                          label: Text(
                            'Share Keepsake Card',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.brightAccent),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${_sortedMemories.length}',
                          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar() {
    return Row(
      children: List.generate(_sortedMemories.length, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: index < _currentIndex
                    ? const ColoredBox(color: AppColors.brightAccent)
                    : index == _currentIndex
                        ? AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brightAccent,
                                ),
                              );
                            },
                          )
                        : const ColoredBox(color: Colors.white24),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKenBurnsBackground(Memory memory) {
    if (memory.hasPhoto) {
      return AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          // Slow cinematic scale: 1.0 to 1.12
          final scale = 1.0 + (_progressController.value * 0.12);
          final translateY = (_progressController.value * -15);

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: _buildImage(memory.imageUrl!),
            ),
          );
        },
      );
    }

    // Elegant animated radiant backdrop for text-only moments
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF262116),
            Color(0xFF11131A),
            Color(0xFF08090D),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.format_quote_rounded,
          size: 160,
          color: AppColors.accent.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
      );
    } else if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return const Center(child: Icon(Icons.photo, color: Colors.white38));
  }
}
