import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/features/student/presentation/widgets/digital_id_card.dart';
import 'package:gokul_shree_app/src/features/student/presentation/widgets/student_notice_board.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/widgets/responsive_container.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/services/update_service.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);

      // The session's "pending approval" flag is a snapshot from whenever
      // the profile was last loaded (often right after a legacy-claim
      // registration, sometimes before the claim's status=1 update had
      // fully landed) — it never re-checks itself otherwise, so a genuinely
      // already-approved account could keep showing a stale pending banner
      // until a full logout/login. One quiet re-check on dashboard mount
      // self-heals that without needing a manual re-login.
      if (!(ref.read(sessionProvider)?.isApproved ?? true)) {
        ref.read(supabaseAuthNotifierProvider).refreshProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(studentRepositoryProvider);
    final profileAsync = ref.watch(studentProfileProvider);
    final isApproved = ref.watch(sessionProvider)?.isApproved ?? false;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentProfileProvider);
              ref.invalidate(studentAttendanceStatsProvider);
              ref.invalidate(studentFeeSnapshotProvider);
              ref.invalidate(studentAcademicCalendarProvider);
            },
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: profileAsync.when(
                      loading: () => _buildLoading(),
                      error: (err, stack) => Center(
                        child: Text(
                          'Error loading profile: $err',
                          style: AppTypography.bodySm.copyWith(color: Colors.redAccent),
                        ),
                      ),
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isApproved)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your account is pending approval by an admin. Some features may not be available.',
                                      style: AppTypography.bodySm.copyWith(color: AppColors.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          DigitalIDCard(data: profile),
                          const SizedBox(height: 32),
                          
                          _buildSectionTitle('Quick Actions'),
                          const SizedBox(height: 16),
                          _buildQuickActionsGrid(context, ref),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.inkNavy900,
      floating: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(EnvConfig.shortName.toUpperCase(), style: AppTypography.labelMd.copyWith(color: AppColors.goldCta, letterSpacing: 2)),
          Text('Student Dashboard', style: AppTypography.headingSm),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsProvider);
    final lastResultSubtitle = resultsAsync.maybeWhen(
      data: (rows) {
        if (rows.isEmpty) return 'No results yet';
        final latest = rows.first;
        final score = (latest['score'] as num?) ?? 0;
        final total = (latest['total_marks'] as num?) ?? 0;
        if (total <= 0) return 'No results yet';
        final pct = (score / total) * 100;
        return '${pct.toStringAsFixed(0)}%';
      },
      orElse: () => '…',
    );

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          title: 'Attendance',
          icon: Icons.calendar_today_rounded,
          color: Colors.blueAccent,
          onTap: () => context.push('/attendance'),
        ),
        _buildActionCard(
          title: 'Last Result',
          subtitle: lastResultSubtitle,
          icon: Icons.emoji_events_rounded,
          color: AppColors.success,
          onTap: () => context.push('/student/academics'),
        ),
        _buildActionCard(
          title: 'Calendar',
          icon: Icons.event_note_rounded,
          color: Colors.orangeAccent,
          onTap: () => context.push('/calendar'),
        ),
        _buildActionCard(
          title: 'Notice Board',
          icon: Icons.campaign_rounded,
          color: Colors.purpleAccent,
          onTap: () => context.push('/notices'),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, String? subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySm.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSm.copyWith(color: AppColors.goldCta, letterSpacing: 1));
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
}
