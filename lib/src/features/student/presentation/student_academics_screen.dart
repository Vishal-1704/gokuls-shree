import 'student_admit_card_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../admin/data/admin_repository.dart';
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
    final profileAsync = ref.watch(studentProfileProvider);
    final studyMaterialsAsync = ref.watch(studyMaterialsProvider);

    int countByType(AsyncValue<List<Map<String, dynamic>>> async, String type) {
      return async.maybeWhen(
        data: (rows) => rows.where((e) {
          final t = e['assessment_type'] ?? (e['paper_sets'] as Map?)?['assessment_type'] ?? 'exam';
          return t.toString().toLowerCase() == type.toLowerCase();
        }).length,
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
            profileAsync.maybeWhen(
              data: (profile) {
                final courseName = (profile['class_section'] ?? 'Enrolled Course').toString();
                final program = profile['program']?.toString();
                final regNo = (profile['reg_no'] ?? 'N/A').toString();
                final enrollments = (profile['enrollments'] as List?) ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EnrolledCourseCard(
                      courseName: courseName,
                      program: program,
                      regNo: regNo,
                      enrollmentsCount: enrollments.length,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Academic Activities',
                      style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
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
                  icon: Icons.history_edu_rounded,
                  color: AppColors.success,
                  title: 'Exam History',
                  subtitle: bestResultLabel(resultsAsync),
                  onTap: () => _openTab(context, 2),
                ),
                _HubCard(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.warning,
                  title: 'Study Material',
                  subtitle: studyMaterialsAsync.maybeWhen(
                    data: (list) => '${list.length} ${list.length == 1 ? "file" : "files"}',
                    orElse: () => '0 files',
                  ),
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
                    count: profileAsync.maybeWhen(data: (_) => 1, orElse: () => 0),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentAdmitCardScreen(),
                        ),
                      );
                    },
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
    const titles = ['Online Tests', 'Exams', 'Exam History', 'Study Material', 'Documents'];
    Navigator.of(context, rootNavigator: true).push(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const SizedBox(height: 6),
            Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        return const StudentStudyMaterialList();
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

class _EnrolledCourseCard extends StatelessWidget {
  const _EnrolledCourseCard({
    required this.courseName,
    this.program,
    required this.regNo,
    required this.enrollmentsCount,
  });

  final String courseName;
  final String? program;
  final String regNo;
  final int enrollmentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldCta.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.goldCta,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'MY COURSE',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.goldCta,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (enrollmentsCount > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryViolet.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$enrollmentsCount Courses',
                              style: const TextStyle(
                                color: AppColors.primaryViolet,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      courseName,
                      style: AppTypography.headingSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Active',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (program != null && program != 'N/A' && program!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.inkNavy900.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Category: $program',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider10),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 14, color: AppColors.goldCta),
              const SizedBox(width: 6),
              Text(
                'Reg. No: $regNo',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class StudentStudyMaterialList extends ConsumerWidget {
  const StudentStudyMaterialList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(studyMaterialsProvider);

    return materialsAsync.when(
      data: (materials) {
        if (materials.isEmpty) {
          return const _StudyMaterialEmptyState();
        }

        return RefreshIndicator(
          color: AppColors.goldCta,
          onRefresh: () async => ref.refresh(studyMaterialsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = materials[index];
              final title = (item['title'] ?? 'Study Material').toString();
              final subject = (item['subject'] ?? item['program'] ?? 'General').toString();
              final desc = (item['description'] ?? '').toString();
              final url = (item['url'] ?? item['file_url'] ?? '').toString();
              final createdAt = item['created_at'] != null
                  ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now())
                  : null;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description_rounded, color: AppColors.warning, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  subject,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        desc,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (createdAt != null)
                          Text(
                            createdAt,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          )
                        else
                          const SizedBox.shrink(),
                        if (url.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldCta,
                              foregroundColor: AppColors.inkNavy900,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open / View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open file link')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading materials: $e', style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }
}
