import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/widgets/webview_screen.dart';
import '../data/exam_repository.dart';
import '../domain/exam_model.dart';

final examListProvider = FutureProvider<List<Exam>>((ref) async {
  return ref.read(examRepositoryProvider).getExams();
});

// upcomingExamsProvider and examResultsProvider come from exam_repository.dart
// (imported below) — this file used to shadow both with local providers that
// read from a different, now-defunct data path, which meant this screen's
// "Upcoming Schedule" and "Recent Results" sections were silently reading
// the wrong data despite the correct providers being one import away.

class ExamListBody extends ConsumerWidget {
  const ExamListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.goldCta,
      onRefresh: () async {
        ref.invalidate(examListProvider);
        ref.invalidate(upcomingExamsProvider);
        ref.invalidate(examResultsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Upcoming Schedule'),
          const SizedBox(height: 12),
          _UpcomingScheduleSection(),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Active Exams'),
          const SizedBox(height: 12),
          _ActiveExamsSection(),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Recent Results'),
          const SizedBox(height: 12),
          _RecentResultsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SECTIONS
// ═══════════════════════════════════════════════

class _QuickActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == 'super_admin' || role == 'branch_admin';

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 60,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      children: [
        _QuickActionCard(
          icon: Icons.badge_outlined,
          label: 'Admit Card',
          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InAppWebViewScreen(url: WebUrls.admitCard, title: 'Admit Card'),
            ),
          ),
        ),
        _QuickActionCard(
          icon: Icons.menu_book_rounded,
          label: 'Study Material',
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InAppWebViewScreen(url: WebUrls.studyMaterial, title: 'Study Material'),
            ),
          ),
        ),
        if (isAdmin)
          _QuickActionCard(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin Panel',
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            onTap: () => context.push('/admin'),
          ),
      ],
    );
  }
}

class _UpcomingScheduleSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingExamsProvider);
    
    return upcomingAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_available,
            message: 'No upcoming scheduled exams.',
          );
        }
        return Column(
          children: items.map((exam) {
            final paper = exam['paper_sets'] as Map<String, dynamic>? ?? {};
            final title = paper['title']?.toString() ?? exam['title']?.toString() ?? 'Exam';
            final startAt = DateTime.tryParse((exam['start_at'] ?? '').toString());
            final date = startAt != null
                ? '${startAt.day.toString().padLeft(2, '0')}/${startAt.month.toString().padLeft(2, '0')}/${startAt.year}'
                : 'TBA';
            return _ScheduleCard(
              title: title,
              date: date,
              status: exam['status']?.toString() ?? 'Upcoming',
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (_, __) => const _EmptyState(icon: Icons.error_outline, message: 'Failed to load schedule'),
    );
  }
}

class _ActiveExamsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examListProvider);
    
    return examsAsync.when(
      data: (exams) {
        if (exams.isEmpty) {
          return const _EmptyState(
            icon: Icons.quiz_outlined,
            message: 'No exams currently active for you to take.',
          );
        }
        return Column(
          children: exams.map((exam) => _ExamCard(exam: exam)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (_, __) => const _EmptyState(icon: Icons.error_outline, message: 'Failed to load exams'),
    );
  }
}

class _RecentResultsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsProvider);
    
    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const _EmptyState(
            icon: Icons.assessment_outlined,
            message: 'No exam results yet.',
          );
        }
        return Column(
          children: results.map((r) => _ResultCard(result: r)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (_, __) => const _EmptyState(icon: Icons.error_outline, message: 'Failed to load results'),
    );
  }
}

// ═══════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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

class _ScheduleCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const _ScheduleCard({required this.title, required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.inkNavy700, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.goldCta, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.inkNavy700, borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/exam-instruction/${exam.id}', extra: exam),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.goldCta, AppColors.goldShine]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _InfoChip(icon: Icons.timer_outlined, text: '${exam.durationMinutes}m'),
                          const SizedBox(width: 12),
                          _InfoChip(icon: Icons.quiz_outlined, text: '${exam.questionsCount}Q'),
                          const SizedBox(width: 12),
                          _InfoChip(icon: Icons.star_outline, text: '${exam.totalMarks} Marks'),
                        ],
                      ),
                    ],
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

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final schedule = result['schedules'] as Map<String, dynamic>?;
    final paper = schedule?['paper_sets'] as Map<String, dynamic>?;
    final title = schedule?['title'] ?? paper?['title'] ?? 'Exam';
    final totalMarks = (result['total_marks'] as num?)?.toInt() ?? 100;
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final passed = result['result'] == 'pass';

    final pct = totalMarks > 0 ? (score / totalMarks * 100) : 0.0;
    final color = passed ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${pct.toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$score / $totalMarks marks', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(passed ? 'PASS' : 'FAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

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
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider10, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
