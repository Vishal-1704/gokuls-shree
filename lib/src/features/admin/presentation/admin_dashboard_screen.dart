import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_panel_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_dashboard_home.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_qr_scanner_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_student_directory_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AdminDashboardHome(),
    AdminStudentDirectoryScreen(),
    AdminQRScannerScreen(),
    AdminPanelScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: AppColors.goldCta.withOpacity(0.1),
            hoverColor: AppColors.goldCta.withOpacity(0.05),
            gap: 8,
            activeColor: AppColors.inkNavy900,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: AppColors.goldCta,
            color: AppColors.textSecondary,
            tabs: const [
              GButton(icon: Icons.dashboard_rounded, text: 'Home'),
              GButton(icon: Icons.people_alt_rounded, text: 'Students'),
              GButton(icon: Icons.qr_code_scanner_rounded, text: 'Scan'),
              GButton(icon: Icons.grid_view_rounded, text: 'Menu'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
