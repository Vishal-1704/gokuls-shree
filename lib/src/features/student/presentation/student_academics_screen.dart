import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import '../../documents/presentation/my_documents_screen.dart';
import 'student_test_list_screen.dart';
import 'student_exam_report_screen.dart';

/// Academics Hub — a tappable card grid instead of a 5-wide scrollable
/// TabBar. The old tabs (Online Tests, Exams, Exam Report, Study Material,
/// Documents) hid content behind equal-weight text labels with half of
/// them scrolled off-screen; this shows a live count on each card so a
/// student knows what's inside before tapping in.
class StudentAcademicsScreen extends ConsumerWidget {
  const StudentAcademicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingExamsProvider);
    final resultsAsync = ref.watch(examResultsProvider);
    final marksheetsAsync = ref.watch(studentMarksheetsProvider);
    final certificatesAsync = ref.watch(studentCertificatesProvider);

    int countByType(AsyncValue<List<Map<String, dynamic>>> async, String type) {
      return async.maybeWhen(
        data: (rows) => rows.where((e) => (e['assessment_type'] ?? 'exam') == type).length,
        orElse: () => 0,
      );
    }

    String bestResultLabel(AsyncValue<List<Map<String, dynamic>>> async) {
      return async.maybeWhen(
        data: (rows) {
          if (rows.isEmpty) return 'No results yet';
          num best = 0;
          for (final r in rows) {
            final score = (r['score'] as num?) ?? 0;
            final total = (r['total_marks'] as num?) ?? 0;
            if (total <= 0) continue;
            final pct = (score / total) * 100;
            if (pct > best) best = pct;
          }
          return 'Best: ${best.toStringAsFixed(0)}%';
        },
        orElse: () => 'Loading…',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Academics Hub',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _HubCard(
                  icon: Icons.edit_note_rounded,
                  color: AppColors.info,
                  title: 'Online Tests',
                  subtitle: '${countByType(upcomingAsync, 'test')} available',
                  onTap: () => _openTab(context, 0),
                ),
                _HubCard(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.primaryViolet,
                  title: 'Exams',
                  subtitle: '${countByType(upcomingAsync, 'exam')} upcoming',
                  onTap: () => _openTab(context, 1),
                ),
                _HubCard(
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.success,
                  title: 'Exam Report',
                  subtitle: bestResultLabel(resultsAsync),
                  onTap: () => _openTab(context, 2),
                ),
                _HubCard(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.warning,
                  title: 'Study Material',
                  subtitle: '0 files',
                  onTap: () => _openTab(context, 3),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Documents', style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DocMiniCard(
                    icon: Icons.badge_rounded,
                    color: Colors.teal,
                    label: 'Admit Card',
                    count: 0, // no admit-card feature exists yet — always 0
                    onTap: () => _openTab(context, 4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DocMiniCard(
                    icon: Icons.description_rounded,
                    color: Colors.blue,
                    label: 'Marksheet',
                    count: marksheetsAsync.maybeWhen(data: (r) => r.length, orElse: () => 0),
                    onTap: () => _openTab(context, 4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DocMiniCard(
                    icon: Icons.workspace_premium_rounded,
                    color: Colors.orange,
                    label: 'Certificate',
                    count: certificatesAsync.maybeWhen(data: (r) => r.length, orElse: () => 0),
                    onTap: () => _openTab(context, 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    const titles = ['Online Tests', 'Exams', 'Exam Report', 'Study Material', 'Documents'];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AcademicsSectionScreen(title: titles[index], index: index),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DocMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _DocMiniCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text('$count', style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary)),
            Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Full-screen destination for a single hub section — reuses the exact
/// same body widgets the old TabBarView rendered, just navigated to
/// directly instead of swiped between.
class _AcademicsSectionScreen extends StatelessWidget {
  final String title;
  final int index;

  const _AcademicsSectionScreen({required this.title, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _bodyFor(index),
    );
  }

  Widget _bodyFor(int index) {
    switch (index) {
      case 0:
        return const StudentTestListGrid(assessmentType: 'test');
      case 1:
        return const StudentTestListGrid(assessmentType: 'exam');
      case 2:
        return const StudentExamReportGrid();
      case 3:
        return const _StudyMaterialEmptyState();
      case 4:
      default:
        return const MyDocumentsBody();
    }
  }
}

class _StudyMaterialEmptyState extends StatelessWidget {
  const _StudyMaterialEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.inkNavy800, shape: BoxShape.circle),
            child: const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Study Material',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Course materials will appear here\nonce uploaded by your teachers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
