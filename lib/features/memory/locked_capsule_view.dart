import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/vault_chrono_vessel.dart';

class LockedCapsuleView extends StatefulWidget {
  final Capsule capsule;

  const LockedCapsuleView({super.key, required this.capsule});

  @override
  State<LockedCapsuleView> createState() => _LockedCapsuleViewState();
}

class _LockedCapsuleViewState extends State<LockedCapsuleView>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  Timer? _heartbeatTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isHoldingCore = false;
  int? _selectedEchoIndex;

  @override
  void initState() {
    super.initState();
    // 1-second live countdown ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Gentle stasis breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onCoreHoldStart() {
    HapticFeedback.lightImpact();
    setState(() {
      _isHoldingCore = true;
    });

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 620), (_) {
      HapticFeedback.lightImpact();
    });
  }

  void _onCoreHoldEnd() {
    _heartbeatTimer?.cancel();
    if (mounted) {
      setState(() {
        _isHoldingCore = false;
      });
    }
  }

  Duration _getTimeRemaining() {
    final diff = widget.capsule.unlockAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  ChronoVesselState _getVesselState() {
    final diff = _getTimeRemaining();
    if (diff <= Duration.zero) {
      return ChronoVesselState.ready;
    }
    if (diff.inHours <= 48) {
      return ChronoVesselState.approaching;
    }
    return ChronoVesselState.sealedEarly;
  }

  String _getDailyReflection() {
    if (AppStrings.lockedReflections.isEmpty) {
      return AppStrings.lockedScreenMessage;
    }
    final index = (widget.capsule.id.hashCode + DateTime.now().day).abs() %
        AppStrings.lockedReflections.length;
    return AppStrings.lockedReflections[index];
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppRepositoryManager().capsuleRepository;
    final remaining = _getTimeRemaining();
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final vesselState = _getVesselState();
    final progress = widget.capsule.progressRatio;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.brightAccent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.capsule.title,
          style: AppTypography.displayMedium.copyWith(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColors.brightAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  'SEALED',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.brightAccent,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Memory>>(
          stream: repo.watchCapsuleMemories(widget.capsule.id),
          builder: (context, snapshot) {
            final memories = snapshot.data ?? [];
            final totalMoments = memories.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header Pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brightAccent.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brightAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brightAccent.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vesselState == ChronoVesselState.approaching
                                ? 'APPROACHING HORIZON • UNLOCK NEAR'
                                : 'TEMPORAL STASIS CONFINED',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.brightAccent,
                              letterSpacing: 1.8,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Temporal Resonance Chamber: Interactive Stasis Core
                  _buildTemporalResonanceChamber(vesselState, progress),
                  const SizedBox(height: 22),

                  // Live Real-Time Countdown Grid (Days, Hours, Minutes, Seconds)
                  _buildLiveCountdownGrid(days, hours, minutes, seconds),
                  const SizedBox(height: 18),

                  // Target Unlock Date
                  Text(
                    'Unlocks on ${widget.capsule.formattedUnlockDate}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Spacetime Trajectory Arc (Traversed path from sealed date to unlock)
                  _buildSpacetimeTrajectoryArc(progress),
                  const SizedBox(height: 24),

                  // Orbiting Memory Resonance Echoes (Interactive Confidential Nodes)
                  if (memories.isNotEmpty) ...[
                    _buildMemoryResonanceEchoes(memories),
                    const SizedBox(height: 24),
                  ],

                  // Rotating Intimate Philosophy Reflection
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '“${_getDailyReflection()}”',
                          style: AppTypography.emotionalHeadline.copyWith(
                            color: AppColors.brightAccent,
                            fontSize: 14.5,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalMoments ${totalMoments == 1 ? "memory" : "memories"} sealed in silence',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Return CTA Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brightAccent,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.brightAccent,
                    ),
                    label: Text(
                      'RETURN TO VAULT',
                      style: AppTypography.button.copyWith(
                        color: AppColors.brightAccent,
                        letterSpacing: 1.4,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTemporalResonanceChamber(
    ChronoVesselState vesselState,
    double progress,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final auraScale = _isHoldingCore ? (1.08 + _pulseAnimation.value * 0.08) : 1.0;
        final auraAlpha = _isHoldingCore ? 0.35 : 0.12;

        return Column(
          children: [
            GestureDetector(
              onTapDown: (_) => _onCoreHoldStart(),
              onTapUp: (_) => _onCoreHoldEnd(),
              onTapCancel: () => _onCoreHoldEnd(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Concentric Stasis Aura Ripples
                  Transform.scale(
                    scale: auraScale,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: auraAlpha),
                            AppColors.accentGlow.withValues(alpha: auraAlpha * 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Centerpiece Vault Chrono Vessel (State 2 or 3)
                  VaultChronoVessel(
                    capsule: widget.capsule,
                    forcedState: vesselState,
                    size: 156,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Chamber Status Indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isHoldingCore
                  ? Row(
                      key: const ValueKey('holding'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: AppColors.brightAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TEMPORAL CONFINEMENT STABLE • HEARTBEAT ACTIVE',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.brightAccent,
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: AppColors.brightAccent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Touch & hold stasis core to sense temporal resonance',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveCountdownGrid(int days, int hours, int minutes, int seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCountdownUnit('$days', 'DAYS'),
          _buildCountdownDivider(),
          _buildCountdownUnit(hours.toString().padLeft(2, '0'), 'HOURS'),
          _buildCountdownDivider(),
          _buildCountdownUnit(minutes.toString().padLeft(2, '0'), 'MINS'),
          _buildCountdownDivider(),
          _buildCountdownUnit(seconds.toString().padLeft(2, '0'), 'SECS'),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.heroNumber.copyWith(
            fontSize: 26,
            color: AppColors.brightAccent,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.badge.copyWith(
            color: AppColors.textTertiary,
            fontSize: 9.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.accent.withValues(alpha: 0.3),
    );
  }

  Widget _buildSpacetimeTrajectoryArc(double progress) {
    final pct = (progress * 100).clamp(0.0, 100.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPACETIME TRAJECTORY',
                style: AppTypography.badge.copyWith(
                  color: AppColors.brightAccent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$pct% TRAVERSED',
                style: AppTypography.badge.copyWith(
                  color: AppColors.brightAccent,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Glowing Stasis Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 6,
              color: AppColors.surfaceElevated,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.01, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.brightAccent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Origin and Destination Dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sealed: ${widget.capsule.shortCreatedDate}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10.5,
                ),
              ),
              Text(
                'Unlock: ${widget.capsule.shortUnlockDate}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryResonanceEchoes(List<Memory> memories) {
    final echoList = memories.take(7).toList();
    final remainingCount = memories.length - echoList.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RESONANCE ECHOES',
                style: AppTypography.badge.copyWith(
                  color: AppColors.brightAccent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Confidential Stasis • Tap Node',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Orbiting Echo Nodes
          Row(
            children: [
              for (int i = 0; i < echoList.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _buildEchoNode(echoList[i], i),
              ],
              if (remainingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    '+$remainingCount',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Interactive Non-Leaking Cryptic Stasis Hint
          if (_selectedEchoIndex != null &&
              _selectedEchoIndex! < memories.length) ...[
            const SizedBox(height: 12),
            _buildEchoInspectionCard(memories[_selectedEchoIndex!], _selectedEchoIndex! + 1),
          ],
        ],
      ),
    );
  }

  Widget _buildEchoNode(Memory memory, int index) {
    final isSelected = _selectedEchoIndex == index;
    final isImportant = memory.isImportant;

    IconData nodeIcon;
    if (memory.hasPhoto || memory.memoryType == 'photo') {
      nodeIcon = Icons.blur_on_rounded;
    } else if (memory.memoryType == 'voice') {
      nodeIcon = Icons.graphic_eq_rounded;
    } else {
      nodeIcon = Icons.auto_awesome_rounded;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedEchoIndex = isSelected ? null : index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brightAccent.withValues(alpha: 0.25)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brightAccent
                : (isImportant
                    ? AppColors.brightAccent.withValues(alpha: 0.6)
                    : AppColors.surfaceBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brightAccent.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            nodeIcon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.brightAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildEchoInspectionCard(Memory memory, int index) {
    String typeLabel;
    String crypticHint;

    if (memory.hasPhoto || memory.memoryType == 'photo') {
      typeLabel = 'VISUAL MOMENT';
      crypticHint = 'A visual instant frozen in time • Sealed from view until the horizon.';
    } else if (memory.memoryType == 'voice') {
      typeLabel = 'VOICE MEMO';
      crypticHint = 'An acoustic transmission resting in stasis • Awaiting the dawn.';
    } else {
      typeLabel = 'WRITTEN THOUGHT';
      crypticHint = 'An intimate reflection sealed in silence • Guarded until unlock.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brightAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brightAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColors.brightAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ECHO #$index • $typeLabel',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.brightAccent,
                        fontSize: 9.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (memory.isImportant) ...[
                      const SizedBox(width: 6),
                      Text(
                        '✦ ESSENTIAL',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.brightAccent,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  crypticHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
