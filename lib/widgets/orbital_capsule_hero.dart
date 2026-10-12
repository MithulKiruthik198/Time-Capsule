import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/date_utils.dart';
import '../models/capsule.dart';
import 'vault_chrono_vessel.dart';

/// The Living Spacetime Vortex — Handcrafted Celestial Time Machine:
/// - Official YESTERA Golden Hourglass Cosmic Emblem at singularity core
/// - Organic Gravitational Spacetime Wave Ripples breathing outwards
/// - Living Solar Corona Flare undulating with liquid golden light
/// - Floating Keplerian Stardust Memory Orbiters drifting in natural elliptical orbits
/// - Real-Time Live Ticking Countdown Clock (Days : Hours : Mins : Secs)
class OrbitalCapsuleHero extends StatefulWidget {
  final Capsule? capsule;
  final int memoryCount;
  final int dayCount;
  final VoidCallback onCapsuleTap;

  const OrbitalCapsuleHero({
    super.key,
    required this.capsule,
    this.memoryCount = 0,
    this.dayCount = 0,
    required this.onCapsuleTap,
  });

  @override
  State<OrbitalCapsuleHero> createState() => _OrbitalCapsuleHeroState();
}

class _OrbitalCapsuleHeroState extends State<OrbitalCapsuleHero>
    with TickerProviderStateMixin {
  late AnimationController _vortexController;
  late AnimationController _rippleController;
  Timer? _ticker;
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    // Continuous cosmic rotation for stardust and celestial filaments
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Breathing gravitational wave pulsation (fluid 4-second cycle)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();

    // 1-second real-time countdown ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentSecond = DateTime.now().second;
      if (mounted && widget.capsule != null && widget.capsule!.isLocked) {
        setState(() {
          _lastTickSecond = currentSecond;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _vortexController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_vortexController.isAnimating) _vortexController.stop();
      if (_rippleController.isAnimating) _rippleController.stop();
    } else {
      if (!_vortexController.isAnimating) _vortexController.repeat();
      if (!_rippleController.isAnimating) _rippleController.repeat();
    }

    final cap = widget.capsule;
    final isReady = cap?.isReady ?? false;
    final isOpened = cap?.isOpened ?? false;
    final isLocked = cap != null && cap.isLocked;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header label
          Text(
            cap != null ? cap.title.toUpperCase() : 'VAULT DORMANT',
            style: AppTypography.heroSubtitle.copyWith(
              color: isReady
                  ? AppColors.readyGold
                  : (cap != null ? AppColors.brightAccent : AppColors.textTertiary),
              letterSpacing: 3.5,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // The Four-State Vault Capsule (Chrono-Vessel) Centerpiece
          VaultChronoVessel(
            capsule: cap,
            size: 265,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onCapsuleTap();
            },
          ),

          const SizedBox(height: 18),

          // Real-Time Live Ticking Countdown (or Completion message)
          if (isLocked) ...[
            _buildLiveCountdownClock(cap.unlockAt),
            const SizedBox(height: 10),
            Text(
              'Time Traveling to ${cap.formattedUnlockDate}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (isReady) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.readyGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.readyGold),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.readyGold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Your Time Machine Journey is Complete',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.readyGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isOpened) ...[
            Text(
              AppStrings.capsuleOpenedOn,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              cap?.openedAt != null
                  ? CapsuleDateUtils.formatFullDate(cap!.openedAt!)
                  : (cap?.formattedUnlockDate ?? ''),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.readyGold,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'Nothing is waiting yet.',
              style: AppTypography.displayMedium.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Give yourself something worth coming back for.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 12),

          // Moments in orbit stats badge
          if (cap != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReady
                      ? AppColors.readyGold.withValues(alpha: 0.4)
                      : AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: isReady ? AppColors.readyGold : AppColors.brightAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.memoryCount} ${widget.memoryCount == 1 ? "moment" : "moments"}  •  ${widget.dayCount} ${widget.dayCount == 1 ? "day" : "days"} sealed in vault',
                    style: AppTypography.timestamp.copyWith(
                      color: isReady ? AppColors.readyGold : AppColors.brightAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Real-Time Live Ticking Countdown Clock
  Widget _buildLiveCountdownClock(DateTime unlockAt) {
    final now = DateTime.now().toUtc();
    final remaining = unlockAt.difference(now);

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = (remaining.inSeconds % 60).clamp(0, 59);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeSegment(days.toString(), 'DAYS'),
          _buildColon(),
          _buildTimeSegment(hours.toString().padLeft(2, '0'), 'HOURS'),
          _buildColon(),
          _buildTimeSegment(minutes.toString().padLeft(2, '0'), 'MINS'),
          _buildColon(),
          _buildTimeSegment(
            seconds.toString().padLeft(2, '0'),
            'SECS',
            isLive: true,
            key: ValueKey(_lastTickSecond),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSegment(String val, String label, {bool isLive = false, Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: Text(
            val,
            key: ValueKey(val),
            style: AppTypography.heroNumber.copyWith(
              fontSize: 22,
              letterSpacing: 1.0,
              color: isLive ? AppColors.brightAccent : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.badge.copyWith(
            fontSize: 9,
            color: isLive ? AppColors.brightAccent.withValues(alpha: 0.8) : AppColors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        ':',
        style: AppTypography.heroNumber.copyWith(
          fontSize: 18,
          color: AppColors.brightAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

