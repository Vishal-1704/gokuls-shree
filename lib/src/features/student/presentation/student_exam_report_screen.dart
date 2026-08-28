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
                headingRowColor: MaterialStateProperty.all(const Color(0xFF006B3F)),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('Sn.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Test Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Tot.Q.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Attempted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('L.Q.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('R.Q.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('W.Q.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('(-M.)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Tot.M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: results.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final res = entry.value;
                  
                  final date = res['calculated_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(res['calculated_at'])) : 'N/A';
                  final testName = res['exam_sessions']?['paper_sets']?['name'] ?? 'Unknown Test';
                  
                  final totalQ = res['total_questions'] ?? 0;
                  final attempted = res['attempted_questions'] ?? 0;
                  final correct = res['correct_answers'] ?? 0;
                  final wrong = res['incorrect_answers'] ?? 0;
                  final left = totalQ - attempted;
                  
                  // For UI fidelity, mocking negative marks and total marks calculation logic from typical Indian test structure
                  final negMarks = res['negative_marks'] ?? (wrong * 0.25).toStringAsFixed(2);
                  final totalMarks = res['score_obtained'] ?? 0;

                  return DataRow(
                    cells: [
                      DataCell(Text('$index', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text(date, style: const TextStyle(color: Colors.black87))),
                      DataCell(Text(testName, style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$totalQ', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$attempted', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$left', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$correct', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$wrong', style: const TextStyle(color: Colors.black87))),
                      DataCell(Text('$negMarks', style: const TextStyle(color: Colors.red))),
                      DataCell(Text('$totalMarks', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
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
