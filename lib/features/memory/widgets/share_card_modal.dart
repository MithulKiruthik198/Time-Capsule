import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/capsule.dart';
import '../../../models/memory.dart';
import '../../../widgets/glowing_button.dart';

class ShareCardModal extends StatefulWidget {
  final Memory? memory;
  final Capsule? capsule;

  const ShareCardModal({
    super.key,
    this.memory,
    this.capsule,
  });

  static Future<void> show(
    BuildContext context, {
    Memory? memory,
    Capsule? capsule,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardModal(memory: memory, capsule: capsule),
    );
  }

  @override
  State<ShareCardModal> createState() => _ShareCardModalState();
}

class _ShareCardModalState extends State<ShareCardModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  String get _unlockDateText {
    if (widget.capsule != null) {
      return 'Opens ${widget.capsule!.formattedUnlockDate}';
    }
    if (widget.memory != null) {
      final approxUnlock = widget.memory!.createdAt.add(const Duration(days: 365));
      return 'Opens ${CapsuleDateUtils.formatFullDate(approxUnlock)}';
    }
    return 'Opens in the future';
  }

  String get _sealDateText {
    if (widget.capsule != null) {
      final now = DateTime.now().toUtc();
      final diff = now.difference(widget.capsule!.createdAt).inDays.abs();
      if (diff < 1) {
        return AppStrings.shareCardStatusSealed;
      }
      return 'SEALED ${widget.capsule!.formattedCreatedDate.toUpperCase()}';
    }
    return AppStrings.shareCardStatusSealed;
  }

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final shareText = 'I left something for my future self on YESTERA.\n$_unlockDateText.\n\n#Yestera #TimeCapsule';

      if (kIsWeb) {
        // ignore: deprecated_member_use
        await Share.share(shareText);
      } else {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = await File('${tempDir.path}/yestera_keepsake_$timestamp.png').create();
        await file.writeAsBytes(bytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
      }
    } catch (e) {
      debugPrint('[ShareCard] Share failed: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Keepsake Card',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Private by design — only your time journey is shared.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Archival Share Card (Privacy-Safe Artifact)
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.4),
                      radius: 1.1,
                      colors: [
                        Color(0xFF1B1914),
                        Color(0xFF11100D),
                        Color(0xFF08090D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Badge: SEALED TODAY / SEALED DATE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                              _sealDateText,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.brightAccent,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Central Sacred Time Emblem (Vault / Hourglass)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentSubtle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.25),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.hourglass_top_rounded,
                            size: 38,
                            color: AppColors.brightAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Core Emotional Headline (Large typography)
                      Text(
                        '“${AppStrings.shareCardAuthor}”',
                        style: AppTypography.emotionalHeadline.copyWith(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // Unlock Date Headline
                      Text(
                        _unlockDateText,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.brightAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Luxury Ornamental Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.accent.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 14,
                              color: AppColors.accent.withValues(alpha: 0.7),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Emotional Reflection Sentence
                      Text(
                        AppStrings.shareCardReflection,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // App Branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.shareCardBrandTitle,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: AppColors.accent.withValues(alpha: 0.6)),
                          ),
                          Text(
                            AppStrings.shareCardBrandTagline,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 1.6,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              GlowingButton(
                label: 'Share Keepsake Card',
                icon: Icons.ios_share_rounded,
                isLoading: _isSharing,
                onPressed: _shareImage,
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
