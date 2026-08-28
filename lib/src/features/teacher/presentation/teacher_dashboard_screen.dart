// lib/src/features/teacher/presentation/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import '../../../core/providers/session_provider.dart';
import '../../admin/data/admin_repository.dart';
import '../data/attendance_repository.dart';
import 'package:dio/dio.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/widgets/responsive_container.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final employeeProfileAsync = ref.watch(teacherEmployeeProfileProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider);
    final attendanceStatsAsync = ref.watch(teacherStudentAttendanceStatsProvider);

    // Permission checks (support both uppercase database keys and lowercase fallback)
    final hasMarkAttendance = session?.hasPermission('MARK_ATTENDANCE') ?? session?.hasPermission('mark_attendance') ?? false;
    final hasViewStudents = session?.hasPermission('READ_BRANCH_STUDENTS') ?? session?.hasPermission('view_students') ?? false;
    final hasUploadResults = session?.hasPermission('UPLOAD_MARKS') ?? session?.hasPermission('upload_results') ?? false;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${session?.name ?? 'Teacher'} 👋',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            employeeProfileAsync.when(
              data: (emp) => Text(
                '${emp?['designation'] ?? 'Faculty'} • ${emp?['department'] ?? 'Teacher Portal'}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              loading: () => const Text('Teacher Portal', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              error: (_, __) => const Text('Teacher Portal', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child:
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminStudentsProvider);
                ref.invalidate(teacherSubjectsProvider);
                ref.invalidate(teacherStudentAttendanceStatsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Student Attendance Statistics Summary
                    _buildStudentAttendanceCard(context, attendanceStatsAsync),
                    const SizedBox(height: 20),

                    // 2. Subjects Taught Catalog
                    const Text(
                      'Subjects I Teach',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildSubjectsSection(subjectsAsync),
                    const SizedBox(height: 24),

                    // 3. Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.how_to_reg_rounded,
                      title: 'Mark Attendance',
                      subtitle: 'Mark today\'s student attendance',
                      color: Colors.green,
                      enabled: hasMarkAttendance,
                      onTap: () => context.go('/teacher/attendance'),
                    ),
                    _ActionTile(
                      icon: Icons.people_alt_rounded,
                      title: 'View Students',
                      subtitle: 'Browse students in your branch',
                      color: Colors.blue,
                      enabled: hasViewStudents,
                      onTap: () => context.go('/teacher/students'),
                    ),
                    _ActionTile(
                      icon: Icons.assignment_rounded,
                      title: 'Upload Results',
                      subtitle: 'Enter exam marks for students',
                      color: Colors.orange,
                      enabled: hasUploadResults,
                      onTap: () => context.push('/teacher/upload-results'),
                    ),
                  ],
                ),
              ),
            ),
        ),
    );
  }

  // WIDGET: Student Attendance Summary (Zoho style summary card)
  Widget _buildStudentAttendanceCard(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final total = stats['total_students'] ?? 0;
        final present = stats['present_today'] ?? 0;
        final absent = stats['absent_today'] ?? 0;
        final pending = stats['pending_today'] ?? 0;
        final rate = (stats['attendance_rate'] as num?)?.toDouble() ?? 0.0;

        return Card(
          color: AppColors.inkNavy800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Attendance',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Branch-level tracking for today',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Circular Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: rate / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(rate >= 75 ? AppColors.success : AppColors.warning),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${rate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: rate >= 75 ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const Text(
                              'Rate',
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Stats Details Grid
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailMiniCard('Present', '$present', Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDetailMiniCard('Absent', '$absent', Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildDetailMiniCard('Pending', '$pending', Colors.orange)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDetailMiniCard('Total Class', '$total', Colors.blue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 140,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.goldCta),
      ),
      error: (e, _) => Container(
        height: 140,
        alignment: Alignment.center,
        child: Text('Error loading stats: $e', style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }

  Widget _buildDetailMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inkNavy900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider10, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // WIDGET: Subjects list
  Widget _buildSubjectsSection(AsyncValue<List<Map<String, dynamic>>> subjectsAsync) {
    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No subjects assigned', style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final sub = subjects[i];
              final subName = sub['name'] ?? 'Subject';
              final subCode = sub['code'] ?? 'SUB';
              final course = sub['courses']?['title'] ?? sub['courses']?['name'] ?? 'Class';

              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldCta.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subCode,
                      style: const TextStyle(color: AppColors.goldCta, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      ),
      error: (_, __) => const SizedBox(
        height: 100,
        child: Center(child: Text('Error loading subjects', style: TextStyle(color: AppColors.textMuted))),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Card(
    color: enabled ? AppColors.inkNavy900 : AppColors.inkNavy800,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: enabled ? Colors.transparent : AppColors.divider10,
        width: 1,
      ),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: enabled ? color.withOpacity(0.2) : AppColors.divider10,
        child: Icon(
          enabled ? icon : Icons.lock_outline,
          color: enabled ? color : AppColors.textMuted,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        enabled ? subtitle : 'Access locked. Contact administrator.',
        style: TextStyle(
          color: enabled ? AppColors.textMuted : AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: enabled ? AppColors.textMuted : AppColors.divider,
        size: 14,
      ),
      onTap: enabled
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access locked. Contact administrator to enable this permission.'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
    ),
  );
}