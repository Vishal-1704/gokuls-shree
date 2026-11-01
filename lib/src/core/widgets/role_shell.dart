import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/navigation/back_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../core/models/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROLE SHELL WIDGET — shared bottom nav bar with role-specific tabs
// ─────────────────────────────────────────────────────────────────────────────
class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({
    super.key,
    required this.shell,
    required this.role,
    required this.tabs,
  });

  final StatefulNavigationShell shell;
  final UserRole role;
  final List<GButton> tabs;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    // Point the global singleton at our handler.
    // Even if this widget is disposed and recreated, the singleton stays alive.
    BackHandler.instance.handler = _handleBack;
    debugPrint('🔵 RoleShell mounted — handler set (tab=${widget.shell.currentIndex})');
  }

  @override
  void dispose() {
    // Only clear if WE are still the active handler (not a newer shell instance).
    if (BackHandler.instance.handler == _handleBack) {
      BackHandler.instance.handler = null;
      debugPrint('🔵 RoleShell disposed — handler cleared');
    }
    super.dispose();
  }

  /// Called by BackHandler.didPopRoute() when the Android back button fires.
  Future<bool> _handleBack() async {
    debugPrint('🟡 _handleBack — tab=${widget.shell.currentIndex}');

    // 1. If GoRouter has a nested screen to pop, pop it
    if (GoRouter.of(context).canPop()) {
      debugPrint('🟢 Popping inner screen');
      GoRouter.of(context).pop();
      return true;
    }

    // 2. Not on home tab → go to home tab
    if (widget.shell.currentIndex != 0) {
      debugPrint('🟢 Going to home tab from tab ${widget.shell.currentIndex}');
      widget.shell.goBranch(0, initialLocation: false);
      return true;
    }

    // 3. On home tab — double-back to exit
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      debugPrint('🟠 First back on home — showing snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    }

    debugPrint('🔴 Second back — exiting app');
    return false; // let system exit
  }

  void _go(int index) {
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  Color get _navBg => AppColors.inkNavy800;
  Color get _activeColor => AppColors.goldCta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: _navBg,
                  selectedIndex: widget.shell.currentIndex,
                  onDestinationSelected: _go,
                  extended: constraints.maxWidth > 1000,
                  unselectedIconTheme: const IconThemeData(color: AppColors.textMuted, opacity: 1),
                  selectedIconTheme: IconThemeData(color: _activeColor, opacity: 1),
                  unselectedLabelTextStyle: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                  selectedLabelTextStyle: AppTypography.labelMd.copyWith(color: _activeColor),
                  indicatorColor: _activeColor.withOpacity(0.1),
                  destinations: widget.tabs.map((tab) {
                    return NavigationRailDestination(
                      icon: Icon(tab.icon),
                      label: Text(tab.text),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.divider10),
                Expanded(child: widget.shell),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: widget.shell,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: _navBg,
                border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: GNav(
                    gap: 6,
                    iconSize: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    duration: const Duration(milliseconds: 250),
                    tabBackgroundColor: _activeColor,
                    activeColor: AppColors.textPrimary,
                    color: AppColors.textMuted,
                    tabs: widget.tabs,
                    selectedIndex: widget.shell.currentIndex,
                    onTabChange: _go,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
