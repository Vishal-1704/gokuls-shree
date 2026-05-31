import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(studentRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: repo.getStudentProfile(),
                    builder: (context, profileSnap) {
                      if (profileSnap.connectionState == ConnectionState.waiting) return _buildLoading();
                      if (profileSnap.hasError) {
                        return Center(
                          child: Text('Error loading profile: ${profileSnap.error}', 
                          style: AppTypography.bodySm.copyWith(color: Colors.redAccent)),
                        );
                      }
                      final profile = profileSnap.data ?? {};
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDigitalIDCard(profile),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle('Academic Progress'),
                          const SizedBox(height: 12),
                          _buildAttendanceAndFees(repo),
                          
                          const SizedBox(height: 24),
                          _buildSectionTitle('Notice Board'),
                          const SizedBox(height: 12),
                          _buildNoticeBoard(repo),
                          
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 100),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
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
          Text('GOKUL SHREE', style: AppTypography.labelMd.copyWith(color: AppColors.goldCta, letterSpacing: 2)),
          Text('Student Dashboard', style: AppTypography.headingSm),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDigitalIDCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.inkNavy800, Color(0xFF1E293B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: AppColors.goldCta.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.school_rounded, size: 150, color: Colors.white.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name']?.toUpperCase() ?? 'STUDENT', style: AppTypography.headingMd.copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(data['class_section'] ?? 'Class/Course', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      _buildIDDetail('REG NO', data['reg_no'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildIDDetail('SESSION', '2024-25'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: QrImageView(
                        data: 'STU-${data['id']}',
                        version: QrVersions.auto,
                        size: 80.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('SCAN FOR PROFILE', style: AppTypography.labelSm.copyWith(fontSize: 8, color: AppColors.goldCta)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIDDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm.copyWith(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildAttendanceAndFees(StudentRepository repo) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: repo.getAttendanceStats(),
            builder: (context, snap) {
              final stats = snap.data ?? {'percentage': 0, 'status': '...'};
              return _buildSmallCard(
                title: 'Attendance',
                value: '${stats['percentage']}%',
                icon: Icons.calendar_today_rounded,
                color: Colors.blueAccent,
                onTap: () => context.push('/attendance'),
              );
            }
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: repo.getFeeSnapshot(),
            builder: (context, snap) {
              final snapshot = snap.data ?? {'all_paid': false};
              final isPaid = snapshot['all_paid'] == true;
              return _buildSmallCard(
                title: 'Fee Status',
                value: isPaid ? 'PAID' : 'DUE',
                icon: Icons.account_balance_wallet_rounded,
                color: isPaid ? AppColors.success : Colors.orangeAccent,
                onTap: () => context.push('/fee-status'),
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.textSecondary)),
            Text(value, style: AppTypography.headingSm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBoard(StudentRepository repo) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getNotices(),
      builder: (context, snap) {
        final notices = snap.data ?? [];
        if (notices.isEmpty) return _buildEmptyNotice();
        
        return Column(
          children: notices.take(2).map((n) => _buildNoticeTile(n)).toList(),
        );
      },
    );
  }

  Widget _buildNoticeTile(Map<String, dynamic> notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.goldCta.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.campaign_rounded, color: AppColors.goldCta, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice['title'] ?? 'Notice', style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                Text(notice['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionIcon(Icons.assignment_rounded, 'Results', () => context.push('/results')),
            _buildActionIcon(Icons.description_rounded, 'Documents', () => context.push('/student/docs')),
            _buildActionIcon(Icons.quiz_rounded, 'Mock Test', () {}),
            _buildActionIcon(Icons.support_agent_rounded, 'Support', () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.inkNavy800, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.labelMd.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSm.copyWith(color: AppColors.goldCta, letterSpacing: 1));
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
  Widget _buildEmptyNotice() => Center(child: Text('No active notices', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)));
}
