import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/day_group.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import '../capsules/create_capsule_dialog.dart';
import '../documentary/cinematic_reel_view.dart';
import '../documentary/hardcover_album_view.dart';
import 'locked_capsule_view.dart';
import 'memory_detail_view.dart';
import 'widgets/share_card_modal.dart';

class OpenedCapsuleView extends StatefulWidget {
  final Capsule capsule;

  const OpenedCapsuleView({super.key, required this.capsule});

  @override
  State<OpenedCapsuleView> createState() => _OpenedCapsuleViewState();
}

class _OpenedCapsuleViewState extends State<OpenedCapsuleView> {
  bool _filterImportantOnly = false;
  List<DayGroup> _timeline = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Strict Mystery Shielding: Never allow unboxing view if still locked in stasis
    if (widget.capsule.isLocked && !widget.capsule.isReady && !widget.capsule.isOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LockedCapsuleView(capsule: widget.capsule)),
          );
        }
      });
      return;
    }
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final timeline = await repo.getTimelineForCapsule(widget.capsule.id);
    if (mounted) {
      setState(() {
        _timeline = timeline;
        _isLoading = false;
      });
    }
  }

  void _openMemory(Memory memory) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoryDetailView(memory: memory)),
    );
  }

  void _openCinematicReel(List<Memory> memories) {
    if (memories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinematicReelView(
          capsule: widget.capsule,
          memories: memories,
        ),
      ),
    );
  }

  void _openHardcoverAlbum(List<Memory> memories) {
    if (memories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HardcoverAlbumView(
          capsule: widget.capsule,
          memories: memories,
        ),
      ),
    );
  }

  void _shareYearCard() {
    final allMemories = _timeline.expand((g) => g.memories).toList();
    if (allMemories.isEmpty) return;

    final centerpiece = allMemories.firstWhere(
      (m) => m.isImportant,
      orElse: () => allMemories.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardModal(
        memory: centerpiece,
        capsule: widget.capsule,
      ),
    );
  }

  void _createNewCapsule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCapsuleDialog(
        onCapsuleCreated: (_) {
          Navigator.pop(context); // pop modal
          Navigator.pop(context); // return to home
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMemories = _timeline.expand((g) => g.memories).toList();
    final importantMemories = allMemories.where((m) => m.isImportant).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.capsule.title, style: AppTypography.displayMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.movie_creation_outlined, color: AppColors.brightAccent),
            tooltip: 'Cinematic Reel',
            onPressed: () => _openCinematicReel(allMemories),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.brightAccent),
            tooltip: 'Hardcover Album',
            onPressed: () => _openHardcoverAlbum(allMemories),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.accent),
            tooltip: AppStrings.shareMyYear,
            onPressed: _shareYearCard,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header documentary banner
                    Center(
                      child: Column(
                        children: [
                          Text(
                            AppStrings.yourYearHeader,
                            style: AppTypography.displayLarge.copyWith(
                              letterSpacing: 2,
                              color: AppColors.brightAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“${AppStrings.lookHowFar}”',
                            style: AppTypography.emotionalHeadline.copyWith(
                              fontSize: 20,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${widget.capsule.formattedCreatedDate} → ${widget.capsule.formattedUnlockDate}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Option A + Option B Action Triggers
                    if (allMemories.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceElevated,
                                foregroundColor: AppColors.brightAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.accent, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _openCinematicReel(allMemories),
                              icon: const Icon(Icons.play_circle_fill_rounded, size: 20, color: AppColors.brightAccent),
                              label: Text(
                                'Cinematic Reel',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.brightAccent,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceElevated,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.surfaceBorderLight, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _openHardcoverAlbum(allMemories),
                              icon: const Icon(Icons.auto_stories_rounded, size: 19, color: AppColors.accent),
                              label: Text(
                                'Archival Album',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Unique Feature 1: The Spacetime Memory Constellation
                    if (allMemories.isNotEmpty) ...[
                      _buildSpacetimeConstellation(allMemories),
                      const SizedBox(height: 20),
                    ],

                    // Unique Feature 2: Letter from Your Past Self (Unsealed Sacred Scroll)
                    _buildLetterFromPastSelf(),
                    const SizedBox(height: 24),

                    // Filter chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text('All Moments (${allMemories.length})'),
                          selected: !_filterImportantOnly,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.surfaceBorder),
                          labelStyle: AppTypography.labelSmall.copyWith(
                            color: !_filterImportantOnly ? Colors.black : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setState(() => _filterImportantOnly = false),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: Text('⭐ Important (${importantMemories.length})'),
                          selected: _filterImportantOnly,
                          selectedColor: AppColors.brightAccent,
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.surfaceBorder),
                          labelStyle: AppTypography.labelSmall.copyWith(
                            color: _filterImportantOnly ? Colors.black : AppColors.brightAccent,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setState(() => _filterImportantOnly = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Memories List
                    if (_filterImportantOnly) ...[
                      if (importantMemories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No moments were marked as important in this capsule.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...importantMemories.map((m) => _buildImportantMemoryCard(m)),
                    ] else ...[
                      if (_timeline.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No moments recorded in this capsule.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._timeline.map((group) {
                          if (group.isQuietDay) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Text(
                                '${group.shortDate} • ${AppStrings.quietDayLabel}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 14, bottom: 8),
                                child: Text(
                                  group.formattedDate.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.brightAccent,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...group.memories.map((m) => _buildTimelineMemoryCard(m)),
                            ],
                          );
                        }),
                    ],

                    const SizedBox(height: 36),

                    // Ready for another year?
                    GlassCard(
                      borderColor: AppColors.accent.withValues(alpha: 0.4),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.readyForAnotherYear,
                            style: AppTypography.titleLarge.copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continue your life\'s journey by sealing another capsule for the next year.',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          GlowingButton(
                            label: AppStrings.createNewCapsule,
                            icon: Icons.hourglass_bottom_rounded,
                            onPressed: _createNewCapsule,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimelineMemoryCard(Memory memory) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: () => _openMemory(memory),
        borderColor: memory.isImportant
            ? AppColors.brightAccent.withValues(alpha: 0.5)
            : AppColors.surfaceBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Day, Time & Importance Indicator
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
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brightAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (memory.isImportant) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brightAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.brightAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 11, color: AppColors.brightAccent),
                        const SizedBox(width: 2),
                        Text(
                          'KEY MOMENT',
                          style: AppTypography.badge.copyWith(fontSize: 9, color: AppColors.brightAccent),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  memory.formattedTime,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),

            // Commanding Large-Format Photo (If memory has a photo)
            if (memory.hasPhoto) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorderLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _buildImage(memory.imageUrl!),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            if (memory.title?.isNotEmpty == true) ...[
              Text(
                memory.title!,
                style: AppTypography.titleLarge.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
            ],

            Text(
              '“${memory.content}”',
              style: AppTypography.emotionalHeadline.copyWith(
                fontSize: 16.5,
                height: 1.45,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),

            // Footer: Archived badge & Keepsake Card export
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 13, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Archived into Vault',
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
                  icon: const Icon(Icons.share_outlined, size: 13, color: AppColors.brightAccent),
                  label: Text(
                    'Keepsake Card',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.brightAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantMemoryCard(Memory memory) {
    return _buildTimelineMemoryCard(memory);
  }

  Widget _buildSpacetimeConstellation(List<Memory> memories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.brightAccent),
              const SizedBox(width: 8),
              Text(
                'SPACETIME CONSTELLATION',
                style: AppTypography.badge.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 11,
                  color: AppColors.brightAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Tap star to inspect',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Constellation Star Map Canvas
          GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null && memories.isNotEmpty) {
                final localX = details.localPosition.dx;
                final width = box.size.width - 32;
                final index = ((localX / width) * memories.length).clamp(0, memories.length - 1).toInt();
                HapticFeedback.selectionClick();
                _openMemory(memories[index]);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 0),
                    radius: 1.2,
                    colors: [
                      Color(0xFF1E1A12),
                      Color(0xFF110F0A),
                      Color(0xFF080705),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _ConstellationPainter(memories: memories),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.capsule.shortCreatedDate,
                style: AppTypography.timestamp.copyWith(color: AppColors.textTertiary, fontSize: 10),
              ),
              Text(
                '${memories.length} celestial moments connected',
                style: AppTypography.caption.copyWith(color: AppColors.brightAccent, fontSize: 10.5),
              ),
              Text(
                widget.capsule.shortUnlockDate,
                style: AppTypography.timestamp.copyWith(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterFromPastSelf() {
    final daysPassed = widget.capsule.unlockAt.difference(widget.capsule.createdAt).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16130D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brightAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brightAccent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 16, color: AppColors.brightAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LETTER FROM YOUR PAST SELF',
                      style: AppTypography.badge.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 11,
                        color: AppColors.brightAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sealed ${widget.capsule.shortCreatedDate} • Unlocked ${widget.capsule.shortUnlockDate}',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '“Look how far you have come. Every memory, photo, and thought preserved in this vault has journeyed through $daysPassed days of life to meet you today.”',
            style: AppTypography.emotionalHeadline.copyWith(
              fontSize: 16,
              height: 1.45,
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: AppColors.textTertiary),
      );
    } else if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return const Icon(Icons.image_outlined, color: AppColors.textTertiary);
  }
}

/// Custom Painter for the Spacetime Memory Constellation
class _ConstellationPainter extends CustomPainter {
  final List<Memory> memories;

  _ConstellationPainter({required this.memories});

  @override
  void paint(Canvas canvas, Size size) {
    if (memories.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final n = memories.length;

    // Background subtle star dust
    final rng = math.Random(42);
    final dustPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (int i = 0; i < 24; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * width, rng.nextDouble() * height),
        rng.nextDouble() * 1.2 + 0.4,
        dustPaint,
      );
    }

    // Compute star positions
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? (width / 2) : (24.0 + (width - 48.0) * (i / (n - 1)));
      final wave = math.sin((i + 1) * 1.8);
      final y = (height / 2) + wave * (height * 0.28);
      points.add(Offset(x, y));
    }

    // Constellation connecting lines
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.brightAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw radiant memory stars
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isImportant = memories[i].isImportant;
      final radius = isImportant ? 5.5 : 3.8;

      // Outer glow
      final auraPaint = Paint()
        ..color = AppColors.readyGold.withValues(alpha: isImportant ? 0.45 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(p, radius * 2.2, auraPaint);

      // Star Core
      final starPaint = Paint()..color = isImportant ? AppColors.readyGold : AppColors.brightAccent;
      canvas.drawCircle(p, radius, starPaint);
      canvas.drawCircle(p, radius * 0.4, Paint()..color = Colors.white);

      // 4-point diffraction flare for important stars
      if (isImportant) {
        final flarePaint = Paint()
          ..color = AppColors.readyGold.withValues(alpha: 0.8)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(p.dx - 10, p.dy), Offset(p.dx + 10, p.dy), flarePaint);
        canvas.drawLine(Offset(p.dx, p.dy - 10), Offset(p.dx, p.dy + 10), flarePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.memories != memories;
}
