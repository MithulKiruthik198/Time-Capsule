import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../models/memory.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/pro_upgrade_modal.dart';
import '../capsules/create_capsule_dialog.dart';
import '../memory/capsule_reveal_view.dart';
import '../memory/locked_capsule_view.dart';
import '../memory/opened_capsule_view.dart';

enum CapsuleFilter { all, locked, ready, opened }

class TimelineView extends StatefulWidget {
  final VoidCallback onNavigateToCapture;

  const TimelineView({
    super.key,
    required this.onNavigateToCapture,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  CapsuleFilter _currentFilter = CapsuleFilter.all;
  List<Capsule> _capsules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final list = await repo.getAllCapsules();
    if (mounted) {
      setState(() {
        _capsules = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateCapsule() async {
    final sub = SubscriptionService();
    if (!sub.canCreateCapsule(_capsules.length)) {
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
      builder: (_) => CreateCapsuleDialog(
        onCapsuleCreated: (_) => _loadCapsules(),
      ),
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
      ).then((_) => _loadCapsules());
    } else if (capsule.isLocked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LockedCapsuleView(capsule: capsule)),
      ).then((_) => _loadCapsules());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OpenedCapsuleView(capsule: capsule)),
      ).then((_) => _loadCapsules());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Time Vaults', style: AppTypography.displayLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.brightAccent),
            tooltip: 'Yestera Pro',
            onPressed: () => ProUpgradeModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brightAccent),
            tooltip: 'Create New Capsule',
            onPressed: _openCreateCapsule,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _capsules.isEmpty
                ? _buildEmptyState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 54,
              color: AppColors.locked,
            ),
            const SizedBox(height: 20),
            Text(
              'NO VAULTS SEALED YET',
              style: AppTypography.displayLarge.copyWith(fontSize: 20, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a Time Capsule to preserve your daily memories for the future.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GlowingButton(
              label: AppStrings.emptyVaultCta,
              icon: Icons.hourglass_bottom_rounded,
              onPressed: _openCreateCapsule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final filteredCapsules = _capsules.where((c) {
      switch (_currentFilter) {
        case CapsuleFilter.locked:
          return c.isLocked;
        case CapsuleFilter.ready:
          return c.isReady;
        case CapsuleFilter.opened:
          return c.isOpened;
        case CapsuleFilter.all:
          return true;
      }
    }).toList();

    final lockedCount = _capsules.where((c) => c.isLocked).length;
    final readyCount = _capsules.where((c) => c.isReady).length;
    final openedCount = _capsules.where((c) => c.isOpened).length;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: _loadCapsules,
      child: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', CapsuleFilter.all, _capsules.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Waiting', CapsuleFilter.locked, lockedCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ready', CapsuleFilter.ready, readyCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Opened', CapsuleFilter.opened, openedCount),
                ],
              ),
            ),
          ),

          // Capsules List
          Expanded(
            child: filteredCapsules.isEmpty
                ? Center(
                    child: Text(
                      'No capsules in this category.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: filteredCapsules.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final capsule = filteredCapsules[index];
                      return _buildCapsuleCard(capsule);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleCard(Capsule capsule) {
    final repo = AppRepositoryManager().capsuleRepository;
    final isReady = capsule.isReady;
    final isOpened = capsule.isOpened;

    final borderColor = isReady
        ? AppColors.ready
        : (isOpened ? AppColors.opened.withValues(alpha: 0.5) : AppColors.surfaceBorder);

    return StreamBuilder<List<Memory>>(
      stream: repo.watchCapsuleMemories(capsule.id),
      builder: (context, snapshot) {
        final memories = snapshot.data ?? [];
        final count = memories.length;

        return GlassCard(
          borderColor: borderColor,
          onTap: () => _handleCapsuleTap(capsule),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceElevated,
                      border: Border.all(
                        color: isReady
                            ? AppColors.ready
                            : (isOpened ? AppColors.opened : AppColors.locked),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isReady
                            ? Icons.lock_open_rounded
                            : (isOpened ? Icons.auto_stories_rounded : Icons.lock_rounded),
                        size: 20,
                        color: isReady
                            ? AppColors.ready
                            : (isOpened ? AppColors.opened : AppColors.locked),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Timeline dates
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capsule.title,
                          style: AppTypography.titleLarge.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${capsule.shortCreatedDate} → ${capsule.shortUnlockDate}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isReady
                              ? AppColors.ready
                              : (isOpened ? AppColors.opened : AppColors.surfaceBorder))
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isReady ? 'READY' : (isOpened ? 'OPENED' : 'WAITING'),
                      style: AppTypography.labelSmall.copyWith(
                        color: isReady
                            ? AppColors.ready
                            : (isOpened ? AppColors.opened : AppColors.textSecondary),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Countdown / Status text & moment badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReady
                        ? 'Ready to reveal your memories'
                        : (isOpened ? 'Documentary available' : 'Unlocks in ${capsule.countdownString}'),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isReady ? AppColors.ready : AppColors.brightAccent,
                      fontWeight: isReady ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count ${count == 1 ? "moment" : "moments"}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, CapsuleFilter filter, int count) {
    final isSelected = _currentFilter == filter;

    return ChoiceChip(
      label: Text(
        '$label ($count)',
        style: AppTypography.labelSmall.copyWith(
          color: isSelected ? Colors.black : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.brightAccent,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.brightAccent : AppColors.surfaceBorder,
      ),
      onSelected: (_) => setState(() => _currentFilter = filter),
    );
  }
}

