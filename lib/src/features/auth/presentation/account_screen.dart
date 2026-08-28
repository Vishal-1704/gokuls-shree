import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/features/teacher/presentation/widgets/teacher_employment_details.dart';
import 'package:gokul_shree_app/src/features/teacher/data/attendance_repository.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                    if (isStudent) ...[
                      _buildInfoCard(
                        icon: Icons.school_outlined,
                        label: 'Course',
                        value: authState.studentData?['course'] ?? 'Pending',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.class_outlined,
                              label: 'Class/Section',
                              value: authState.studentData?['class_section'] ?? 'N/A',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.badge_outlined,
                              label: 'Reg. Number',
                              value: authState.studentData?['reg_no'] ?? 'Pending',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isStudent) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Financial Overview'),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final feeAsync = ref.watch(studentFeeStatusProvider);
                          return feeAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
                            error: (e, _) => Text('Error loading fees: $e', style: const TextStyle(color: AppColors.danger)),
                            data: (fees) {
                              final totalPaid = fees
                                  .where((f) => f['status'] == 'paid')
                                  .fold<num>(0, (sum, item) => sum + (item['amount'] as num));
                              final totalPending = fees
                                  .where((f) => f['status'] != 'paid')
                                  .fold<num>(0, (sum, item) => sum + (item['amount'] as num));
                              
                              // Mocking course fee / tuition fee breakdown based on totals
                              final totalCourseFee = totalPaid + totalPending;

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildFinancialStat('Total Paid', '₹$totalPaid', AppColors.success)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildFinancialStat('Total Overdue', '₹$totalPending', AppColors.warning)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    icon: Icons.receipt_long_rounded,
                                    title: 'Detailed Fee Status',
                                    subtitle: 'Total Course Fee: ₹$totalCourseFee',
                                    onTap: () => context.push('/fee-status'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],

                  const SizedBox(height: 40),
                  
                    if (userRole == 'teacher') ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Employment Details'),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final empAsync = ref.watch(teacherEmployeeProfileProvider);
                          return empAsync.when(
                            data: (emp) => Container(
                              decoration: BoxDecoration(
                                color: AppColors.inkNavy800,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.divider.withOpacity(0.2)),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.inkNavy700,
                                  child: Icon(Icons.work_outline_rounded, color: AppColors.goldCta),
                                ),
                                title: const Text('View Employment Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Salary, attendance, and department info', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                                onTap: () => context.push('/teacher/employment-details', extra: emp),
                              ),
                            ),
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
                            error: (e, _) => Text('Error loading profile: ', style: const TextStyle(color: AppColors.danger)),
                          );
                        },
                      ),
                    ],
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
      actions: [
        if (state is AuthAuthenticated && role == 'student')
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: AppColors.textPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.inkNavy800,
                  title: const Text('Digital Profile QR', style: TextStyle(color: AppColors.textPrimary)),
                  content: Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: QrImageView(
                      data: 'STU-${state.user.id}',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.goldCta)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
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
                  colors: [AppColors.inkNavy700, AppColors.inkNavy900],
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    name,
                    style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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

  Widget _buildFinancialStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headingMd.copyWith(color: color)),
        ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
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
              title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
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
