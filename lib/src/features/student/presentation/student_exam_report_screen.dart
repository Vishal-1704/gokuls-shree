import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:intl/intl.dart';

class StudentExamReportGrid extends ConsumerStatefulWidget {
  const StudentExamReportGrid({super.key});

  @override
  ConsumerState<StudentExamReportGrid> createState() => _StudentExamReportGridState();
}

class _StudentExamReportGridState extends ConsumerState<StudentExamReportGrid> {
  String _filter = 'all'; // 'all', 'exam', 'test'

  @override
  Widget build(BuildContext context) {
    final examResultsAsync = ref.watch(examResultsProvider);

    return examResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
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
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Test or Exam History',
                    style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your submitted tests and exams will appear here with your scores and pass/fail reports.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate summary stats
        final total = results.length;
        final passedCount = results.where((r) => r['result'] == 'pass').length;
        final passRate = total > 0 ? ((passedCount / total) * 100).toStringAsFixed(0) : '0';

        // Filter list
        final filtered = results.where((r) {
          if (_filter == 'all') return true;
          final schedule = r['schedules'] as Map<String, dynamic>?;
          final paper = schedule?['paper_sets'] as Map<String, dynamic>?;
          final type = (paper?['assessment_type'] ?? 'exam').toString().toLowerCase();
          return type == _filter;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(examResultsProvider),
          color: AppColors.goldCta,
          backgroundColor: AppColors.inkNavy800,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Total Attempts',
                      value: '$total',
                      icon: Icons.assignment_outlined,
                      color: AppColors.goldCta,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Passed',
                      value: '$passedCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Pass Rate',
                      value: '$passRate%',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Attempts ($total)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('exam', 'Exams'),
                    const SizedBox(width: 8),
                    _buildFilterChip('test', 'Online Tests'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No $_filter attempts found',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                )
              else
                ...filtered.map((res) {
                  final schedule = res['schedules'] as Map<String, dynamic>?;
                  final paper = schedule?['paper_sets'] as Map<String, dynamic>?;
                  final testName = schedule?['title'] ?? paper?['title'] ?? 'Assessment';
                  final assessmentType = (paper?['assessment_type'] ?? 'exam').toString().toLowerCase();
                  final isExam = assessmentType == 'exam';

                  final dateStr = res['submitted_at'] != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(res['submitted_at']).toLocal())
                      : 'N/A';

                  final num score = res['score'] ?? 0;
                  final num totalMarks = res['total_marks'] ?? paper?['total_marks'] ?? 100;
                  final bool passed = res['result'] == 'pass';
                  final double pct = totalMarks > 0 ? (score / totalMarks).clamp(0.0, 1.0).toDouble() : 0.0;
                  final int pctDisplay = (pct * 100).round();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: passed
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.danger.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Title & Badges
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isExam ? AppColors.primaryViolet : AppColors.info).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExam ? Icons.emoji_events_rounded : Icons.quiz_outlined,
                                color: isExam ? AppColors.primaryViolet : AppColors.info,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testName,
                                    style: AppTypography.bodyLg.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateStr,
                                        style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Type Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isExam ? AppColors.primaryViolet : AppColors.info).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isExam ? 'EXAM' : 'TEST',
                                style: TextStyle(
                                  color: isExam ? AppColors.primaryViolet : AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Score & Result Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.inkNavy900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Score Secured',
                                    style: AppTypography.bodySm.copyWith(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$score',
                                        style: AppTypography.headingSm.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ' / $totalMarks marks',
                                        style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '($pctDisplay%)',
                                        style: TextStyle(
                                          color: passed ? AppColors.success : AppColors.danger,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Pass / Fail Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (passed ? AppColors.success : AppColors.danger).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (passed ? AppColors.success : AppColors.danger).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 14,
                                      color: passed ? AppColors.success : AppColors.danger,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      passed ? 'PASS' : 'FAIL',
                                      style: TextStyle(
                                        color: passed ? AppColors.success : AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Progress indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: AppColors.inkNavy900,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              passed ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.goldCta),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load history: $e',
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headingSm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCta : AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldCta : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
