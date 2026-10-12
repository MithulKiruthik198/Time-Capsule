import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../models/capsule.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/pro_upgrade_modal.dart';
import '../../widgets/vault_chrono_vessel.dart';
import '../memory/widgets/share_card_modal.dart';

class CreateCapsuleDialog extends StatefulWidget {
  final void Function(Capsule createdCapsule)? onCapsuleCreated;

  const CreateCapsuleDialog({super.key, this.onCapsuleCreated});

  @override
  State<CreateCapsuleDialog> createState() => _CreateCapsuleDialogState();
}

class _CreateCapsuleDialogState extends State<CreateCapsuleDialog>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController(text: 'My Future Self');
  DateTime _targetUnlockDate = CapsuleDateUtils.getPresetOneYear();
  String _selectedPreset = AppStrings.presetOneYear;
  bool _isSealing = false;
  bool _showSealedAnimation = false;
  Capsule? _createdCapsule;

  late AnimationController _sealAnimController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeTextAnimation;

  @override
  void initState() {
    super.initState();
    _sealAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sealAnimController, curve: Curves.easeOutCubic),
    );

    _fadeTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sealAnimController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sealAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(hours: 1)),
      lastDate: now.add(const Duration(days: 365 * 30)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child!,
        ),
      );

      final combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 12,
        pickedTime?.minute ?? 0,
      );

      if (combined.isAfter(DateTime.now())) {
        setState(() {
          _targetUnlockDate = combined;
          _selectedPreset = AppStrings.presetCustom;
        });
      }
    }
  }

  Future<void> _sealCapsule() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final all = await repo.getAllCapsules();
    if (!SubscriptionService().canCreateCapsule(all.length)) {
      if (mounted) {
        ProUpgradeModal.show(
          context,
          reasonMessage: AppStrings.freeCapsuleLimitReached,
        );
      }
      return;
    }

    setState(() => _isSealing = true);

    try {
      final capsule = await repo.createCapsule(
        title: _titleController.text.trim().isEmpty ? 'My Future Self' : _titleController.text.trim(),
        unlockAtUtc: _targetUnlockDate.toUtc(),
      );

      // Schedule notification and anticipation milestones
      await NotificationService().showMemoryLockedNotification();
      await NotificationService().scheduleCapsuleMilestones(
        capsuleId: capsule.id,
        capsuleTitle: capsule.title,
        createdAtUtc: capsule.createdAt,
        unlockAtUtc: capsule.unlockAt,
      );

      HapticFeedback.heavyImpact();

      if (mounted) {
        setState(() {
          _createdCapsule = capsule;
          _showSealedAnimation = true;
        });
        _sealAnimController.forward();

        widget.onCapsuleCreated?.call(capsule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seal capsule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSealing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSealedAnimation) {
      return _buildSealedAnimation();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.createCapsuleTitle, style: AppTypography.displayMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Give your capsule a name',
                style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: AppTypography.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g., Open When I\'m 30, Year of 2026-2027',
                ),
              ),
              const SizedBox(height: 32),

              Text(
                AppStrings.chooseHorizon,
                style: AppTypography.titleLarge.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPresetChip(AppStrings.presetOneMonth, CapsuleDateUtils.getPresetOneMonth()),
                  _buildPresetChip(AppStrings.presetSixMonths, CapsuleDateUtils.getPresetSixMonths()),
                  _buildPresetChip(AppStrings.presetOneYear, CapsuleDateUtils.getPresetOneYear()),
                  _buildPresetChip(AppStrings.presetFiveYears, CapsuleDateUtils.getPresetFiveYears()),
                  if (kDebugMode)
                    _buildPresetChip(AppStrings.presetQuickTest, CapsuleDateUtils.getPresetQuickTest()),
                  ActionChip(
                    label: Text(
                      _selectedPreset == AppStrings.presetCustom
                          ? CapsuleDateUtils.formatShortDate(_targetUnlockDate.toUtc())
                          : AppStrings.presetCustom,
                      style: AppTypography.labelSmall.copyWith(
                        color: _selectedPreset == AppStrings.presetCustom
                            ? Colors.black
                            : AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: _selectedPreset == AppStrings.presetCustom
                        ? AppColors.brightAccent
                        : AppColors.surface,
                    side: const BorderSide(color: AppColors.surfaceBorderLight),
                    onPressed: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Pre-Seal Review Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.brightAccent.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_clock_rounded, size: 15, color: AppColors.brightAccent),
                        const SizedBox(width: 8),
                        Text(
                          'PRE-SEAL REVIEW',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.brightAccent,
                            letterSpacing: 2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _titleController.text.trim().isEmpty
                          ? 'MY FUTURE SELF'
                          : _titleController.text.trim().toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Opens ${CapsuleDateUtils.formatFullDate(_targetUnlockDate.toUtc())}',
                      style: AppTypography.emotionalHeadline.copyWith(
                        color: AppColors.brightAccent,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sealed for $_selectedPreset. You can keep adding daily memories until this moment arrives.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              GlowingButton(
                label: 'SEAL THIS MOMENT',
                icon: Icons.lock_outline_rounded,
                isLoading: _isSealing,
                onPressed: _sealCapsule,
              ),
              const SizedBox(height: 8),
              Text(
                'Opens ${CapsuleDateUtils.formatShortDate(_targetUnlockDate.toUtc())}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, DateTime date) {
    final isSelected = _selectedPreset == label;
    return ChoiceChip(
      label: Text(
        label,
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
      onSelected: (_) {
        setState(() {
          _selectedPreset = label;
          _targetUnlockDate = date;
        });
      },
    );
  }

  Widget _buildSealedAnimation() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Accessible Skip Control
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Skip',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
              const Spacer(),

              // Dimensional Vault sealing with VaultChronoVessel
              AnimatedBuilder(
                animation: _sealAnimController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding stasis aura
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brightAccent.withValues(
                                alpha: 0.35 * _glowAnimation.value,
                              ),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      VaultChronoVessel(
                        capsule: _createdCapsule,
                        forcedState: ChronoVesselState.sealedEarly,
                        size: 146,
                        showProgressRing: false,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              // Elegant text reveal
              FadeTransition(
                opacity: _fadeTextAnimation,
                child: Column(
                  children: [
                    Text(
                      AppStrings.capsuleSealedHeader,
                      style: AppTypography.displayLarge.copyWith(
                        letterSpacing: 2,
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '“${AppStrings.capsuleSealedConfirmationVariations[DateTime.now().millisecondsSinceEpoch % AppStrings.capsuleSealedConfirmationVariations.length]}”',
                      style: AppTypography.emotionalHeadline.copyWith(
                        fontSize: 18,
                        color: AppColors.brightAccent,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      CapsuleDateUtils.formatFullDate(_targetUnlockDate.toUtc()),
                      style: AppTypography.heroNumber.copyWith(
                        fontSize: 26,
                        color: AppColors.brightAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'See you on the other side.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _fadeTextAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_createdCapsule != null) {
                          ShareCardModal.show(context, capsule: _createdCapsule);
                        }
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 16, color: AppColors.brightAccent),
                      label: Text(
                        'Share Keepsake Card',
                        style: AppTypography.button.copyWith(color: AppColors.brightAccent, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlowingButton(
                      label: 'Enter Time Vault',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
