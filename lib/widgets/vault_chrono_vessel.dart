import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/capsule.dart';

/// The 4 distinct physical states of the Vault Capsule (Chrono-Vessel)
enum ChronoVesselState {
  /// State 1: Dormant, dim, unlit, minimal particles (empty vault)
  dormant,

  /// State 2: Sealed, warm golden stasis field, slow breathing pulse (>48h)
  sealedEarly,

  /// State 3: Approaching horizon (final 48h), intensified kinetic luminescence
  approaching,

  /// State 4: Ready to open / opened, radiant celebratory gold with cracked seam
  ready,
}

/// Helper to resolve the ChronoVesselState from a Capsule
ChronoVesselState resolveVesselState(Capsule? capsule) {
  if (capsule == null) return ChronoVesselState.dormant;
  if (capsule.isReady || capsule.isOpened) return ChronoVesselState.ready;
  final remaining = capsule.unlockAt.difference(DateTime.now());
  if (remaining.inHours <= 48 && remaining.inSeconds > 0) {
    return ChronoVesselState.approaching;
  }
  return ChronoVesselState.sealedEarly;
}

Color getVesselThemeColor(ChronoVesselState state) {
  switch (state) {
    case ChronoVesselState.dormant:
      return const Color(0xFF262116);
    case ChronoVesselState.sealedEarly:
      return AppColors.accent;
    case ChronoVesselState.approaching:
      return AppColors.brightAccent;
    case ChronoVesselState.ready:
      return AppColors.readyGold;
  }
}

/// The Evolving Hero Object: The Vault Capsule (Chrono-Vessel)
///
/// A physical, tactile vessel crafted from obsidian metal and celestial stasis fields.
/// Appears consistently across Home, Locked Capsule Detail, and Unlock Sequence.
class VaultChronoVessel extends StatefulWidget {
  final Capsule? capsule;
  final ChronoVesselState? forcedState;
  final double size;
  final bool showProgressRing;
  final bool showParticles;
  final double crackOpenProgress; // 0.0 = sealed, 1.0 = fully split open
  final VoidCallback? onTap;

  const VaultChronoVessel({
    super.key,
    this.capsule,
    this.forcedState,
    this.size = 260,
    this.showProgressRing = true,
    this.showParticles = true,
    this.crackOpenProgress = 0.0,
    this.onTap,
  });

  @override
  State<VaultChronoVessel> createState() => _VaultChronoVesselState();
}

class _VaultChronoVesselState extends State<VaultChronoVessel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _ringRotationController;
  late AnimationController _reboundController;

  Offset _tiltOffset = Offset.zero;
  Offset _reboundStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Organic breathing pulse (~5.5 second cycle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    // Dynamic orbital particle cycle
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    // Smooth celestial astrolabe ring rotation
    _ringRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Springback rebound when user releases finger
    _reboundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {
          _tiltOffset = Offset.lerp(_reboundStart, Offset.zero, Curves.easeOutBack.transform(_reboundController.value))!;
        });
      });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _ringRotationController.dispose();
    _reboundController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      final newDx = (_tiltOffset.dx + details.delta.dx * 0.4).clamp(-22.0, 22.0);
      final newDy = (_tiltOffset.dy + details.delta.dy * 0.4).clamp(-22.0, 22.0);
      _tiltOffset = Offset(newDx, newDy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _reboundStart = _tiltOffset;
    _reboundController.forward(from: 0.0);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
      if (_particleController.isAnimating) _particleController.stop();
      if (_ringRotationController.isAnimating) _ringRotationController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_particleController.isAnimating) _particleController.repeat();
      if (!_ringRotationController.isAnimating) _ringRotationController.repeat();
    }

    final state = widget.forcedState ?? resolveVesselState(widget.capsule);
    final themeColor = getVesselThemeColor(state);
    final isReady = state == ChronoVesselState.ready;
    final isDormant = state == ChronoVesselState.dormant;

    final progress = widget.capsule == null
        ? 0.0
        : (widget.capsule!.isOpened || widget.capsule!.isReady
            ? 1.0
            : widget.capsule!.progressRatio);

    return GestureDetector(
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Volumetric Ambient Horizon Glow
            if (!isDormant)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = _pulseController.value;
                  return Container(
                    width: widget.size * 0.98,
                    height: widget.size * 0.98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          themeColor.withValues(alpha: isReady ? (0.24 + 0.10 * pulse) : (0.16 + 0.08 * pulse)),
                          themeColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.25, 0.65, 1.0],
                      ),
                    ),
                  );
                },
              ),

            // 2. Astrolabe Celestial Orbiting Rings & Tick Markings
            if (!isDormant)
              AnimatedBuilder(
                animation: Listenable.merge([_ringRotationController, _pulseController]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size * 0.96, widget.size * 0.96),
                    painter: _CelestialAstrolabeRingsPainter(
                      rotation: _ringRotationController.value,
                      pulse: _pulseController.value,
                      color: themeColor,
                      state: state,
                      tilt: _tiltOffset,
                    ),
                  );
                },
              ),

            // 3. Stardust Motes & Quantum Memory Flares
            if (widget.showParticles && !isDormant)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _VesselStardustPainter(
                      progress: _particleController.value,
                      color: themeColor,
                      state: state,
                    ),
                  );
                },
              ),

            // 4. Progress Perimeter Ring
            if (widget.showProgressRing && !isDormant)
              CustomPaint(
                size: Size(widget.size * 0.88, widget.size * 0.88),
                painter: _VesselProgressRingPainter(
                  progress: progress,
                  color: themeColor,
                  isCompleted: isReady,
                ),
              ),

            // 5. The Physical Chrono-Sphere Singularity Core (With Parallax Tilt)
            Transform.translate(
              offset: _tiltOffset,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _ringRotationController]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size * 0.64, widget.size * 0.76),
                    painter: _VaultCapsuleChassisPainter(
                      state: state,
                      themeColor: themeColor,
                      pulse: _pulseController.value,
                      rotation: _ringRotationController.value,
                      crackOpenProgress: widget.crackOpenProgress,
                      tiltOffset: _tiltOffset,
                    ),
                  );
                },
              ),
            ),

            // 6. Ready State Celebratory Seal Breach Affordance
            if (isReady && widget.crackOpenProgress <= 0.05)
              Positioned(
                bottom: widget.size * 0.08,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.readyGold, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.readyGold.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open_rounded, size: 14, color: AppColors.readyGold),
                      const SizedBox(width: 6),
                      Text(
                        'READY TO OPEN',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.readyGold,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
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
}

/// Celestial Astrolabe Orbiting Rings & Tick Markings
class _CelestialAstrolabeRingsPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color color;
  final ChronoVesselState state;
  final Offset tilt;

  _CelestialAstrolabeRingsPainter({
    required this.rotation,
    required this.pulse,
    required this.color,
    required this.state,
    required this.tilt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.48;
    final isReady = state == ChronoVesselState.ready;
    final isApproaching = state == ChronoVesselState.approaching;

    // A. Outer Astrolabe Fixed Coordinate Track
    final outerTrackPaint = Paint()
      ..color = color.withValues(alpha: isReady ? 0.35 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    // 12 Astrolabe Radial Hour/Time Coordinates
    final tickAngleBase = rotation * 2 * math.pi;
    final tickPaint = Paint()
      ..color = color.withValues(alpha: isReady ? 0.6 : 0.35)
      ..strokeWidth = 1.4;

    for (int i = 0; i < 12; i++) {
      final angle = tickAngleBase + (i * (math.pi / 6));
      final isMajor = i % 3 == 0;
      final innerR = outerRadius - (isMajor ? 8.0 : 4.5);
      final p1 = Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle));
      final p2 = Offset(center.dx + outerRadius * math.cos(angle), center.dy + outerRadius * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);

      // Cardinal celestial node beads
      if (isMajor) {
        final nodePoint = Offset(center.dx + (outerRadius + 1) * math.cos(angle), center.dy + (outerRadius + 1) * math.sin(angle));
        canvas.drawCircle(nodePoint, 2.5, Paint()..color = color);
        canvas.drawCircle(nodePoint, 1.2, Paint()..color = Colors.white);
      }
    }

    // B. Middle Counter-Rotating Gyroscopic Celestial Ring
    canvas.save();
    canvas.translate(center.dx + tilt.dx * 0.3, center.dy + tilt.dy * 0.3);
    canvas.rotate(-tickAngleBase * 0.7);

    final midRingRect = Rect.fromCenter(
      center: Offset.zero,
      width: outerRadius * 1.84,
      height: outerRadius * (0.85 + 0.15 * math.sin(tickAngleBase)),
    );

    final midRingPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.1),
          color.withValues(alpha: isReady ? 0.7 : 0.4),
          color.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: isReady ? 0.8 : 0.5),
          color.withValues(alpha: 0.1),
        ],
      ).createShader(midRingRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isApproaching || isReady ? 1.6 : 1.2;

    canvas.drawOval(midRingRect, midRingPaint);

    // Orbital celestial bead along middle ring
    final orbitalAngle = tickAngleBase * 1.8;
    final orbX = (midRingRect.width / 2) * math.cos(orbitalAngle);
    final orbY = (midRingRect.height / 2) * math.sin(orbitalAngle);
    canvas.drawCircle(
      Offset(orbX, orbY),
      3.2,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset(orbX, orbY), 2.0, Paint()..color = Colors.white);
    canvas.restore();

    // C. Inner Gimbal Resonant Horizon (Tilted by Touch)
    canvas.save();
    canvas.translate(center.dx + tilt.dx * 0.6, center.dy + tilt.dy * 0.6);
    canvas.rotate(tickAngleBase * 0.4);

    final innerGimbalRect = Rect.fromCenter(
      center: Offset.zero,
      width: outerRadius * 1.55,
      height: outerRadius * 0.65,
    );

    final innerGimbalPaint = Paint()
      ..color = color.withValues(alpha: 0.25 + 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(innerGimbalRect, innerGimbalPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CelestialAstrolabeRingsPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.state != state ||
        oldDelegate.tilt != tilt;
  }
}

/// Custom Painter for the Chrono-Sphere Singularity Core
class _VaultCapsuleChassisPainter extends CustomPainter {
  final ChronoVesselState state;
  final Color themeColor;
  final double pulse;
  final double rotation;
  final double crackOpenProgress;
  final Offset tiltOffset;

  _VaultCapsuleChassisPainter({
    required this.state,
    required this.themeColor,
    required this.pulse,
    required this.rotation,
    required this.crackOpenProgress,
    required this.tiltOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final isDormant = state == ChronoVesselState.dormant;
    final isReady = state == ChronoVesselState.ready;
    final isApproaching = state == ChronoVesselState.approaching;

    final sphereRadius = (size.width * 0.44);
    final seamGap = (isReady ? (6.0 + 16.0 * crackOpenProgress) : 0.0);
    final topDisplacement = -seamGap / 2;
    final bottomDisplacement = seamGap / 2;

    // A. Singularity Horizon Aura behind Core
    if (!isDormant) {
      final coreAuraPaint = Paint()
        ..color = themeColor.withValues(alpha: isReady ? 0.35 : (isApproaching ? 0.26 : 0.18))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(center, sphereRadius + 10, coreAuraPaint);
    }

    // B. ESCAPING LIGHT BEAMS & FISSURE ENERGY (When cracked open in Ready State)
    if (isReady && seamGap > 1.0) {
      final lightBeamPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            AppColors.readyGold,
            AppColors.amberGold.withValues(alpha: 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCenter(center: center, width: sphereRadius * 3.2, height: seamGap * 5));

      canvas.drawOval(
        Rect.fromCenter(center: center, width: sphereRadius * 3.0, height: seamGap * 4.5),
        lightBeamPaint,
      );
    }

    // C. TOP CHRONO-SPHERE HEMISPHERE
    canvas.save();
    canvas.translate(0, topDisplacement);
    final topClipRect = Rect.fromLTRB(
      center.dx - sphereRadius * 1.3,
      center.dy - sphereRadius * 1.3,
      center.dx + sphereRadius * 1.3,
      center.dy,
    );
    canvas.clipRect(topClipRect);

    // Top Spherical Body Gradient (Rich Obsidian Titanium with Warm Gold Specular Highlight)
    final topSpherePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.35 + (tiltOffset.dx * 0.015).clamp(-0.2, 0.2), -0.45 + (tiltOffset.dy * 0.015).clamp(-0.2, 0.2)),
        radius: 0.95,
        colors: isDormant
            ? const [Color(0xFF2A241C), Color(0xFF1E1A14), Color(0xFF12100C), Color(0xFF080705)]
            : [
                const Color(0xFF382E1E),
                const Color(0xFF241D13),
                isReady ? const Color(0xFF2C2010) : const Color(0xFF15120C),
                const Color(0xFF0C0A07),
              ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: sphereRadius));

    canvas.drawCircle(center, sphereRadius, topSpherePaint);

    // Outer Precision Titanium Rim
    final rimPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          themeColor.withValues(alpha: 0.2),
          themeColor.withValues(alpha: isReady ? 0.9 : 0.6),
          Colors.white.withValues(alpha: 0.8),
          themeColor.withValues(alpha: 0.3),
        ],
        transform: GradientRotation(rotation * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: sphereRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, sphereRadius, rimPaint);

    // Engraved Latitude Arc on Top Shell
    final latPaint = Paint()
      ..color = themeColor.withValues(alpha: isDormant ? 0.1 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - sphereRadius * 0.35), width: sphereRadius * 1.4, height: sphereRadius * 0.6),
      0,
      math.pi,
      false,
      latPaint,
    );

    // Specular Lens Glare Arc
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDormant ? 0.05 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: sphereRadius - 4),
      -math.pi * 0.85,
      math.pi * 0.35,
      false,
      glarePaint,
    );

    canvas.restore();

    // D. BOTTOM CHRONO-SPHERE HEMISPHERE
    canvas.save();
    canvas.translate(0, bottomDisplacement);
    final bottomClipRect = Rect.fromLTRB(
      center.dx - sphereRadius * 1.3,
      center.dy,
      center.dx + sphereRadius * 1.3,
      center.dy + sphereRadius * 1.3,
    );
    canvas.clipRect(bottomClipRect);

    // Bottom Spherical Body Gradient
    final bottomSpherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.4),
        radius: 0.95,
        colors: isDormant
            ? const [Color(0xFF1E1A14), Color(0xFF14120E), Color(0xFF0D0B08), Color(0xFF060504)]
            : [
                const Color(0xFF261F14),
                const Color(0xFF19140D),
                isReady ? const Color(0xFF22180C) : const Color(0xFF120F0A),
                const Color(0xFF080705),
              ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: sphereRadius));

    canvas.drawCircle(center, sphereRadius, bottomSpherePaint);

    // Bottom Rim
    canvas.drawCircle(center, sphereRadius, rimPaint);

    // Bottom Engraved Latitude Arc
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + sphereRadius * 0.35), width: sphereRadius * 1.4, height: sphereRadius * 0.6),
      math.pi,
      math.pi,
      false,
      latPaint,
    );

    canvas.restore();

    // E. THE CENTRAL TEMPORAL RELIC CHAMBER (Floating Key / Lock / Energy Core)
    final chamberCenter = Offset(center.dx + tiltOffset.dx * 0.3, center.dy + tiltOffset.dy * 0.3);
    final chamberRadius = sphereRadius * 0.44;

    // Chamber Aperture Lens
    final aperturePaint = Paint()
      ..shader = RadialGradient(
        colors: isDormant
            ? const [Color(0xFF181510), Color(0xFF100E0A), Color(0xFF080705)]
            : [
                themeColor.withValues(alpha: isReady ? 0.35 : 0.22),
                const Color(0xFF16130E),
                const Color(0xFF080705),
              ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: chamberCenter, radius: chamberRadius));
    canvas.drawCircle(chamberCenter, chamberRadius, aperturePaint);

    // Chamber Glowing Border Ring
    final chamberBorder = Paint()
      ..color = themeColor.withValues(alpha: isDormant ? 0.2 : (isReady ? 0.85 : 0.55))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(chamberCenter, chamberRadius, chamberBorder);

    // Concentric Energy Ripples inside Chamber
    if (!isDormant) {
      final waveRadius = chamberRadius * (0.45 + 0.45 * pulse);
      final ripplePaint = Paint()
        ..color = themeColor.withValues(alpha: (0.35 * (1.0 - pulse)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(chamberCenter, waveRadius, ripplePaint);

      // Organic Fluid Energy Wave Filament
      final filamentPath = Path();
      final waveAngle = rotation * 2 * math.pi;
      for (double x = -chamberRadius * 0.7; x <= chamberRadius * 0.7; x += 4) {
        final y = math.sin(waveAngle + x * 0.12) * (chamberRadius * 0.18 * pulse);
        if (x == -chamberRadius * 0.7) {
          filamentPath.moveTo(chamberCenter.dx + x, chamberCenter.dy + y);
        } else {
          filamentPath.lineTo(chamberCenter.dx + x, chamberCenter.dy + y);
        }
      }
      final filamentPaint = Paint()
        ..color = themeColor.withValues(alpha: isReady ? 0.7 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(filamentPath, filamentPaint);
    }

    // Sacred Lock / Unlocked Relic Icon
    final iconData = isReady ? Icons.lock_open_rounded : Icons.lock_rounded;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: chamberRadius * 1.08,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: isReady ? AppColors.readyGold : (isApproaching ? AppColors.brightAccent : themeColor),
          shadows: [
            Shadow(
              color: (isReady ? AppColors.readyGold : themeColor).withValues(alpha: 0.6),
              blurRadius: 10,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(chamberCenter.dx - iconPainter.width / 2, chamberCenter.dy - iconPainter.height / 2),
    );

    // F. THE EQUATORIAL CONTAINMENT SEAM
    final seamY = center.dy;
    final seamWidth = sphereRadius * 2.15;

    if (isDormant) {
      final dormantSeam = Paint()
        ..color = const Color(0xFF262116)
        ..strokeWidth = 1.8;
      canvas.drawLine(
        Offset(center.dx - seamWidth / 2, seamY),
        Offset(center.dx + seamWidth / 2, seamY),
        dormantSeam,
      );
    } else if (isReady) {
      final seamGlow = Paint()
        ..color = AppColors.readyGold.withValues(alpha: 0.85)
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawLine(
        Offset(center.dx - seamWidth * 0.62, seamY),
        Offset(center.dx + seamWidth * 0.62, seamY),
        seamGlow,
      );

      final coreLight = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.6;
      canvas.drawLine(
        Offset(center.dx - seamWidth * 0.52, seamY),
        Offset(center.dx + seamWidth * 0.52, seamY),
        coreLight,
      );
    } else {
      final pulseBrightness = 0.5 + 0.5 * pulse;
      final seamGlow = Paint()
        ..color = themeColor.withValues(alpha: (0.45 + 0.35 * pulseBrightness).clamp(0.0, 1.0))
        ..strokeWidth = isApproaching ? 4.8 : 3.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(
        Offset(center.dx - seamWidth * 0.55, seamY),
        Offset(center.dx + seamWidth * 0.55, seamY),
        seamGlow,
      );

      final coreSeam = Paint()
        ..color = isApproaching ? AppColors.brightAccent : AppColors.accent
        ..strokeWidth = 1.8;
      canvas.drawLine(
        Offset(center.dx - seamWidth * 0.5, seamY),
        Offset(center.dx + seamWidth * 0.5, seamY),
        coreSeam,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VaultCapsuleChassisPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.pulse != pulse ||
        oldDelegate.rotation != rotation ||
        oldDelegate.crackOpenProgress != crackOpenProgress ||
        oldDelegate.tiltOffset != tiltOffset;
  }
}

/// Dynamic Progress Ring around the Vessel
class _VesselProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isCompleted;

  _VesselProgressRingPainter({
    required this.progress,
    required this.color,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // Background Track
    final trackPaint = Paint()
      ..color = AppColors.surfaceBorderLight.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    final sweepAngle = (isCompleted ? 1.0 : progress.clamp(0.0, 1.0)) * 2 * math.pi;
    const startAngle = -math.pi / 2;

    // Glowing Arc
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, glowPaint);

    // Primary Arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.3), color, Colors.white],
        stops: const [0.0, 0.7, 1.0],
        transform: const GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, arcPaint);

    // Waypoint Bead
    if (!isCompleted && progress < 0.99) {
      final tipAngle = startAngle + sweepAngle;
      final tip = Offset(center.dx + radius * math.cos(tipAngle), center.dy + radius * math.sin(tipAngle));
      canvas.drawCircle(tip, 4.0, Paint()..color = color);
      canvas.drawCircle(tip, 2.0, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _VesselProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.isCompleted != isCompleted;
}

/// Particle Stardust Painter
class _VesselStardustPainter extends CustomPainter {
  final double progress;
  final Color color;
  final ChronoVesselState state;

  _VesselStardustPainter({
    required this.progress,
    required this.color,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final speed = state == ChronoVesselState.approaching ? 1.4 : 1.0;
    final baseAngle = progress * 2 * math.pi * speed;

    final particles = [
      Offset(size.width * 0.46, size.height * 0.44),
      Offset(size.width * 0.52, size.height * 0.48),
      Offset(size.width * 0.56, size.height * 0.54),
      Offset(size.width * 0.48, size.height * 0.50),
      Offset(size.width * 0.58, size.height * 0.56),
    ];

    for (int i = 0; i < particles.length; i++) {
      final a = particles[i].dx;
      final b = particles[i].dy;
      final angle = baseAngle + (i * 1.25);
      final x = center.dx + (a * 0.8) * math.cos(angle);
      final y = center.dy + (b * 0.8) * math.sin(angle);
      final twinkle = 0.4 + 0.6 * math.sin(angle * 3);

      final paint = Paint()
        ..color = color.withValues(alpha: (0.35 * twinkle).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VesselStardustPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
