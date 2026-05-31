import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/widgets/webview_screen.dart';
import '../data/exam_repository.dart';
import '../domain/exam_model.dart';

final examListProvider = FutureProvider<List<Exam>>((ref) async {
  return ref.read(examRepositoryProvider).getExams();
});

final examResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(examRepositoryProvider).getMyResults();
});

final upcomingExamsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async => ref.read(studentRepositoryProvider).getUpcomingExams(),
);

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.inkNavy900,
        appBar: AppBar(
          title: const Text(
            'Exams',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.inkNavy800,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: TabBar(
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Hub"),
              Tab(text: "Exams"),
              Tab(text: "Results"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_ExamHubTab(), _AvailableExamsTab(), _MyResultsTab()],
        ),
      ),
    );
  }
}

class _ExamHubTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingExamsProvider);
    final resultsAsync = ref.watch(examResultsProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == 'super_admin' || role == 'branch_admin';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingExamsProvider);
        ref.invalidate(examResultsProvider);
      },
      child: Container(
        color: AppColors.inkNavy900,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HubSectionTitle(
              title: 'Exam Schedule',
              onTap: () => DefaultTabController.of(context).animateTo(1),
            ),
            const SizedBox(height: 8),
            upcomingAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCard(message: 'No upcoming exams yet');
                }

                return _HubCard(
                  child: Column(
                    children: items.take(3).map((exam) {
                      final status = exam['status']?.toString() ?? 'Available';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_note,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam['name']?.toString() ?? 'Exam',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    exam['date']?.toString() ?? 'TBA',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _MiniBadge(label: status),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, __) =>
                  const _EmptyCard(message: 'Failed to load schedule'),
            ),
            const SizedBox(height: 16),
            _HubSectionTitle(
              title: 'Recent Results',
              onTap: () => DefaultTabController.of(context).animateTo(2),
            ),
            const SizedBox(height: 8),
            resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return const _EmptyCard(message: 'No results yet');
                }

                return _HubCard(
                  child: Column(
                    children: results.take(3).map((result) {
                      final paperSet =
                          result['paper_sets'] as Map<String, dynamic>?;
                      final examResult = result['exam_results'] as List?;
                      final title = paperSet?['title'] ?? 'Exam';
                      final totalMarks =
                          (paperSet?['total_marks'] as num?)?.toInt() ?? 100;

                      int score = 0;
                      bool passed = false;
                      if (examResult != null && examResult.isNotEmpty) {
                        final first = examResult.first as Map<String, dynamic>;
                        score = (first['marks_obtained'] as num?)?.toInt() ?? 0;
                        passed = first['passed'] == true;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              passed ? Icons.check_circle : Icons.cancel,
                              color: passed ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$score / $totalMarks marks',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _MiniBadge(label: passed ? 'Pass' : 'Fail'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, __) =>
                  const _EmptyCard(message: 'Failed to load results'),
            ),
            const SizedBox(height: 16),
            _HubSectionTitle(title: 'Quick Access'),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _QuickAccessCard(
                  icon: Icons.badge,
                  label: 'Admit Card',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppWebViewScreen(
                        url: WebUrls.admitCard,
                        title: 'Admit Card',
                      ),
                    ),
                  ),
                ),
                _QuickAccessCard(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'My Documents',
                  color: Colors.indigo,
                  onTap: () => context.push('/documents'),
                ),
                _QuickAccessCard(
                  icon: Icons.menu_book,
                  label: 'Study Material',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppWebViewScreen(
                        url: WebUrls.studyMaterial,
                        title: 'Study Material',
                      ),
                    ),
                  ),
                ),
                _QuickAccessCard(
                  icon: Icons.workspace_premium,
                  label: 'Certificates',
                  color: Colors.teal,
                  onTap: () => context.push('/documents'),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              _QuickAccessCard(
                icon: isAdmin ? Icons.admin_panel_settings : Icons.help_outline,
                label: isAdmin ? 'Admin Panel' : 'Help',
                color: isAdmin ? Colors.purple : Colors.blueGrey,
                onTap: isAdmin ? () => context.push('/admin') : () {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 1: Available Exams
// ═══════════════════════════════════════════════

class _AvailableExamsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examListProvider);

    return Container(
      color: AppColors.inkNavy900,
      child: examsAsync.when(
        data: (exams) {
          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No exams available right now',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for new exams',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return _ExamCard(exam: exam);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              const Text(
                'Failed to load exams',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(examListProvider),
                icon: const Icon(Icons.refresh, color: AppColors.goldCta),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.goldCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 2: My Results
// ═══════════════════════════════════════════════

class _MyResultsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsProvider);

    return Container(
      color: AppColors.inkNavy900,
      child: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No exam results yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete an exam to see your results here',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examResultsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _ResultCard(result: result);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              const Text(
                'Failed to load results',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(examResultsProvider),
                icon: const Icon(Icons.refresh, color: AppColors.goldCta),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.goldCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// EXAM CARD (Available Exams)
// ═══════════════════════════════════════════════

class _ExamCard extends StatelessWidget {
  final Exam exam;

  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldCta.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.push('/exam-instruction/${exam.id}', extra: exam),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exam Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Exam Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            text: '${exam.durationMinutes} min',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: Icons.quiz_outlined,
                            text: '${exam.questionsCount} Q',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: Icons.star_outline,
                            text: '${exam.totalMarks} marks',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldCta.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.goldCta,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// RESULT CARD (My Results)
// ═══════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final paperSet = result['paper_sets'] as Map<String, dynamic>?;
    final examResult = result['exam_results'] as List?;
    final title = paperSet?['title'] ?? 'Exam';
    final totalMarks = paperSet?['total_marks'] ?? 100;

    int score = 0;
    bool passed = false;
    if (examResult != null && examResult.isNotEmpty) {
      final r = examResult[0] as Map<String, dynamic>;
      score = (r['marks_obtained'] as num?)?.toInt() ?? 0;
      passed = r['passed'] == true;
    }

    final pct = totalMarks > 0 ? (score / totalMarks * 100) : 0.0;
    final color = passed ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldCta.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${pct.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score / $totalMarks marks',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Pass/Fail badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                passed ? 'PASS ✅' : 'FAIL ❌',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// INFO CHIP (small icon + text)
// ═══════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _HubSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _HubSectionTitle({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text(
              'View All',
              style: TextStyle(color: AppColors.goldCta),
            ),
          ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  final Widget child;

  const _HubCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldCta.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inkNavy700,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _HubCard(
      child: Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return _HubCard(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
