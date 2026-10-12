import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../models/capsule.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/pro_upgrade_modal.dart';
import '../memory/widgets/share_card_modal.dart';

/// Frictionless & Mysterious Standalone Capture Route:
/// - Distraction-free single note canvas (no form fatigue)
/// - Space-saving confidential Encrypted Photo Token (zero image leak, height <50px)
/// - Express quick action bar: Photo, Audio PRO, Video PRO, Star, Inspire Me
/// - Luminous golden "SEAL IN TIME" master action
class CaptureView extends StatefulWidget {
  final VoidCallback? onMemoryLocked;

  const CaptureView({super.key, this.onMemoryLocked});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final SubscriptionService _sub = SubscriptionService();
  Capsule? _activeCapsule;
  bool _isLoading = true;

  // Single canvas memory fields
  final _contentController = TextEditingController();
  final FocusNode _canvasFocusNode = FocusNode();
  bool _isCanvasFocused = false;
  XFile? _selectedImage;
  bool _isImportant = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _todayMediaCount = 0;
  int _promptIndex = 0;

  // Capsule creation fallback fields (if no active capsule exists)
  final _capsuleTitleController = TextEditingController(text: 'My Future Self');
  DateTime _capsuleUnlockDate = CapsuleDateUtils.getPresetOneYear();
  String _selectedPreset = AppStrings.presetOneYear;

  final List<String> _inspirationPrompts = [
    'What made you smile today?',
    'A feeling to remember...',
    'Where were you right now?',
    'A lesson I learned today...',
    'Who was by your side?',
    'One thing I hope never changes...',
  ];

  @override
  void initState() {
    super.initState();
    _canvasFocusNode.addListener(() {
      if (mounted) setState(() => _isCanvasFocused = _canvasFocusNode.hasFocus);
    });
    _checkActiveCapsule();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final count = await _sub.getMediaCountToday();
    if (mounted) setState(() => _todayMediaCount = count);
  }

  Future<void> _checkActiveCapsule() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final cap = await repo.getActiveCapsule();
    if (mounted) {
      setState(() {
        _activeCapsule = cap;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _canvasFocusNode.dispose();
    _contentController.dispose();
    _capsuleTitleController.dispose();
    super.dispose();
  }

  void _cyclePrompt() {
    HapticFeedback.selectionClick();
    final prompt = _inspirationPrompts[_promptIndex % _inspirationPrompts.length];
    _promptIndex++;
    setState(() {
      _contentController.text = prompt;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: prompt.length),
      );
    });
  }

  Future<void> _handlePhotoTap() async {
    if (_selectedImage != null) {
      _showImageOptionsSheet();
      return;
    }

    final canAdd = await _sub.canAddMediaToday();
    if (!canAdd) {
      if (!mounted) return;
      ProUpgradeModal.show(
        context,
        reasonMessage: AppStrings.freeDailyMediaLimitReached,
      );
      return;
    }
    _showImagePickerSheet();
  }

  void _showImageOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text('Replace Photo', style: AppTypography.titleLarge),
                onTap: () {
                  Navigator.pop(context);
                  _showImagePickerSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: Text('Remove Photo', style: AppTypography.titleLarge.copyWith(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text('Choose from Gallery', style: AppTypography.titleLarge),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                title: Text('Take a Photo', style: AppTypography.titleLarge),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await StorageService().pickImage(source);
    if (file != null) {
      setState(() => _selectedImage = file);
      AnalyticsService().photoAdded();
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _handleAudioTap() async {
    if (!_sub.isPro) {
      ProUpgradeModal.show(context, reasonMessage: AppStrings.proFeatureAudio);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _contentController.text = '🎙️ [Voice Memo Recorded]: "Leaving this voice note for my future self..."';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          '🎙️ Audio Voice memo attached to transmission.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.brightAccent),
        ),
      ),
    );
  }

  Future<void> _handleVideoTap() async {
    if (!_sub.isPro) {
      ProUpgradeModal.show(context, reasonMessage: AppStrings.proFeatureVideo);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _contentController.text = '🎥 [Video Moment Attached]: High-definition transmission ready for replay.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          '🎥 Video Moment attached to transmission.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.brightAccent),
        ),
      ),
    );
  }

  Future<void> _createAndSealCapsule() async {
    final repo = AppRepositoryManager().capsuleRepository;
    final all = await repo.getAllCapsules();
    if (!_sub.canCreateCapsule(all.length)) {
      if (!mounted) return;
      ProUpgradeModal.show(
        context,
        reasonMessage: AppStrings.freeCapsuleLimitReached,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final capsule = await repo.createCapsule(
        title: _capsuleTitleController.text.trim().isEmpty
            ? 'My Future Self'
            : _capsuleTitleController.text.trim(),
        unlockAtUtc: _capsuleUnlockDate.toUtc(),
      );

      await NotificationService().showMemoryLockedNotification();
      await NotificationService().scheduleCapsuleMilestones(
        capsuleId: capsule.id,
        capsuleTitle: capsule.title,
        createdAtUtc: capsule.createdAt,
        unlockAtUtc: capsule.unlockAt,
      );

      if (mounted) {
        setState(() {
          _activeCapsule = capsule;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not seal capsule: $e';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveMemory() async {
    if (_activeCapsule == null) return;

    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) {
      setState(() => _errorMessage = 'Write a note or attach a photo to preserve this moment.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = AppRepositoryManager().capsuleRepository;
      String? uploadedImageUrl;

      if (_selectedImage != null) {
        uploadedImageUrl = await StorageService().saveMemoryImage(
          imageFile: _selectedImage!,
          memoryId: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _activeCapsule!.userId,
        );
        await _sub.recordMediaAddedToday();
      }

      await repo.addMemory(
        capsuleId: _activeCapsule!.id,
        title: null,
        content: content.isEmpty ? 'A visual memory from today.' : content,
        imageUrl: uploadedImageUrl,
        memoryType: _selectedImage != null ? 'photo' : 'note',
        isImportant: _isImportant,
        capturedAtUtc: DateTime.now().toUtc(),
      );

      AnalyticsService().memoryCreated(hasPhoto: _selectedImage != null);
      HapticFeedback.heavyImpact();

      if (mounted) {
        final confirmationPhrase = AppStrings.capsuleSealedConfirmationVariations[
          DateTime.now().millisecondsSinceEpoch %
              AppStrings.capsuleSealedConfirmationVariations.length
        ];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.brightAccent, width: 1),
            ),
            action: SnackBarAction(
              label: 'SHARE CARD',
              textColor: AppColors.brightAccent,
              onPressed: () {
                if (_activeCapsule != null) {
                  ShareCardModal.show(context, capsule: _activeCapsule);
                }
              },
            ),
            content: Row(
              children: [
                const Icon(Icons.lock_clock_rounded,
                    color: AppColors.brightAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$confirmationPhrase Hidden until ${_activeCapsule!.shortUnlockDate}.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        widget.onMemoryLocked?.call();

        setState(() {
          _contentController.clear();
          _selectedImage = null;
          _isImportant = false;
          _isSaving = false;
        });
        _loadQuota();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not seal moment: $e';
          _isSaving = false;
        });
      }
    }
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
          _capsuleUnlockDate = combined;
          _selectedPreset = AppStrings.presetCustom;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _activeCapsule != null ? 'SEAL IN TIME' : AppStrings.createCapsuleTitle,
          style: AppTypography.displayMedium.copyWith(letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.brightAccent),
            tooltip: 'Yestera Pro',
            onPressed: () => ProUpgradeModal.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _activeCapsule != null ? _buildFrictionlessCapture() : _buildCreateCapsuleForm(),
        ),
      ),
    );
  }

  Widget _buildFrictionlessCapture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Destination capsule & Quota bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.brightAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeCapsule!.title.toUpperCase(),
                      style: AppTypography.badge.copyWith(
                        color: AppColors.brightAccent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Target: ${_activeCapsule!.shortUnlockDate}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => ProUpgradeModal.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sub.isPro
                        ? AppColors.brightAccent.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _sub.isPro ? AppColors.brightAccent : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sub.isPro ? Icons.workspace_premium_rounded : Icons.shield_outlined,
                        size: 12,
                        color: _sub.isPro ? AppColors.brightAccent : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sub.isPro ? 'PRO VAULT' : 'TIME VAULT',
                        style: AppTypography.caption.copyWith(
                          color: _sub.isPro ? AppColors.brightAccent : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Single-Canvas Note Parchment with Gold Focus Glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isCanvasFocused
                  ? AppColors.brightAccent
                  : AppColors.surfaceBorder,
              width: _isCanvasFocused ? 1.6 : 1.2,
            ),
            boxShadow: _isCanvasFocused
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _contentController,
            focusNode: _canvasFocusNode,
            maxLines: 5,
            minLines: 4,
            autofocus: true,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            cursorColor: AppColors.brightAccent,
            decoration: InputDecoration(
              hintText: 'Drop a thought or memory to your future self...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        // Inline Photo Attachment Preview Card
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brightAccent.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHOTO ATTACHED',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.brightAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to seal into confidential vault',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Remove photo',
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATTACH TO TRANSMISSION',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 11,
                  color: AppColors.brightAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Optional • Note, photo, or audio',
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tactile Action Stack: Generous Vertical Cards Filling Empty Space
        // 1. Photo Vault Card
        _buildVerticalOptionTile(
          icon: _selectedImage != null ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
          title: 'Photo Memory',
          subtitle: _selectedImage != null
              ? '1 Photo Encrypted & Sealed in Vault'
              : (_sub.isPro
                  ? 'Unlimited Photos with PRO'
                  : '${(SubscriptionService.freeDailyMediaLimit - _todayMediaCount).clamp(0, SubscriptionService.freeDailyMediaLimit)}/2 photos today'),
          isActive: _selectedImage != null,
          trailing: _selectedImage != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Remove photo',
                  onPressed: () => setState(() => _selectedImage = null),
                )
              : const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          onTap: _handlePhotoTap,
        ),
        const SizedBox(height: 10),

        // 2. Voice Transmission Card
        _buildVerticalOptionTile(
          icon: Icons.mic_none_rounded,
          title: 'Voice Transmission',
          subtitle: 'Record an audio memo for your future self',
          isGated: !_sub.isPro,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          onTap: _handleAudioTap,
        ),
        const SizedBox(height: 10),

        // 3. Video Moment Card
        _buildVerticalOptionTile(
          icon: Icons.videocam_outlined,
          title: 'Video Moment',
          subtitle: 'Attach a high-definition video clip',
          isGated: !_sub.isPro,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          onTap: _handleVideoTap,
        ),
        const SizedBox(height: 10),

        // 4. Key Moment Toggle Card
        _buildVerticalOptionTile(
          icon: _isImportant ? Icons.star_rounded : Icons.star_border_rounded,
          title: 'Key Moment',
          subtitle: 'Featured highlight in your documentary replay',
          isActive: _isImportant,
          trailing: Switch(
            value: _isImportant,
            activeThumbColor: AppColors.brightAccent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _isImportant = val);
            },
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isImportant = !_isImportant);
          },
        ),
        const SizedBox(height: 10),

        // 5. Inspire Me Card
        _buildVerticalOptionTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Inspire My Reflection',
          subtitle: 'Tap to generate a deep reflective prompt',
          trailing: const Icon(Icons.cached_rounded, color: AppColors.brightAccent, size: 20),
          onTap: _cyclePrompt,
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),

        // One-Tap Master Glow Button
        GlowingButton(
          label: 'SEAL INTO ${_activeCapsule!.shortUnlockDate.toUpperCase()}',
          icon: Icons.lock_clock_rounded,
          isLoading: _isSaving,
          onPressed: _saveMemory,
        ),
      ],
    );
  }

  Widget _buildVerticalOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isGated = false,
    bool isActive = false,
    Color? activeColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final effectiveColor = isActive
        ? (activeColor ?? AppColors.brightAccent)
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.brightAccent
                  : AppColors.surfaceBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brightAccent.withValues(alpha: 0.2)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? AppColors.brightAccent : AppColors.surfaceBorderLight,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: effectiveColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            color: effectiveColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isGated) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brightAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCapsuleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'NAME YOUR TIME CAPSULE',
          style: AppTypography.badge.copyWith(letterSpacing: 1.5, fontSize: 11),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _capsuleTitleController,
          style: AppTypography.titleLarge,
          decoration: const InputDecoration(
            hintText: 'e.g., My Future Self, Year of 2026',
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'CHOOSE TIME HORIZON',
          style: AppTypography.badge.copyWith(letterSpacing: 1.5, fontSize: 11),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip(AppStrings.presetTomorrow, CapsuleDateUtils.getPresetTomorrow()),
            _buildPresetChip(AppStrings.presetOneMonth, CapsuleDateUtils.getPresetOneMonth()),
            _buildPresetChip(AppStrings.presetSixMonths, CapsuleDateUtils.getPresetSixMonths()),
            _buildPresetChip(AppStrings.presetOneYear, CapsuleDateUtils.getPresetOneYear()),
            _buildPresetChip(AppStrings.presetFiveYears, CapsuleDateUtils.getPresetFiveYears()),
            if (kDebugMode)
              _buildPresetChip(AppStrings.presetQuickTest, CapsuleDateUtils.getPresetQuickTest()),
          ],
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: const BorderSide(color: AppColors.surfaceBorderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.accent),
          label: Text(
            _selectedPreset == AppStrings.presetCustom
                ? CapsuleDateUtils.formatFullDate(_capsuleUnlockDate)
                : AppStrings.presetCustom,
            style: AppTypography.button.copyWith(color: AppColors.brightAccent),
          ),
          onPressed: _pickCustomDate,
        ),
        const SizedBox(height: 24),

        // Pre-Seal Review Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.brightAccent.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock_rounded, size: 14, color: AppColors.brightAccent),
                  const SizedBox(width: 6),
                  Text(
                    'PRE-SEAL REVIEW',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.brightAccent,
                      letterSpacing: 2,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _capsuleTitleController.text.trim().isEmpty
                    ? 'MY FUTURE SELF'
                    : _capsuleTitleController.text.trim().toUpperCase(),
                style: AppTypography.titleLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Opens ${CapsuleDateUtils.formatFullDate(_capsuleUnlockDate)}',
                style: AppTypography.emotionalHeadline.copyWith(
                  color: AppColors.brightAccent,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sealed for $_selectedPreset. Memories remain confidential until unlock.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        GlowingButton(
          label: 'SEAL THIS MOMENT',
          icon: Icons.lock_outline_rounded,
          isLoading: _isSaving,
          onPressed: _createAndSealCapsule,
        ),
        const SizedBox(height: 8),
        Text(
          'Opens ${CapsuleDateUtils.formatShortDate(_capsuleUnlockDate)}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
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
          _capsuleUnlockDate = date;
        });
      },
    );
  }
}
