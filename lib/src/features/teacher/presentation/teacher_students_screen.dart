import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
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
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (allStudents) {
          return subjectsAsync.when(
            data: (subjects) {
              // Extract course IDs the teacher teaches
              final teacherCourseIds = subjects.map((s) => s['course_id']).where((id) => id != null).toSet();

              // Filter students
              final students = allStudents.where((s) {
                 final cId = s['course_id'];
                 if (teacherCourseIds.isNotEmpty && !teacherCourseIds.contains(cId)) return false;
                 if (_searchQuery.isEmpty) return true;
                 final name = (s['name'] ?? '').toString().toLowerCase();
                 final regNo = (s['reg_no'] ?? '').toString().toLowerCase();
                 return name.contains(_searchQuery) || regNo.contains(_searchQuery);
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
              final courseName = s['courses']?['short_name'] ?? s['courses']?['name'] ?? 'Student';
              final isActive = s['status'] == 1;

              return Card(
                color: AppColors.inkNavy800,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.greenAccent)),
                  ),
                  title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('$regNo • $courseName',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isActive ? AppColors.success : AppColors.warning).withOpacity(0.2),
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
                                    backgroundColor: AppColors.goldCta.withOpacity(0.2),
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
                                  // Navigate to marks view (mock)
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks view not available for this student.')));
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.how_to_reg_outlined, color: AppColors.textSecondary),
                                title: const Text('Attendance Summary', style: TextStyle(color: AppColors.textPrimary)),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                onTap: () {
                                  // Navigate to attendance view (mock)
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance summary coming soon.')));
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
