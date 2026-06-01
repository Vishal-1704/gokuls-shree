import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(studentAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('My Attendance', style: TextStyle(color: Colors.white)),
      ),
      body: attendanceAsync.when(
        data: (records) {
          final present = records.where((r) {
            final status = (r['status'] ?? '').toString().toLowerCase();
            return status == 'present' || status == 'p' || status == 'late';
          }).length;
          final pct = records.isEmpty ? 0 : ((present / records.length) * 100).toStringAsFixed(0);

          return Column(children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF0E2A47)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _AttStat('$present', 'Present', Colors.greenAccent),
                _AttStat('${records.length - present}', 'Absent', Colors.redAccent),
                _AttStat('$pct%', 'Attendance', Colors.amberAccent),
              ]),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Text('No attendance records found', style: TextStyle(color: Colors.white70)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: records.length,
                      itemBuilder: (ctx, i) {
                        final r = records[i];
                        final status = (r['status'] ?? '').toString().toLowerCase();
                        final isPresent = status == 'present' || status == 'p';
                        final isLate = status == 'late' || status == 'l';
                        final color = isPresent
                            ? Colors.green
                            : isLate
                                ? Colors.orange
                                : Colors.red;
                        final label = isPresent
                            ? 'Present'
                            : isLate
                                ? 'Late'
                                : 'Absent';
                        final date = r['date']?.toString() ?? 'N/A';
                        final day = date.length >= 3 ? date.substring(0, 3) : 'Day';
                        return Card(
                          color: const Color(0xFF152D4D),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              child: Text(day, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(date, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Marked as ${r['status']?.toString() ?? 'N/A'}', style: const TextStyle(color: Colors.white54)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withOpacity(0.4)),
                              ),
                              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white70)),
        error: (error, _) => Center(
          child: Text('Unable to load attendance: $error', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  const _AttStat(this.value, this.label, this.color);
  final String value, label; final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  ]);
}
