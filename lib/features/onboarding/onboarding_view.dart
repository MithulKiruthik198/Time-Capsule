import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glowing_button.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<({String title, String subtitle, IconData icon})> _slides = [
    (
      title: AppStrings.onboarding1Title,
      subtitle: AppStrings.onboarding1Subtitle,
      icon: Icons.hourglass_top_rounded,
    ),
    (
      title: AppStrings.onboarding2Title,
      subtitle: AppStrings.onboarding2Subtitle,
      icon: Icons.lock_clock_rounded,
    ),
    (
      title: AppStrings.onboarding3Title,
      subtitle: '“${AppStrings.conceptStatement}”',
      icon: Icons.flight_takeoff_rounded,
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    AnalyticsService().onboardingCompleted();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              // Top progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.accent
                          : AppColors.surfaceBorderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Page Carousel
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.surfaceBorderLight),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                blurRadius: 40,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide.icon,
                              size: 46,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 44),
                        Text(
                          slide.title,
                          style: AppTypography.displayLarge.copyWith(fontSize: 34),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.subtitle,
                          style: AppTypography.emotionalHeadline.copyWith(
                            fontSize: 22,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),

              // Bottom CTA
              if (_currentPage == _slides.length - 1)
                GlowingButton(
                  label: AppStrings.onboarding3Cta,
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: _finishOnboarding,
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GlowingButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
