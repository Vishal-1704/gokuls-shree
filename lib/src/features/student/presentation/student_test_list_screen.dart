import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/exams/domain/exam_model.dart';
import 'package:gokul_shree_app/src/features/exams/presentation/exam_instructions_screen.dart';
import 'package:intl/intl.dart';

class StudentTestListGrid extends ConsumerWidget {
  final String assessmentType;
  
  const StudentTestListGrid({super.key, required this.assessmentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We filter exams vs tests client-side for simplicity, or backend can handle it
    final upcomingExamsAsync = ref.watch(upcomingExamsProvider);
    
    return upcomingExamsAsync.when(
      data: (allExams) {
        final filteredExams = allExams.where((e) {
          final type = e['assessment_type'] ?? 'exam';
          return type == assessmentType;
        }).toList();

        if (filteredExams.isEmpty) {
          return Center(
            child: Text(
              'No upcoming ${assessmentType}s scheduled',
              style: const TextStyle(color: AppColors.textSecondary),
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
                dataRowMinHeight: 60,
                dataRowMaxHeight: 80,
                columns: const [
                  DataColumn(label: Text('Test Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Test Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: filteredExams.map((exam) {
                  final paperSet = exam['paper_sets'] ?? {};
                  final testName = paperSet['name'] ?? exam['title'] ?? 'Unknown Test';
                  final numQs = paperSet['questions'] != null ? (paperSet['questions'] as List).length : 0;
                  final duration = exam['duration_minutes'] ?? 0;
                  final startDate = exam['start_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['start_at'])) : 'N/A';
                  final endDate = exam['end_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['end_at'])) : 'N/A';
                  
                  final isStarted = DateTime.now().isAfter(DateTime.parse(exam['start_at'] ?? DateTime.now().toString()));
                  final isClosed = exam['status'] == 'closed' || (exam['end_at'] != null && DateTime.now().isAfter(DateTime.parse(exam['end_at'])));
                  final statusText = isClosed ? 'Closed' : (isStarted ? 'Start Test >' : 'Upcoming');
                  final statusColor = isClosed ? Colors.grey : (isStarted ? const Color(0xFF8CC63F) : AppColors.goldCta);

                  final courseName = (exam['courses'] as Map<String, dynamic>?)?['name'] ?? 
                                     (exam['courses'] as Map<String, dynamic>?)?['short_name'] ?? 
                                     'ADVANCE DIPLOMA IN COMPUTER APPLICATION (ADCA)';

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(testName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text('No.of Qns. : $numQs', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            Text('Duration : $duration Min', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            Text('Date : $startDate To $endDate', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(courseName, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: (isStarted && !isClosed) ? () {
                            final examObj = Exam.fromJson({
                              'id': (paperSet['id'] ?? exam['paper_set_id'] ?? 1).toString(),
                              'schedule_id': (exam['id'] ?? 1).toString(),
                              'name': testName,
                              'time_limit': duration,
                              'total_marks': paperSet['total_marks'] ?? 100,
                              'questions_count': numQs,
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamInstructionsScreen(exam: examObj),
                              ),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
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
