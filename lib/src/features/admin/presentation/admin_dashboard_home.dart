import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_notices_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_staff_directory_screen.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';

class AdminDashboardHome extends ConsumerStatefulWidget {
  const AdminDashboardHome({super.key});

  @override
  ConsumerState<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends ConsumerState<AdminDashboardHome> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final repo = ref.read(adminRepositoryProvider);
    _statsFuture = repo.getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider) ?? 'branch_admin';
    final isSuperAdmin = role == 'super_admin';
    final roleLabel = isSuperAdmin ? 'Super Admin' : 'Branch Admin';
    final roleAccent = isSuperAdmin ? AppColors.info : AppColors.goldCta;
    final roleCode = isSuperAdmin ? 'HQ' : 'BR-012';
    final roleAvatarText = isSuperAdmin ? 'S' : 'A';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: RefreshIndicator(
        color: AppColors.goldCta,
        backgroundColor: AppColors.inkNavy800,
        onRefresh: () async {
          setState(() => _refreshData());
        },
        child: CustomScrollView(
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFormattedDate(),
                            style: AppTypography.labelMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, $roleLabel',
                            style: AppTypography.headingLg,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: roleAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: roleAccent.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSuperAdmin ? Icons.shield : Icons.domain,
                                size: 16,
                                color: roleAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                roleCode,
                                style: AppTypography.labelLg.copyWith(
                                  color: roleAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Franchise Setup Banner (If missing branch_id) ───
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: ref.read(adminRepositoryProvider).getMyBranch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SizedBox.shrink();

                  final hasBranch = snapshot.data != null;
                  if (hasBranch) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.orange),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Setup Required',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Please complete your franchise details to start.',
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/admin/franchise-setup'),
                            child: const Text(
                              'SETUP NOW',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Stats Section (Vibrant Control Panel) ───
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.goldCta,
                        ),
                      ),
                    );
                  }

                  final stats = snapshot.data ?? {};

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Control panel', style: AppTypography.headingSm),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) / 2,
                              child: _buildVibrantTile(
                                value: '${stats['total_students'] ?? 0}',
                                label: 'TOTAL STUDENTS',
                                icon: Icons.group,
                                color: const Color(0xFFF34C68), // Pinkish red
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) / 2,
                              child: _buildVibrantTile(
                                value: '${stats['present_students'] ?? 0}',
                                label: 'PRESENT TODAY',
                                icon: Icons.how_to_reg,
                                color: const Color(0xFF3498DB), // Blue
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) / 2,
                              child: _buildVibrantTile(
                                value: '₹${stats['todays_collection'] ?? 0}',
                                label: 'FEES TODAY',
                                icon: Icons.currency_rupee,
                                color: const Color(0xFF27AE60), // Green
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 60) / 2,
                              child: _buildVibrantTile(
                                value: '${stats['pending_enquiries'] ?? 0}',
                                label: 'ENQUIRIES',
                                icon: Icons.help_outline,
                                color: const Color(0xFFF39C12), // Orange
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── Quick Actions ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: AppTypography.headingSm),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.campaign,
                            label: 'Notices',
                            color: AppColors.goldCta,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminNoticesScreen(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.badge,
                            label: 'Staff',
                            color: AppColors.info,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminStaffDirectoryScreen(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.fact_check_outlined,
                            label: 'Results Entry',
                            color: const Color(0xFF7C3AED),
                            onTap: () => context.push('/admin/results-entry'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'Add Student',
                            color: AppColors.success,
                            onTap: () => context.push('/admin/add-student'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.request_quote_outlined,
                            label: 'Dues Report',
                            color: AppColors.warning,
                            onTap: () => context.push('/admin/dues-report'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.event_note_outlined,
                            label: 'Exam Scheduler',
                            color: const Color(0xFF2563EB),
                            onTap: () => context.push('/admin/exam-scheduler'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'Marksheet',
                            color: AppColors.info,
                            onTap: () =>
                                context.push('/admin/marksheet-generator'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.upload_file_outlined,
                            label: 'Materials',
                            color: const Color(0xFF0F766E),
                            onTap: () => context.push('/admin/study-material'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.qr_code_2_outlined,
                            label: 'Attendance',
                            color: const Color(0xFFDB2777),
                            onTap: () => context.push('/admin/attendance'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.receipt_long_outlined,
                            label: 'Payslip',
                            color: const Color(0xFF0D9488),
                            onTap: () => context.push('/admin/payslip-generator'),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: _buildQuickAction(
                            icon: Icons.trending_up_outlined,
                            label: 'Propose Salary',
                            color: const Color(0xFF6D28D9),
                            onTap: () => context.push('/admin/propose-salary'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ─── Primary Card: Fee Collection ───

  // ─── Primary Card: Student Attendance ───
  Widget _buildVibrantTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: 10,
            child: Icon(icon, size: 70, color: Colors.black.withOpacity(0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'More info ',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Icon(Icons.arrow_circle_right, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard(Map<String, dynamic> stats) {
    final List<dynamic> courseAttendance = stats['course_attendance'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Student Attendance (Course-wise)',
                style: AppTypography.headingSm,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (courseAttendance.isEmpty)
            Text(
              'No attendance data available for today.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courseAttendance.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: AppColors.divider.withOpacity(0.2),
                  height: 1,
                ),
              ),
              itemBuilder: (context, index) {
                final course = courseAttendance[index] as Map<String, dynamic>;
                final name = course['course_name'] ?? 'Unknown';
                final present = course['present'] ?? 0;
                final total = course['total'] ?? 0;
                final rate = course['rate'] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.labelMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$present / $total Present',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rate >= 75
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$rate%',
                        style: AppTypography.labelMd.copyWith(
                          color: rate >= 75
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Secondary Card ───
  Widget _buildSecondaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subValue,
    required String footerText,
    required Color footerColor,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (showBadge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelMd),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTypography.headingMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subValue.isNotEmpty)
                    Flexible(
                      child: Text(
                        subValue,
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                footerText,
                style: AppTypography.labelMd.copyWith(
                  color: footerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Quick Action Button ───
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.inkNavy800,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.3)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelLg.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Activity Item ───
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Builder(
              builder: (context) {
                final avatar = resolveAvatarProvider(activity['photo_url']);
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.inkNavy700,
                  backgroundImage: avatar,
                  onBackgroundImageError: avatar != null ? (_, __) {} : null,
                  child: avatar == null
                      ? const Icon(Icons.person, color: AppColors.textSecondary)
                      : null,
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['name'],
                    style: AppTypography.headingSm.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activity['class']} • ${activity['type']}',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ₹ ${activity['amount']}',
                  style: AppTypography.headingSm.copyWith(
                    color: AppColors.success,
                    fontSize: 15,
                  ),
                ),
                Text(activity['time'], style: AppTypography.labelMd),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }
}
