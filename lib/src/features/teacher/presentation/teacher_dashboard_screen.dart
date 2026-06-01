// lib/src/features/teacher/presentation/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import '../../../core/providers/session_provider.dart';
import '../../admin/data/admin_repository.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final studentsFuture = ref.watch(adminStudentsProvider);

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
            Text('Hello, ${session?.name ?? 'Teacher'} 👋',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Teacher Portal', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_rounded, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: studentsFuture.when(
        data: (students) {
          final totalStudents = students.length;
          final activeStudents = students.where((s) => s['status'] == 1).length;
          final pendingStudents = students.where((s) => s['status'] == 0).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats
                Row(children: [
                  _StatCard('Total Students', '$totalStudents', Icons.people_alt_rounded, Colors.blue),
                  const SizedBox(width: 12),
                  _StatCard('Active Students', '$activeStudents', Icons.check_circle_rounded, Colors.green),
                  const SizedBox(width: 12),
                  _StatCard('Pending Approvals', '$pendingStudents', Icons.pending_actions_rounded, Colors.orange),
                ]),
                const SizedBox(height: 24),
                const Text('Quick Actions',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: CircularProgressIndicator(color: Colors.green),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              'Unable to load student stats: $e',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );
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
    color: enabled ? const Color(0xFF112A16) : const Color(0xFF1B231D),
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: enabled ? Colors.transparent : Colors.white10,
        width: 1,
      ),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: enabled ? color.withOpacity(0.2) : Colors.white10,
        child: Icon(
          enabled ? icon : Icons.lock_outline,
          color: enabled ? color : Colors.white38,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        enabled ? subtitle : 'Access locked. Contact administrator.',
        style: TextStyle(
          color: enabled ? Colors.white54 : Colors.white24,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: enabled ? Colors.white30 : Colors.white12,
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
