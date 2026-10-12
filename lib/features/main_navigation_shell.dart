import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'capture/capture_view.dart';
import 'home/home_view.dart';
import 'settings/settings_view.dart';
import 'timeline/timeline_view.dart';

class MainNavigationShell extends StatefulWidget {
  final VoidCallback onSignOut;

  const MainNavigationShell({super.key, required this.onSignOut});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToCapture() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureView(
          onMemoryLocked: () {
            setState(() => _currentIndex = 0); // Navigate to Home
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeView(onNavigateToCapture: _navigateToCapture),
      const SizedBox.shrink(), // Index 1 is Capture (action tab)
      TimelineView(onNavigateToCapture: _navigateToCapture),
      SettingsView(onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex == 1 ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          onTap: (index) {
            if (index == 1) {
              _navigateToCapture();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded, size: 28),
              activeIcon: Icon(Icons.add_circle_rounded, size: 28),
              label: 'Capture',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline_rounded),
              activeIcon: Icon(Icons.timeline_rounded),
              label: 'Timeline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
