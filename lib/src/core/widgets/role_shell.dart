import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
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
  final List<int> _history = [0];

  void _go(int index) {
    setState(() => _history.add(index));
    widget.shell.goBranch(index,
        initialLocation: index == widget.shell.currentIndex);
  }

  void _onPop(bool didPop) {
    if (didPop) return;
    if (_history.length > 1) {
      _history.removeLast();
      setState(() {});
      widget.shell.goBranch(_history.last, initialLocation: false);
      return;
    }
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  // Nav bar color per role
  Color get _navBg {
    switch (widget.role) {
      case UserRole.superAdmin:  return AppColors.inkNavy800; // deep purple
      case UserRole.branchAdmin: return AppColors.inkNavy800; // deep blue
      case UserRole.teacher:     return AppColors.inkNavy800; // deep green
      default:                   return AppColors.inkNavy800; // ink navy (student)
    }
  }

  Color get _activeColor => AppColors.goldCta; // gold CTA — same for all roles

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onPop,
      child: LayoutBuilder(
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
      ),
    );
  }
}
