import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:intl/intl.dart';

class StudentExamReportGrid extends ConsumerWidget {
  const StudentExamReportGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examResultsAsync = ref.watch(examResultsProvider);

    return examResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No exam reports available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF006B3F)),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('Sn.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Test Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Marks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: results.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final res = entry.value;

                  final date = res['submitted_at'] != null
                      ? DateFormat('dd-MM-yyyy').format(DateTime.parse(res['submitted_at']))
                      : 'N/A';
                  final schedule = res['schedules'] as Map<String, dynamic>?;
                  final paper = schedule?['paper_sets'] as Map<String, dynamic>?;
                  final testName = schedule?['title'] ?? paper?['title'] ?? 'Unknown Test';
                  final score = res['score'] ?? 0;
                  final totalMarks = res['total_marks'] ?? 0;
                  final passed = res['result'] == 'pass';

                  return DataRow(
                    cells: [
                      DataCell(Text('$index', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text(date, style: const TextStyle(color: Colors.black87))),
                      DataCell(Text(testName, style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$score', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                      DataCell(Text('$totalMarks', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text(
                        passed ? 'PASS' : 'FAIL',
                        style: TextStyle(color: passed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))),
    );
  }
}
