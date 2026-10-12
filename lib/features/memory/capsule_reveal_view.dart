import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../models/capsule.dart';
import '../../models/day_group.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/vault_chrono_vessel.dart';
import 'opened_capsule_view.dart';

class CapsuleRevealView extends StatefulWidget {
  final Capsule capsule;

  const CapsuleRevealView({super.key, required this.capsule});

  @override
  State<CapsuleRevealView> createState() => _CapsuleRevealViewState();
}

class _CapsuleRevealViewState extends State<CapsuleRevealView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<DayGroup> _timeline = [];
  List<Memory> _allMemories = [];
  bool _hasMarkedOpened = false;
  bool _hapticFired = false;

  // Staged animations
  late Animation<double> _lightPointFade;
  late Animation<double> _stage1Fade;
  late Animation<double> _stage2Fade;
  late Animation<double> _stage3Fade;
  late Animation<double> _unlockBurst;
  late Animation<double> _stage5FirstMemoryFade;
  late Animation<double> _exploreCtaFade;

  @override
  void initState() {
    super.initState();
    _loadCapsuleData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _controller.addListener(() {
      if (!_hapticFired && _controller.value >= 0.62) {
        _hapticFired = true;
        HapticFeedback.mediumImpact();
      }
    });

    // 1. Tiny gold light (0.0 -> 0.20)
    _lightPointFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.20, curve: Curves.easeIn),
    );

    // Stage 1: "You asked me to remember this." (0.10 -> 0.28)
    _stage1Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.28, curve: Curves.easeIn),
    );

    // Stage 2: Date + "One year ago." (0.28 -> 0.45)
    _stage2Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.45, curve: Curves.easeIn),
    );

    // Stage 3: YOUR YEAR metrics (0.45 -> 0.65)
    _stage3Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
    );

    // Stage 4: Mechanical/cosmic unlock burst (0.62 -> 0.78)
    _unlockBurst = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.78, curve: Curves.easeOutBack),
    );

    // Stage 5: First memory preview (0.75 -> 0.90)
    _stage5FirstMemoryFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 0.90, curve: Curves.easeIn),
    );

    // Stage 6: Explore Entire Capsule CTA (0.88 -> 1.0)
    _exploreCtaFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
    _markOpened();
  }

  Future<void> _loadCapsuleData() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final timeline = await repo.getTimelineForCapsule(widget.capsule.id);
    final memories = await repo.getMemoriesForCapsule(widget.capsule.id);
    if (mounted) {
      setState(() {
        _timeline = timeline;
        _allMemories = memories;
      });
    }
  }

  Future<void> _markOpened() async {
    if (_hasMarkedOpened) return;
    _hasMarkedOpened = true;
    try {
      final repo = AppRepositoryManager().capsuleRepository;
      await repo.markCapsuleOpened(widget.capsule.id);
      AnalyticsService().memoryOpened(memoryId: widget.capsule.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDocumentary() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OpenedCapsuleView(capsule: widget.capsule),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMoments = _allMemories.length;
    final daysCount = _timeline.where((g) => !g.isQuietDay).length;
    final importantMoments = _allMemories.where((m) => m.isImportant).length;
    final firstMemory = _allMemories.isNotEmpty ? _allMemories.last : null; // earliest memory

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top navigation / Skip
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: _navigateToDocumentary,
                      icon: const Icon(Icons.fast_forward_rounded, size: 14, color: AppColors.textTertiary),
                      label: Text(
                        'SKIP',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // STAGE 1: Tiny gold light point
                  FadeTransition(
                    opacity: _lightPointFade,
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brightAccent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // "You asked me to remember this."
                  FadeTransition(
                    opacity: _stage1Fade,
                    child: Text(
                      '“${AppStrings.revealStage1}”',
                      style: AppTypography.emotionalHeadline.copyWith(
                        fontSize: 24,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // STAGE 2: Creation Date + "One year ago."
                  FadeTransition(
                    opacity: _stage2Fade,
                    child: Column(
                      children: [
                        Text(
                          widget.capsule.formattedCreatedDate.toUpperCase(),
                          style: AppTypography.heroSubtitle.copyWith(
                            color: AppColors.brightAccent,
                            fontSize: 14,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CapsuleDateUtils.formatElapsedDuration(widget.capsule.createdAt),
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // STAGE 3: YOUR YEAR Summary
                  FadeTransition(
                    opacity: _stage3Fade,
                    child: Column(
                      children: [
                        Text(
                          AppStrings.yourYearHeader,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 26,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricItem('$totalMoments', 'MOMENTS'),
                              _buildMetricItem('$daysCount', 'DAYS'),
                              _buildMetricItem('$importantMoments', 'KEY MOMENTS'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // STAGE 4: Physical Vault Capsule Equatorial Seam Rupture & Gold Light Bloom
                  ScaleTransition(
                    scale: _unlockBurst,
                    child: Center(
                      child: VaultChronoVessel(
                        capsule: widget.capsule,
                        forcedState: ChronoVesselState.ready,
                        size: 156,
                        crackOpenProgress: _unlockBurst.value,
                        showProgressRing: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // STAGE 5: First Memory Preview (Blur-to-focus transition)
                  if (firstMemory != null) ...[
                    FadeTransition(
                      opacity: _stage5FirstMemoryFade,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: ((1.0 - _stage5FirstMemoryFade.value) * 12.0).clamp(0.0, 12.0),
                          sigmaY: ((1.0 - _stage5FirstMemoryFade.value) * 12.0).clamp(0.0, 12.0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.surfaceBorderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WHERE IT ALL BEGAN',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brightAccent,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '“${firstMemory.content}”',
                                style: AppTypography.emotionalHeadline.copyWith(
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],

                  // STAGE 6: Explore Entire Capsule Button
                  FadeTransition(
                    opacity: _exploreCtaFade,
                    child: GlowingButton(
                      label: 'Explore Your Year',
                      icon: Icons.auto_stories_rounded,
                      onPressed: _navigateToDocumentary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: AppTypography.heroNumber.copyWith(
            fontSize: 22,
            color: AppColors.brightAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
