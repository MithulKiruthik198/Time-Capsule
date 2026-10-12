import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/day_group.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/orbital_capsule_hero.dart';
import '../../widgets/pro_upgrade_modal.dart';
import '../capsules/create_capsule_dialog.dart';
import '../capture/add_memory_modal.dart';
import '../documentary/cinematic_reel_view.dart';
import '../documentary/hardcover_album_view.dart';
import '../memory/capsule_reveal_view.dart';
import '../memory/locked_capsule_view.dart';
import '../memory/opened_capsule_view.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onNavigateToCapture;

  const HomeView({
    super.key,
    required this.onNavigateToCapture,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SubscriptionService _sub = SubscriptionService();
  String? _focalCapsuleId;

  @override
  void initState() {
    super.initState();
    _sub.addListener(_onSubChanged);
  }

  @override
  void dispose() {
    _sub.removeListener(_onSubChanged);
    super.dispose();
  }

  void _onSubChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openCreateCapsuleDialog() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final allCapsules = await repo.getAllCapsules();

    if (!_sub.canCreateCapsule(allCapsules.length)) {
      if (!mounted) return;
      ProUpgradeModal.show(
        context,
        reasonMessage: AppStrings.freeCapsuleLimitReached,
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCapsuleDialog(),
    );
  }

  void _openAddMemoryModal(Capsule capsule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMemoryModal(capsule: capsule),
    );
  }

  void _handleCapsuleTap(Capsule capsule) {
    if (capsule.isReady) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CapsuleRevealView(capsule: capsule),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else if (capsule.isLocked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LockedCapsuleView(capsule: capsule)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OpenedCapsuleView(capsule: capsule)),
      );
    }
  }

  void _playCinematicReel(Capsule capsule, List<Memory> memories) {
    if (memories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinematicReelView(capsule: capsule, memories: memories),
      ),
    );
  }

  void _openHardcoverAlbum(Capsule capsule, List<Memory> memories) {
    if (memories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HardcoverAlbumView(capsule: capsule, memories: memories),
      ),
    );
  }

  List<DayGroup> _buildDayGroups(List<Memory> memories) {
    final Map<String, List<Memory>> map = {};
    for (final m in memories) {
      map.putIfAbsent(m.dayKey, () => []).add(m);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final List<DayGroup> groups = [];

    for (final key in sortedKeys) {
      final parsed = DateFormat('yyyy-MM-dd').parse(key);
      final mems = map[key]!;
      mems.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      groups.add(DayGroup(date: parsed, memories: mems));
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppRepositoryManager().capsuleRepository;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Capsule?>(
          stream: repo.watchActiveCapsule(),
          builder: (context, capsuleSnapshot) {
            final activeCapsule = capsuleSnapshot.data;

            if (capsuleSnapshot.connectionState == ConnectionState.waiting &&
                activeCapsule == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (activeCapsule == null) {
              return _buildEmptyState();
            }

            return FutureBuilder<List<Capsule>>(
              future: repo.getAllCapsules(),
              builder: (context, allCapsulesSnapshot) {
                final allCapsules = allCapsulesSnapshot.data ?? [activeCapsule];
                final focalCapsule = (allCapsules.any((c) => c.id == _focalCapsuleId))
                    ? allCapsules.firstWhere((c) => c.id == _focalCapsuleId)
                    : activeCapsule;

                return StreamBuilder<List<Memory>>(
                  stream: repo.watchCapsuleMemories(focalCapsule.id),
                  builder: (context, memoriesSnapshot) {
                    final memories = memoriesSnapshot.data ?? [];
                    final dayGroups = _buildDayGroups(memories);
                    final daysCount = dayGroups.where((g) => !g.isQuietDay).length;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(focalCapsule),
                          const SizedBox(height: 16),

                          // Multi-Capsule Selector Carousel (when vault contains >1 capsule)
                          if (allCapsules.length > 1)
                            _buildMultiCapsuleSelector(allCapsules, focalCapsule),

                          // Four-State Vault Capsule Hero Centerpiece
                          OrbitalCapsuleHero(
                            capsule: focalCapsule,
                            memoryCount: memories.length,
                            dayCount: daysCount,
                            onCapsuleTap: () => _handleCapsuleTap(focalCapsule),
                          ),
                          const SizedBox(height: 20),

                          // Action CTA Center
                          _buildHeroActionCta(focalCapsule, memories),
                          const SizedBox(height: 24),

                          // Highlighted YESTERA PRO Banner
                          _buildProHighlightBanner(),
                          const SizedBox(height: 24),

                          // Capsule Vault Tab (100% Sealed & Confidential - Zero Photo Leaks)
                          _buildJourneySection(
                            activeCapsule: focalCapsule,
                            totalMoments: memories.length,
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMultiCapsuleSelector(List<Capsule> allCapsules, Capsule focal) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allCapsules.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final capsule = allCapsules[index];
          final isSelected = capsule.id == focal.id;
          final isLocked = capsule.isLocked;
          final accentColor = isLocked ? AppColors.brightAccent : AppColors.readyGold;

          return InkWell(
            onTap: () {
              setState(() {
                _focalCapsuleId = capsule.id;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isLocked
                        ? AppColors.brightAccent.withValues(alpha: 0.16)
                        : AppColors.readyGold.withValues(alpha: 0.16))
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.surfaceBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    capsule.isReady
                        ? Icons.lock_open_rounded
                        : (capsule.isOpened
                            ? Icons.auto_stories_rounded
                            : Icons.lock_outline_rounded),
                    size: 14,
                    color: isSelected ? accentColor : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    capsule.title,
                    style: AppTypography.badge.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroActionCta(Capsule activeCapsule, List<Memory> memories) {
    if (activeCapsule.isReady) {
      return Center(
        child: GlowingButton(
          label: 'OPEN TIME CAPSULE',
          icon: Icons.lock_open_rounded,
          onPressed: () => _handleCapsuleTap(activeCapsule),
        ),
      );
    }

    if (activeCapsule.isOpened) {
      // Documentary options when opened
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _playCinematicReel(activeCapsule, memories),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    'REPLAY REEL',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.brightAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.accent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _openHardcoverAlbum(activeCapsule, memories),
                  icon: const Icon(Icons.menu_book_rounded, size: 20, color: AppColors.brightAccent),
                  label: Text(
                    'OPEN ALBUM',
                    style: AppTypography.button.copyWith(
                      color: AppColors.brightAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _openCreateCapsuleDialog,
            icon: const Icon(Icons.hourglass_bottom_rounded, size: 15, color: AppColors.textSecondary),
            label: Text(
              'Create New Time Capsule',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    // Locked active capsule: Single clean "+ ADD TO CAPSULE"
    return Center(
      child: GlowingButton(
        label: 'ADD TO CAPSULE',
        icon: Icons.add_rounded,
        onPressed: () => _openAddMemoryModal(activeCapsule),
      ),
    );
  }

  /// Highlighted YESTERA PRO Luxury Card
  Widget _buildProHighlightBanner() {
    final isPro = _sub.isPro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [const Color(0xFF142416), AppColors.surfaceElevated]
              : [const Color(0xFF2E220F), AppColors.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPro
              ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
              : AppColors.brightAccent.withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPro ? const Color(0xFF4CAF50) : AppColors.accent).withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPro
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                  : AppColors.accent.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
                width: 1,
              ),
            ),
            child: Icon(
              isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'YESTERA PRO',
                      style: AppTypography.badge.copyWith(
                        color: isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isPro ? const Color(0xFF4CAF50) : AppColors.brightAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPro ? 'ACTIVE' : 'VIP',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isPro
                      ? 'Infinite Vault active • Unlimited capsules & 4K media'
                      : 'Unlimited vaults • Audio memos • 4K video clips',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? AppColors.surface : AppColors.brightAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isPro
                      ? AppColors.surfaceBorderLight
                      : AppColors.brightAccent,
                ),
              ),
              elevation: 0,
            ),
            onPressed: () => ProUpgradeModal.show(context),
            child: Text(
              isPro ? 'PERKS' : 'UPGRADE',
              style: AppTypography.badge.copyWith(
                fontSize: 10,
                color: isPro ? AppColors.brightAccent : Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Capsule? capsule) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          // Celestial Brand Medallion
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brightAccent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/yestera_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 20,
                  color: AppColors.brightAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Brand Wordmark & Tagline (Flexes safely with zero overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFFDE8),
                      Color(0xFFF7D98D),
                      Color(0xFFD6A84F),
                      Color(0xFF9E7227),
                      Color(0xFFF7E2A8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'YESTERA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.2,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '✦ YOUR LIFE. REPLAYED. ✦',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brightAccent.withValues(alpha: 0.85),
                    fontSize: 8.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Pro badge & Create Capsule button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => ProUpgradeModal.show(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sub.isPro
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.18)
                        : AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _sub.isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sub.isPro ? Icons.workspace_premium_rounded : Icons.flash_on_rounded,
                        size: 12,
                        color: _sub.isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _sub.isPro ? 'PRO' : 'UPGRADE',
                        style: AppTypography.badge.copyWith(
                          color: _sub.isPro ? const Color(0xFF81C784) : AppColors.brightAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brightAccent, size: 22),
                tooltip: 'Create New Capsule',
                onPressed: _openCreateCapsuleDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(null),
          const SizedBox(height: 36),

          OrbitalCapsuleHero(
            capsule: null,
            onCapsuleTap: _openCreateCapsuleDialog,
          ),
          const SizedBox(height: 28),

          Text(
            AppStrings.emptyVaultTitle,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.emptyVaultSubtitle,
            style: AppTypography.emotionalHeadline.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          GlowingButton(
            label: AppStrings.emptyVaultCta,
            icon: Icons.hourglass_top_rounded,
            onPressed: _openCreateCapsuleDialog,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildJourneySection({
    required Capsule activeCapsule,
    required int totalMoments,
  }) {
    final isReady = activeCapsule.isReady;
    final isOpened = activeCapsule.isOpened;
    final isLocked = activeCapsule.isLocked;

    final primaryThemeColor = isLocked
        ? AppColors.brightAccent
        : (isReady ? AppColors.readyGold : AppColors.champagne);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isOpened
                  ? 'UNSEALED TIME VAULT'
                  : (isReady ? 'READY TO OPEN' : 'ACTIVE TIME VAULT'),
              style: AppTypography.badge.copyWith(
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: primaryThemeColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryThemeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryThemeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$totalMoments Moments Sealed',
                style: AppTypography.badge.copyWith(
                  color: primaryThemeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sealed Capsule Vault Card (Zero photo leaks, click to view countdown)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleCapsuleTap(activeCapsule),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryThemeColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryThemeColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryThemeColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryThemeColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isReady
                                ? Icons.lock_open_rounded
                                : (isOpened ? Icons.auto_stories_rounded : Icons.lock_rounded),
                            color: primaryThemeColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeCapsule.title.toUpperCase(),
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isOpened
                                  ? 'Capsule Unsealed • Documentary Ready'
                                  : 'Target: ${activeCapsule.formattedUnlockDate}',
                              style: AppTypography.caption.copyWith(
                                color: isReady ? AppColors.readyGold : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 14,
                          color: primaryThemeColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isOpened
                                ? 'Tap to view archival countdown & documentary records'
                                : '🔒 Confidential: Tap to view countdown to open capsule',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
