import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class TeacherStudentsScreen extends ConsumerWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Students', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Text('No students found for your branch', style: TextStyle(color: Colors.white70)),
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
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('$regNo • $courseName',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white70)),
        error: (error, _) => Center(
          child: Text('Unable to load students: $error', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}
