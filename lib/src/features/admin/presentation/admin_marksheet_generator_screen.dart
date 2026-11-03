import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_results_entry_screen.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/marksheet_viewer_screen.dart';

class AdminMarksheetGeneratorScreen extends ConsumerStatefulWidget {
  const AdminMarksheetGeneratorScreen({super.key});

  @override
  ConsumerState<AdminMarksheetGeneratorScreen> createState() =>
      _AdminMarksheetGeneratorScreenState();
}

class _AdminMarksheetGeneratorScreenState
    extends ConsumerState<AdminMarksheetGeneratorScreen> {
  int? _branchId;
  int? _courseId;
  String? _year;
  String? _studentId;
  bool _isPreparing = false;

  Future<void> _prepareMarksheet(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> rows,
  ) async {
    setState(() => _isPreparing = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final obtained = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['marks_obtained'] as num?)?.toDouble() ?? 0),
    );
    final total = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['total_marks'] as num?)?.toDouble() ?? 0),
    );
    final percent = total <= 0 ? 0 : (obtained / total) * 100;
    final grade = percent >= 75
        ? 'A+'
        : percent >= 60
            ? 'A'
            : percent >= 50
                ? 'B'
                : percent >= 40
                    ? 'C'
                    : 'F';
    final result = percent >= 40 ? 'PASS' : 'FAIL';

    final marksheetData = <String, dynamic>{
      'id': student['reg_no'] ?? 'PREVIEW',
      'result': result,
      'obtained_marks': obtained.toInt(),
      'total_marks': total.toInt(),
      'percentage': percent.toStringAsFixed(2),
      'grade': grade,
      'issue_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'students': student,
      'courses': student['courses'] ??
          {'name': 'Academic Course', 'duration': '1 Year'},
      'branches': student['branches'],
      'subjects': rows
          .map((r) => {
                'name': r['subject_name'] ?? 'Subject',
                'max': (r['total_marks'] as num?)?.toInt() ?? 100,
                'theory': (r['marks_obtained'] as num?)?.toInt() ?? 0,
                'max_marks': (r['total_marks'] as num?)?.toInt() ?? 100,
                'marks_obtained': (r['marks_obtained'] as num?)?.toInt() ?? 0,
                'grade': r['grade'] ?? 'B',
              })
          .toList(),
      'signature_hash': 'OFFICIAL_DIGITAL_SIGNATURE',
    };

    if (!mounted) return;
    setState(() => _isPreparing = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarksheetViewerScreen(marksheet: marksheetData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final coursesAsync = ref.watch(adminCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'Marksheet Generator',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (e, _) => Center(
          child: Text(
            'Unable to load students: $e',
            style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
          ),
        ),
        data: (students) {
          final branches = branchesAsync.value ?? [];
          final courses = coursesAsync.value ?? [];
          
          // Generate unique years from the student data based on 'doj' (date of joining) or just fallback to generic
          final yearsSet = <String>{};
          for (final s in students) {
             if (s['doj'] != null) {
                try {
                  final year = DateTime.parse(s['doj'].toString()).year.toString();
                  yearsSet.add(year);
                } catch(_) {}
             }
          }
          final years = yearsSet.toList()..sort();

          // Filter logic — "All Branches"/"All Courses" carry value: null,
          // so this must default to showing everyone and narrow from there,
          // not default to empty and only populate once a specific filter
          // is picked (that previously made the list look like it could
          // never load any students at all).
          var filteredStudents = students;
          if (_branchId != null) {
             filteredStudents = filteredStudents.where((s) => s['branch_id']?.toString() == _branchId.toString()).toList();
          }
          if (_courseId != null) {
             filteredStudents = filteredStudents.where((s) => s['course_id']?.toString() == _courseId.toString()).toList();
          }
          if (_year != null) {
             filteredStudents = filteredStudents.where((s) {
                 if (s['doj'] == null) return false;
                 try {
                     return DateTime.parse(s['doj'].toString()).year.toString() == _year;
                 } catch(_) { return false; }
             }).toList();
          }

          final selectedStudent = students
              .where((s) => s['id']?.toString() == _studentId)
              .cast<Map<String, dynamic>>()
              .toList();

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 600 ? double.infinity : (MediaQuery.of(context).size.width - 64) / 3,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: _branchId,
                        dropdownColor: AppColors.inkNavy800,
                        iconEnabledColor: AppColors.goldCta,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('All Branches', style: TextStyle(color: AppColors.textPrimary))),
                          ...branches.map((b) => DropdownMenuItem<int>(
                              value: b['id'], 
                              child: Text(b['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary)),
                          ))
                        ],
                        onChanged: (v) => setState(() { _branchId = v; _studentId = null; }),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 600 ? double.infinity : (MediaQuery.of(context).size.width - 64) / 3,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: _courseId,
                        dropdownColor: AppColors.inkNavy800,
                        iconEnabledColor: AppColors.goldCta,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('All Courses', style: TextStyle(color: AppColors.textPrimary))),
                          ...courses.map((c) => DropdownMenuItem<int>(
                              value: c['id'], 
                              child: Text(c['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary)),
                          ))
                        ],
                        onChanged: (v) => setState(() { _courseId = v; _studentId = null; }),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 600 ? double.infinity : (MediaQuery.of(context).size.width - 64) / 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _year,
                        dropdownColor: AppColors.inkNavy800,
                        iconEnabledColor: AppColors.goldCta,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Years', style: TextStyle(color: AppColors.textPrimary))),
                          ...years.map((y) => DropdownMenuItem<String>(
                              value: y, 
                              child: Text(y, style: const TextStyle(color: AppColors.textPrimary)),
                          ))
                        ],
                        onChanged: (v) => setState(() { _year = v; _studentId = null; }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: filteredStudents.any((s) => s['id'].toString() == _studentId)
                      ? _studentId
                      : null,
                  dropdownColor: AppColors.inkNavy800,
                  iconEnabledColor: AppColors.goldCta,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Select Student',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  hint: const Text(
                    'Select a student',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  items: filteredStudents.isEmpty
                      ? [
                          const DropdownMenuItem<String>(
                            value: null,
                            enabled: false,
                            child: Text(
                              'No students match current filter',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ]
                      : filteredStudents
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s['id'].toString(),
                              child: Text(
                                '${s['name'] ?? 'Unknown'} (${s['reg_no'] ?? 'N/A'})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: filteredStudents.isEmpty
                      ? null
                      : (v) => setState(() => _studentId = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_studentId != null && selectedStudent.isNotEmpty)
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ref
                          .read(adminRepositoryProvider)
                          .getStudentMarksheetData(_studentId!),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load result rows: ${snap.error}',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.danger,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.goldCta,
                            ),
                          );
                        }

                        final rows = snap.data!;
                        if (rows.isEmpty) {
                          final studentName = selectedStudent.isNotEmpty
                              ? (selectedStudent.first['name'] ?? 'this student')
                              : 'this student';
                          return Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldCta.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.assignment_late_outlined,
                                      size: 48,
                                      color: AppColors.goldCta,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Exam Marks Found',
                                    style: AppTypography.headingSm.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No exam or test scores have been entered for $studentName yet. Marks must be entered first to generate their marksheet.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminResultsEntryScreen(
                                            initialStudentId: _studentId,
                                          ),
                                        ),
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.goldCta,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(
                                      Icons.add_chart_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Enter Marks for this Student',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Result Rows (${rows.length})',
                              style: AppTypography.headingSm.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(
                              child: ListView.separated(
                                itemCount: rows.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  return Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row['subject_name']?.toString() ??
                                                'Subject',
                                            style: AppTypography.bodyMd
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${row['marks_obtained'] ?? 0}/${row['total_marks'] ?? 0}',
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.goldCta,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldCta,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _isPreparing
                                    ? null
                                    : () => _prepareMarksheet(
                                        selectedStudent.first,
                                        rows,
                                      ),
                                icon: _isPreparing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.workspace_premium_rounded, size: 22),
                                label: Text(
                                  _isPreparing
                                      ? 'Preparing Marksheet...'
                                      : 'Preview & Export Official Marksheet',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
