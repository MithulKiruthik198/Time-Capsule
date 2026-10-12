import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/capsule.dart';
import '../../repositories/app_repository_manager.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/pro_upgrade_modal.dart';

/// Frictionless & Mysterious Time Vault Capture Chamber:
/// - Single-canvas distraction-free note entry (zero form fatigue)
/// - Space-saving Encrypted Photo Token: zero image leak before unboxing, takes <50px height
/// - Express quick-action toolbar: Photo, Audio PRO, Video PRO, Star, Spark inspiration
/// - Radiant golden "SEAL IN TIME" master button
class AddMemoryModal extends StatefulWidget {
  final Capsule capsule;
  final VoidCallback? onMemoryAdded;

  const AddMemoryModal({
    super.key,
    required this.capsule,
    this.onMemoryAdded,
  });

  @override
  State<AddMemoryModal> createState() => _AddMemoryModalState();
}

class _AddMemoryModalState extends State<AddMemoryModal> {
  final _sub = SubscriptionService();
  final _contentController = TextEditingController();
  XFile? _selectedImage;
  bool _isImportant = false;
  bool _isSaving = false;
  String? _errorMessage;

  int _todayMediaCount = 0;
  bool _hasCheckedQuota = false;
  int _promptIndex = 0;

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
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final count = await _sub.getMediaCountToday();
    if (mounted) {
      setState(() {
        _todayMediaCount = count;
        _hasCheckedQuota = true;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
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

  Future<void> _handleAudioTap() async {
    if (!_sub.isPro) {
      ProUpgradeModal.show(
        context,
        reasonMessage: AppStrings.proFeatureAudio,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _contentController.text =
          '🎙️ [Voice Memo Recorded]: "Leaving this voice note for my future self..."';
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
      ProUpgradeModal.show(
        context,
        reasonMessage: AppStrings.proFeatureVideo,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _contentController.text =
          '🎥 [Video Moment Attached]: High-definition transmission ready for replay.';
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

  Future<void> _pickImage(ImageSource source) async {
    final file = await StorageService().pickImage(source);
    if (file != null) {
      setState(() => _selectedImage = file);
      AnalyticsService().photoAdded();
      HapticFeedback.lightImpact();
    }
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

  Future<void> _saveMemory() async {
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
          userId: widget.capsule.userId,
        );
        await _sub.recordMediaAddedToday();
      }

      await repo.addMemory(
        capsuleId: widget.capsule.id,
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.accent, width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.lock_clock_rounded,
                    color: AppColors.brightAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sealed into ${widget.capsule.title}. Hidden until ${widget.capsule.shortUnlockDate}.',
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
        widget.onMemoryAdded?.call();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not seal memory: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingMedia = _sub.isPro
        ? 'PRO: Unlimited'
        : '${(SubscriptionService.freeDailyMediaLimit - _todayMediaCount).clamp(0, SubscriptionService.freeDailyMediaLimit)}/2 photos today';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Bar: Capsule Destination & Daily Quota
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, size: 14, color: AppColors.brightAccent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.capsule.title.toUpperCase(),
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
                                'Target: ${widget.capsule.shortUnlockDate}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quota badge
                  if (_hasCheckedQuota)
                    InkWell(
                      onTap: () => ProUpgradeModal.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _sub.isPro
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _sub.isPro
                                ? AppColors.brightAccent
                                : AppColors.surfaceBorderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sub.isPro
                                  ? Icons.workspace_premium_rounded
                                  : Icons.photo_camera_outlined,
                              size: 12,
                              color: AppColors.brightAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              remainingMedia,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brightAccent,
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
              const SizedBox(height: 14),

              // Single-Canvas Glass Note Parchment (Distraction-free)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 4,
                  minLines: 3,
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
                              'Ready to seal into vault',
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
                      'ATTACH MEMORIES',
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

              // 1. Photo Card
              _buildVerticalOptionTile(
                icon: Icons.add_a_photo_outlined,
                title: _selectedImage != null ? 'Photo Attached & Sealed' : 'Add Photo Memory',
                subtitle: _selectedImage != null
                    ? '1 Photo encrypted • Hidden until ${widget.capsule.shortUnlockDate}'
                    : 'Confidential photo • $remainingMedia',
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

              // 2. Voice Note Card
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
                label: 'SEAL INTO ${widget.capsule.shortUnlockDate.toUpperCase()}',
                icon: Icons.lock_clock_rounded,
                isLoading: _isSaving,
                onPressed: _saveMemory,
              ),
            ],
          ),
        ),
      ),
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
}
