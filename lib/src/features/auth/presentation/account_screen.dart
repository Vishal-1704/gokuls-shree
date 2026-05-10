import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(supabaseAuthProvider);
    final userRole = ref.watch(userRoleProvider) ?? 'student';
    final isStudent = userRole == 'student';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref, authState, userRole),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authState is AuthAuthenticated) ...[
                    _buildSectionHeader('Profile Information'),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: authState.user.email ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    if (isStudent)
                      _buildInfoCard(
                        icon: Icons.badge_outlined,
                        label: 'Registration Number',
                        value: authState.studentData?['reg_no'] ?? 'Pending',
                      ),
                    const SizedBox(height: 24),
                  ],
                  
                  _buildSectionHeader('App Settings'),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage alerts and updates',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.security_rounded,
                    title: 'Security',
                    subtitle: 'Password and biometric login',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English (US)',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Support & Legal'),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'FAQs and support chat',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About App',
                    subtitle: 'Version 2.0.4 (Hardened)',
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, SupabaseAuthState state, String role) {
    String name = 'User';
    String sub = role.replaceAll('_', ' ').toUpperCase();
    
    if (state is AuthAuthenticated) {
      name = state.user.userMetadata?['name'] ?? state.user.email?.split('@')[0] ?? 'User';
    }

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.inkNavy800,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF1E293B), AppColors.inkNavy900],
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              right: -50,
              top: -20,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: AppColors.goldCta.withOpacity(0.03),
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile-pic',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldCta, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.inkNavy700,
                      child: Text(
                        name[0].toUpperCase(),
                        style: AppTypography.displayLg.copyWith(color: AppColors.goldCta),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: AppTypography.headingLg),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldCta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.goldCta,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headingSm.copyWith(
        color: AppColors.goldCta,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.inkNavy800,
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(supabaseAuthNotifierProvider).signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: Text(
          'Sign Out of Account',
          style: AppTypography.bodyLg.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.danger.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
