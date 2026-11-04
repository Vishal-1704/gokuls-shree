import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/exams/domain/exam_model.dart';
import 'package:intl/intl.dart';

class StudentTestListGrid extends ConsumerWidget {
  final String assessmentType;

  const StudentTestListGrid({super.key, required this.assessmentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingExamsAsync = ref.watch(upcomingExamsProvider);
    final isExam = assessmentType.toLowerCase() == 'exam';
    final labelPlural = isExam ? 'Exams' : 'Tests';

    return upcomingExamsAsync.when(
      data: (allExams) {
        final filteredExams = allExams.where((e) {
          final type = e['assessment_type'] ?? (e['paper_sets'] as Map?)?['assessment_type'] ?? 'exam';
          return type.toString().toLowerCase() == assessmentType.toLowerCase();
        }).toList();

        if (filteredExams.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.goldCta),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Upcoming $labelPlural',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are all caught up! No ${labelPlural.toLowerCase()} are scheduled for you at this time.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.goldCta,
          backgroundColor: AppColors.inkNavy800,
          onRefresh: () => ref.refresh(upcomingExamsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: filteredExams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final exam = filteredExams[index];
              final paperSet = (exam['paper_sets'] as Map<String, dynamic>?) ?? {};
              final testName = paperSet['title'] ?? paperSet['name'] ?? exam['title'] ?? 'Assessment';
              final numQs = paperSet['questions_count'] ?? 0;
              final duration = paperSet['duration_minutes'] ?? 60;
              final totalMarks = paperSet['total_marks'] ?? 100;
              final startDate = exam['start_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['start_at'])) : 'N/A';
              final endDate = exam['end_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['end_at'])) : 'N/A';

              final startUtc = DateTime.tryParse(exam['start_at']?.toString() ?? '')?.toUtc();
              final endUtc = DateTime.tryParse(exam['end_at']?.toString() ?? '')?.toUtc();
              final nowUtc = DateTime.now().toUtc();
              final isStarted = startUtc == null || nowUtc.isAfter(startUtc);
              final isClosed = exam['status'] == 'closed' || (endUtc != null && nowUtc.isAfter(endUtc));

              String statusText;
              if (isClosed) {
                statusText = '$assessmentType Window Closed';
              } else if (!isStarted) {
                statusText = 'Starts $startDate';
              } else {
                statusText = isExam ? 'Start Exam' : 'Start Test';
              }

              final String dateLabel;
              if (exam['end_at'] != null && endDate != 'N/A') {
                dateLabel = '$startDate – $endDate';
              } else if (exam['start_at'] != null && startDate != 'N/A') {
                dateLabel = 'Valid from: $startDate';
              } else {
                dateLabel = 'Available Now';
              }

              final courseName = (paperSet['course_name'] ??
                                  exam['course_name'] ??
                                  (paperSet['courses'] as Map<String, dynamic>?)?['name'] ??
                                  (paperSet['courses'] as Map<String, dynamic>?)?['short_name'] ??
                                  'General Course').toString();

              final canStart = isStarted && !isClosed;

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: canStart ? const Color(0xFF006B3F).withValues(alpha: 0.6) : AppColors.divider.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Icon + Title + Course Chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: canStart
                                ? const Color(0xFF006B3F).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isExam ? Icons.military_tech_outlined : Icons.assignment_outlined,
                            color: canStart ? const Color(0xFF8CC63F) : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.goldCta.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.35), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_outlined, size: 12, color: AppColors.goldCta),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        courseName,
                                        style: const TextStyle(
                                          color: AppColors.goldCta,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 12),

                    // Details Badges (cleanly spaced and padded pills)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DetailBadge(icon: Icons.quiz_outlined, label: '$numQs Questions'),
                        _DetailBadge(icon: Icons.timer_outlined, label: '$duration Min'),
                        _DetailBadge(icon: Icons.star_outline, label: '$totalMarks Marks'),
                        _DetailBadge(icon: Icons.calendar_today_outlined, label: dateLabel),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start Action Button (Adapts full width of card)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: canStart
                            ? () {
                                final examObj = Exam.fromJson({
                                  'id': (paperSet['id'] ?? exam['paper_id'] ?? 1).toString(),
                                  'schedule_id': (exam['id'] ?? 1).toString(),
                                  'title': testName,
                                  'duration_minutes': duration,
                                  'total_marks': totalMarks,
                                  'questions_count': numQs,
                                });
                                context.push('/exam-instruction/${examObj.id}', extra: examObj);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canStart ? const Color(0xFF006B3F) : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: canStart ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (canStart) ...[
                              const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              statusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: canStart ? Colors.white : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.goldCta),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
