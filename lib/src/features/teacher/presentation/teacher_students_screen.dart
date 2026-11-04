import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/teacher/data/attendance_repository.dart';

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMarksSheet(BuildContext context, String studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.inkNavy900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(adminRepositoryProvider).getStudentResults(studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
                }
                final results = snapshot.data ?? [];

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.assessment_rounded, color: AppColors.goldCta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$studentName — Results',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(
                              child: Text(
                                'No exam results recorded for this student.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final r = results[index];
                                final examName = (r['exam_name'] ?? r['title'] ?? 'Exam').toString();
                                final subjectName = (r['subject_name'] ?? r['subject'] ?? 'Subject').toString();
                                final score = (r['marks_obtained'] ?? r['score'] ?? 0).toString();
                                final total = (r['total_marks'] ?? 100).toString();
                                final grade = r['grade']?.toString();
                                final dateStr = r['created_at'] != null
                                    ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(r['created_at'].toString()) ?? DateTime.now())
                                    : null;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.inkNavy800,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              examName,
                                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              subjectName,
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                            if (dateStr != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                dateStr,
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$score / $total',
                                            style: const TextStyle(color: AppColors.goldCta, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          if (grade != null && grade.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Grade $grade',
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAttendanceSheet(BuildContext context, String studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.inkNavy900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(supabaseServiceProvider).getStudentAttendance(studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
                }
                final logs = snapshot.data ?? [];
                final total = logs.length;
                final present = logs.where((l) {
                  final st = (l['status'] ?? '').toString().toLowerCase();
                  return st == 'present' || st == 'p' || st == 'late';
                }).length;
                final pct = total > 0 ? (present / total * 100).round() : 0;

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.how_to_reg_rounded, color: Colors.greenAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$studentName — Attendance',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inkNavy800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol('Total Days', '$total'),
                          _statCol('Present', '$present', Colors.green),
                          _statCol('Absent', '${total - present}', Colors.red),
                          _statCol('Rate', '$pct%', AppColors.goldCta),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No attendance records found for this student.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: logs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final dateStr = log['date']?.toString() ?? 'Recent';
                                final st = (log['status'] ?? 'Present').toString();
                                final isPres = st.toLowerCase().startsWith('p');

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.inkNavy800,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPres ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          st,
                                          style: TextStyle(
                                            color: isPres ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCol(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search by name or reg. no.',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              )
            : const Text('Students', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (rawStudents) {
          return subjectsAsync.when(
            data: (subjects) {
              final students = rawStudents.where((s) {
                if (_searchQuery.isEmpty) return true;
                final name = (s['name'] ?? '').toString().toLowerCase();
                final reg = (s['reg_no'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || reg.contains(_searchQuery);
              }).toList();

              if (students.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'No students found for your branch' : 'No students match "$_searchQuery"',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  final name = (s['name'] ?? 'Unknown').toString();
                  final regNo = (s['reg_no'] ?? 'N/A').toString();
                  final studentId = (s['id'] ?? regNo).toString();
                  final courseName = s['courses']?['short_name'] ?? s['courses']?['name'] ?? 'Student';
                  final isActive = s['status'] == 1;

                  return Card(
                    color: AppColors.inkNavy800,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.greenAccent)),
                      ),
                      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('$regNo • $courseName',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Pending',
                          style: TextStyle(
                            color: isActive ? AppColors.success : AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.inkNavy800,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.goldCta.withValues(alpha: 0.2),
                                        child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.goldCta, fontSize: 20)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                            Text('Reg No: $regNo', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Text('Course Details', style: TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(courseName, style: const TextStyle(color: AppColors.textPrimary)),
                                  const SizedBox(height: 16),
                                  
                                  const Text('Performance & Records', style: TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.assessment_outlined, color: AppColors.textSecondary),
                                    title: const Text('View Marks & Results', style: TextStyle(color: AppColors.textPrimary)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMarksSheet(context, studentId, name);
                                    },
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.how_to_reg_outlined, color: AppColors.textSecondary),
                                    title: const Text('Attendance Summary', style: TextStyle(color: AppColors.textPrimary)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showAttendanceSheet(context, studentId, name);
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.textSecondary)),
            error: (error, _) => Center(
              child: Text('Unable to load subjects: $error', style: const TextStyle(color: AppColors.textSecondary)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.textSecondary)),
        error: (error, _) => Center(
          child: Text('Unable to load students: $error', style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}
