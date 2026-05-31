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
    _activitiesFuture = repo.getRecentActivity();
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminProfileScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: roleAccent,
                            child: Text(
                              roleAvatarText,
                              style: TextStyle(
                                color: AppColors.inkNavy900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                  if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                  
                  final hasBranch = snapshot.data != null;
                  if (hasBranch) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Please complete your franchise details to start.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/admin/franchise-setup'),
                            child: const Text('SETUP NOW', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Stats Section ───
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
                      children: [
                        _buildPrimaryCard(stats),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSecondaryCard(
                                icon: Icons.groups,
                                iconColor: AppColors.info,
                                label: 'Present Students',
                                value: '${stats['present_students']}',
                                subValue: '/${stats['total_students']}',
                                footerText: '${stats['attendance_rate']}% Rate',
                                footerColor: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSecondaryCard(
                                icon: Icons.assignment_late,
                                iconColor: AppColors.warning,
                                label: 'Pending Enquiries',
                                value: '${stats['pending_enquiries']} New',
                                subValue: '',
                                footerText: 'Action Req.',
                                footerColor: AppColors.warning,
                                showBadge: true,
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.campaign,
                            label: 'Notices',
                            color: AppColors.goldCta,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminNoticesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.badge,
                            label: 'Staff',
                            color: AppColors.info,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminStaffDirectoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildQuickAction(
                        icon: Icons.fact_check_outlined,
                        label: 'Results Entry',
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/admin/results-entry'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'Add Student',
                            color: AppColors.success,
                            onTap: () => context.push('/admin/add-student'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.request_quote_outlined,
                            label: 'Dues Report',
                            color: AppColors.warning,
                            onTap: () => context.push('/admin/dues-report'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildQuickAction(
                        icon: Icons.event_note_outlined,
                        label: 'Exam Scheduler',
                        color: const Color(0xFF2563EB),
                        onTap: () => context.push('/admin/exam-scheduler'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'Marksheet',
                            color: AppColors.info,
                            onTap: () =>
                                context.push('/admin/marksheet-generator'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.upload_file_outlined,
                            label: 'Materials',
                            color: const Color(0xFF0F766E),
                            onTap: () => context.push('/admin/study-material'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Recent Transactions Header ───
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: AppTypography.headingSm,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.goldCta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Recent Activity List ───
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.inkNavy800,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _activitiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: AppColors.goldCta,
                          ),
                        ),
                      );
                    }

                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return Center(
                        child: Text(
                          "No recent activity",
                          style: AppTypography.bodyMd,
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => Divider(
                        color: AppColors.divider.withOpacity(0.35),
                        height: 1,
                      ),
                      itemBuilder: (context, index) =>
                          _buildActivityItem(activities[index]),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ─── Primary Card: Fee Collection ───
  Widget _buildPrimaryCard(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldCta, Color(0xFFA67B00)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldCta.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: AppColors.inkNavy900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: AppColors.inkNavy900,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats['collection_growth']}%',
                          style: AppTypography.labelLg.copyWith(
                            color: AppColors.inkNavy900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Today's Collection",
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.inkNavy900.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹ ${stats['todays_collection']}',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.inkNavy900,
                  fontSize: 32,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Progress Bar
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inkNavy900.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy900,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
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
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.inkNavy700,
              backgroundImage: NetworkImage(activity['photo_url']),
              onBackgroundImageError: (_, __) => const Icon(Icons.person),
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
