import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/exams/domain/exam_model.dart';
import 'package:intl/intl.dart';

class StudentTestListGrid extends ConsumerStatefulWidget {
  final String assessmentType;

  const StudentTestListGrid({super.key, required this.assessmentType});

  @override
  ConsumerState<StudentTestListGrid> createState() => _StudentTestListGridState();
}

class _StudentTestListGridState extends ConsumerState<StudentTestListGrid> {
  int _selectedTabIndex = 0; // 0: Upcoming, 1: Past / Attempted

  @override
  Widget build(BuildContext context) {
    final upcomingExamsAsync = ref.watch(upcomingExamsProvider);
    final examResultsAsync = ref.watch(examResultsProvider);

    final isExam = widget.assessmentType.toLowerCase() == 'exam';
    final labelPlural = isExam ? 'Exams' : 'Tests';

    return upcomingExamsAsync.when(
      data: (allExams) {
        final myResults = examResultsAsync.value ?? [];

        // Build set of attempted schedule IDs and paper IDs
        final attemptedScheduleIds = <int>{};
        final attemptedPaperIds = <int>{};
        final attemptByScheduleId = <int, Map<String, dynamic>>{};
        final attemptByPaperId = <int, Map<String, dynamic>>{};

        for (final res in myResults) {
          final sId = res['schedule_id'];
          if (sId is int) {
            attemptedScheduleIds.add(sId);
            attemptByScheduleId[sId] = res;
          } else if (sId != null) {
            final parsed = int.tryParse(sId.toString());
            if (parsed != null) {
              attemptedScheduleIds.add(parsed);
              attemptByScheduleId[parsed] = res;
            }
          }

          final s = res['schedules'] as Map<String, dynamic>?;
          final pId = s?['paper_id'];
          if (pId is int) {
            attemptedPaperIds.add(pId);
            attemptByPaperId[pId] = res;
          } else if (pId != null) {
            final parsed = int.tryParse(pId.toString());
            if (parsed != null) {
              attemptedPaperIds.add(parsed);
              attemptByPaperId[parsed] = res;
            }
          }
        }

        // Filter all schedules matching this assessment type
        final matchingSchedules = allExams.where((e) {
          final type = e['assessment_type'] ?? (e['paper_sets'] as Map?)?['assessment_type'] ?? 'exam';
          return type.toString().toLowerCase() == widget.assessmentType.toLowerCase();
        }).toList();

        // Partition into upcoming (unattempted & open) vs past (attempted or closed)
        final upcomingList = <Map<String, dynamic>>[];
        final pastList = <Map<String, dynamic>>[];

        for (final exam in matchingSchedules) {
          final sId = exam['id'] is int ? exam['id'] as int : int.tryParse(exam['id']?.toString() ?? '');
          final pId = exam['paper_id'] is int ? exam['paper_id'] as int : int.tryParse(exam['paper_id']?.toString() ?? '');

          final isAttempted = (sId != null && attemptedScheduleIds.contains(sId)) ||
              (pId != null && attemptedPaperIds.contains(pId));

          final endUtc = DateTime.tryParse(exam['end_at']?.toString() ?? '')?.toUtc();
          final isClosed = exam['status'] == 'closed' || (endUtc != null && DateTime.now().toUtc().isAfter(endUtc));

          if (isAttempted || isClosed) {
            // Attach matching attempt result if present
            final copy = Map<String, dynamic>.from(exam);
            if (sId != null && attemptByScheduleId.containsKey(sId)) {
              copy['attempt_result'] = attemptByScheduleId[sId];
            } else if (pId != null && attemptByPaperId.containsKey(pId)) {
              copy['attempt_result'] = attemptByPaperId[pId];
            }
            copy['is_attempted'] = isAttempted;
            pastList.add(copy);
          } else {
            upcomingList.add(exam);
          }
        }

        // Also add any attempts that might not be in upcoming schedule roster (e.g. older completed attempts)
        for (final res in myResults) {
          final paper = (res['paper_sets'] as Map?) ?? {};
          final type = paper['assessment_type'] ?? 'exam';
          if (type.toString().toLowerCase() == widget.assessmentType.toLowerCase()) {
            final sId = res['schedule_id'] is int ? res['schedule_id'] as int : int.tryParse(res['schedule_id']?.toString() ?? '');
            final alreadyInPast = sId != null && pastList.any((p) => p['id'] == sId);
            if (!alreadyInPast) {
              final synthetic = <String, dynamic>{
                'id': sId ?? res['id'],
                'paper_id': paper['id'] ?? (res['schedules'] as Map?)?['paper_id'],
                'title': res['schedules']?['title'] ?? paper['title'] ?? paper['name'] ?? 'Assessment',
                'course_name': res['course_name'] ?? 'General Course',
                'start_at': res['submitted_at'],
                'end_at': res['submitted_at'],
                'status': 'closed',
                'paper_sets': paper,
                'attempt_result': res,
                'is_attempted': true,
              };
              pastList.add(synthetic);
            }
          }
        }

        return RefreshIndicator(
          color: AppColors.goldCta,
          backgroundColor: AppColors.inkNavy800,
          onRefresh: () async {
            await Future.wait([
              ref.refresh(upcomingExamsProvider.future),
              ref.refresh(examResultsProvider.future),
            ]);
          },
          child: Column(
            children: [
              // ── Sub-Tabs Header (Upcoming vs Past) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SubTabButton(
                          title: 'Upcoming (${upcomingList.length})',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _SubTabButton(
                          title: 'Past $labelPlural (${pastList.length})',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab Content ──
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildUpcomingList(context, upcomingList, labelPlural, isExam)
                    : _buildPastList(context, pastList, labelPlural, isExam),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))),
    );
  }

  Widget _buildUpcomingList(
    BuildContext context,
    List<Map<String, dynamic>> exams,
    String labelPlural,
    bool isExam,
  ) {
    if (exams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No Upcoming $labelPlural',
        subtitle: 'You are all caught up! No ${labelPlural.toLowerCase()} are scheduled for you at this time.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final exam = exams[index];
        final paperSet = (exam['paper_sets'] as Map<String, dynamic>?) ?? {};
        final testName = (paperSet['title'] ?? paperSet['name'] ?? exam['title'] ?? 'Assessment').toString();
        final numQs = (paperSet['questions_count'] as num?)?.toInt() ?? 0;
        final duration = (paperSet['duration_minutes'] as num?)?.toInt() ?? 60;
        final totalMarks = (paperSet['total_marks'] as num?)?.toInt() ?? 100;
        final startDate = exam['start_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['start_at'])) : 'N/A';
        final endDate = exam['end_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(exam['end_at'])) : 'N/A';

        final startUtc = DateTime.tryParse(exam['start_at']?.toString() ?? '')?.toUtc();
        final endUtc = DateTime.tryParse(exam['end_at']?.toString() ?? '')?.toUtc();
        final nowUtc = DateTime.now().toUtc();
        final isStarted = startUtc == null || nowUtc.isAfter(startUtc);
        final isClosed = exam['status'] == 'closed' || (endUtc != null && nowUtc.isAfter(endUtc));

        String statusText;
        if (isClosed) {
          statusText = '${widget.assessmentType} Window Closed';
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
                'General Course')
            .toString();

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
                      color: canStart ? const Color(0xFF006B3F).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

              // Details Badges
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

              // Start Action Button (Cleanly constrained, never overlaps)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
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
                  icon: canStart
                      ? const Icon(Icons.play_arrow_rounded, size: 20)
                      : const Icon(Icons.lock_clock_outlined, size: 18),
                  label: Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: canStart ? Colors.white : Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canStart ? const Color(0xFF006B3F) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: canStart ? 2 : 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPastList(
    BuildContext context,
    List<Map<String, dynamic>> exams,
    String labelPlural,
    bool isExam,
  ) {
    if (exams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_edu_outlined,
        title: 'No Past $labelPlural',
        subtitle: 'Completed tests and exams will appear here with your attempt results and score analysis.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final exam = exams[index];
        final paperSet = (exam['paper_sets'] as Map<String, dynamic>?) ?? {};
        final testName = (paperSet['title'] ?? paperSet['name'] ?? exam['title'] ?? 'Assessment').toString();
        final numQs = (paperSet['questions_count'] as num?)?.toInt() ?? 0;
        final duration = (paperSet['duration_minutes'] as num?)?.toInt() ?? 60;
        final totalMarks = (paperSet['total_marks'] as num?)?.toInt() ?? 100;

        final isAttempted = exam['is_attempted'] == true;
        final attempt = exam['attempt_result'] as Map<String, dynamic>?;

        final courseName = (paperSet['course_name'] ??
                exam['course_name'] ??
                (paperSet['courses'] as Map<String, dynamic>?)?['name'] ??
                'General Course')
            .toString();

        String dateSubmitted = 'Completed';
        if (attempt != null && attempt['submitted_at'] != null) {
          final dt = DateTime.tryParse(attempt['submitted_at'].toString());
          if (dt != null) dateSubmitted = 'Submitted ${DateFormat('dd-MM-yyyy').format(dt)}';
        } else if (exam['end_at'] != null) {
          final dt = DateTime.tryParse(exam['end_at'].toString());
          if (dt != null) dateSubmitted = 'Ended ${DateFormat('dd-MM-yyyy').format(dt)}';
        }

        // Score info
        num? score;
        num? maxM;
        String? scoreText;
        String? resultStatus;
        if (attempt != null) {
          score = attempt['score'] as num?;
          maxM = (attempt['total_marks'] as num?) ?? totalMarks;
          if (score != null && maxM > 0) {
            final pct = (score / maxM) * 100;
            scoreText = '$score / $maxM (${pct.toStringAsFixed(0)}%)';
          }
          resultStatus = (attempt['result'] ?? (score != null && maxM > 0 && (score / maxM) >= 0.4 ? 'passed' : 'completed')).toString().toUpperCase();
        }

        // Greyed out card style as requested
        return Opacity(
          opacity: 0.85,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inkNavy800.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Course Chip + Attempted Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAttempted ? Icons.task_alt_rounded : Icons.history_rounded,
                        color: isAttempted ? AppColors.success : AppColors.textMuted,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  courseName,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isAttempted ? AppColors.success : AppColors.textMuted).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAttempted ? (resultStatus ?? 'ATTEMPTED') : 'CLOSED',
                                  style: TextStyle(
                                    color: isAttempted ? AppColors.success : AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Details Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(icon: Icons.calendar_today_outlined, label: dateSubmitted),
                    _DetailBadge(icon: Icons.timer_outlined, label: '$duration Min'),
                    if (numQs > 0)
                      _DetailBadge(icon: Icons.quiz_outlined, label: '$numQs Questions'),
                    if (scoreText != null)
                      _DetailBadge(icon: Icons.emoji_events_outlined, label: 'Score: $scoreText')
                    else
                      _DetailBadge(icon: Icons.star_outline, label: '$totalMarks Marks'),
                  ],
                ),
                const SizedBox(height: 14),

                // Past Exam Action Button: View Result & Analysis
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/results'),
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text(
                      'View Result & Report',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldCta,
                      side: BorderSide(color: AppColors.goldCta.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              child: Icon(icon, size: 48, color: AppColors.goldCta),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCta : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.inkNavy900 : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
