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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.badge_outlined), text: 'Zoho Employee Profile'),
            ],
          ),
        ),
        body: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: TabBarView(
          children: [
            // TAB 1: DASHBOARD & STATS
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

            // TAB 2: ZOHO EMPLOYEE DETAILS
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(teacherEmployeeProfileProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: employeeProfileAsync.when(
                  data: (emp) => _buildEmployeeDetails(context, ref, emp),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(color: AppColors.goldCta),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text('Error loading profile: $err', style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          _buildDetailMiniCard('Present', '$present', Colors.green),
                          _buildDetailMiniCard('Absent', '$absent', Colors.red),
                          _buildDetailMiniCard('Pending', '$pending', Colors.orange),
                          _buildDetailMiniCard('Total Class', '$total', Colors.blue),
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

  // WIDGET: Zoho Style Employee Profile Details
  Widget _buildEmployeeDetails(BuildContext context, WidgetRef ref, Map<String, dynamic>? emp) {
    if (emp == null) {
      return const Center(child: Text('No employee profile record found.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final name = emp['name'] ?? 'Employee';
    final email = emp['email'] ?? 'N/A';
    final contact = emp['contact'] ?? 'N/A';
    final designation = emp['designation'] ?? 'N/A';
    final department = emp['department'] ?? 'N/A';
    final doj = emp['doj'] ?? 'N/A';
    final address = emp['address'] ?? 'N/A';

    // Salary info
    final basic = (emp['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hra = (emp['hra'] as num?)?.toDouble() ?? 0.0;
    final da = (emp['da'] as num?)?.toDouble() ?? 0.0;
    final other = (emp['other_allowance'] as num?)?.toDouble() ?? 0.0;
    final gross = basic + hra + da + other;

    // Accounts
    final pf = emp['pf_account_no'] ?? 'N/A';
    final pan = emp['pan_no'] ?? 'N/A';
    final esi = emp['esi_no'] ?? 'N/A';

    // Leaves
    const totalLeaves = 15;
    const takenLeaves = 3;
    final remainingLeaves = emp['causal_leave'] ?? (totalLeaves - takenLeaves);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.inkNavy700, AppColors.inkNavy800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldCta.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.inkNavy700,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.goldCta, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(designation, style: const TextStyle(color: AppColors.goldCta, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Dept: $department', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Leaves Section (Zoho style leave tracker)
        const Text('Leave Entitlements', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildLeaveCard('Total Leaves', '$totalLeaves', Colors.blue),
            const SizedBox(width: 10),
            _buildLeaveCard('Leaves Taken', '$takenLeaves', Colors.orange),
            const SizedBox(width: 10),
            _buildLeaveCard('Balance Available', '$remainingLeaves', Colors.green),
          ],
        ),
        const SizedBox(height: 24),

        // Payroll / Payslip Section
        const Text('Payroll Snapshot (Monthly)', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider10, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPayRow('Basic Salary', '₹${basic.toStringAsFixed(2)}'),
              _buildPayRow('House Rent Allowance (HRA)', '₹${hra.toStringAsFixed(2)}'),
              _buildPayRow('Dearness Allowance (DA)', '₹${da.toStringAsFixed(2)}'),
              _buildPayRow('Special Allowances', '₹${other.toStringAsFixed(2)}'),
              const Divider(color: AppColors.textMuted, thickness: 1, height: 20),
              _buildPayRow('Gross Salary', '₹${gross.toStringAsFixed(2)}', isBold: true, valueColor: AppColors.goldCta),
              const SizedBox(height: 16),
              const Text('Statutory Registrations', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPayRow('PF Account No', pf, isSecondary: true),
              _buildPayRow('ESI Registration No', esi, isSecondary: true),
              _buildPayRow('PAN Card', pan, isSecondary: true),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Profile Details List
        const Text('Registry Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoRow('Email Address', email, Icons.email_outlined),
              _buildInfoRow('Contact Number', contact, Icons.phone_outlined),
              _buildInfoRow('Date of Joining', doj, Icons.calendar_today_outlined),
              _buildInfoRow('Office Address', address, Icons.location_on_outlined),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Experience Certificate Request
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _requestExperienceCertificate(context, ref),
            icon: const Icon(Icons.workspace_premium, color: AppColors.textPrimary),
            label: const Text('Request Experience Certificate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _requestExperienceCertificate(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final baseUrl = 'http://10.0.2.2:3001/api/v1'; // Or from config
      final session = supabase.auth.currentSession;
      
      if (session == null) throw Exception('Not authenticated');

      final response = await Dio().post(
        '$baseUrl/documents/experience-certificates/request',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        }),
      );

      if (response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience Certificate requested successfully!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request certificate: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildLeaveCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPayRow(String label, String value, {bool isBold = false, bool isSecondary = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSecondary ? 11 : 12,
              color: isSecondary ? AppColors.textMuted : (isBold ? AppColors.textPrimary : AppColors.textSecondary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSecondary ? 11 : 12,
              color: valueColor ?? (isSecondary ? AppColors.textMuted : AppColors.textPrimary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.goldCta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
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
