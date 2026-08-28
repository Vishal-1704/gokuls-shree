import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _exportSummaryPdf(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> rows,
  ) async {
    final obtained = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['marks_obtained'] as num?)?.toDouble() ?? 0),
    );
    final total = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['total_marks'] as num?)?.toDouble() ?? 0),
    );
    final percent = total <= 0 ? 0 : (obtained / total) * 100;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Marksheet Summary',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Student: ${student['name'] ?? 'Unknown'}'),
          pw.Text('Reg No: ${student['reg_no'] ?? '-'}'),
          pw.Text(
            'Total: ${obtained.toStringAsFixed(0)} / ${total.toStringAsFixed(0)} (${percent.toStringAsFixed(2)}%)',
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['Subject', 'Obtained', 'Total', 'Grade'],
            data: rows
                .map(
                  (row) => [
                    row['subject_name']?.toString() ?? '-',
                    (row['marks_obtained'] as num?)?.toStringAsFixed(0) ?? '0',
                    (row['total_marks'] as num?)?.toStringAsFixed(0) ?? '0',
                    row['grade']?.toString() ?? '-',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'marksheet_summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _prepareMarksheet(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> rows,
  ) async {
    setState(() => _isPreparing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final obtained = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['marks_obtained'] as num?)?.toDouble() ?? 0),
    );
    final total = rows.fold<double>(
      0,
      (sum, r) => sum + ((r['total_marks'] as num?)?.toDouble() ?? 0),
    );
    final percent = total <= 0 ? 0 : (obtained / total) * 100;

    if (!mounted) return;
    setState(() => _isPreparing = false);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Marksheet Data Ready',
          style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Student: ${student['name'] ?? 'Unknown'}\n'
          'Reg No: ${student['reg_no'] ?? '-'}\n'
          'Subjects: ${rows.length}\n'
          'Total: ${obtained.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}\n'
          'Percentage: ${percent.toStringAsFixed(2)}%',
          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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

          // Filter logic
          var filteredStudents = <Map<String, dynamic>>[];
          final hasFilter = _branchId != null || _courseId != null || _year != null;
          
          if (hasFilter) {
            filteredStudents = students;
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
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('All Branches')),
                          ...branches.map((b) => DropdownMenuItem<int>(
                              value: b['id'], 
                              child: Text(b['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
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
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('All Courses')),
                          ...courses.map((c) => DropdownMenuItem<int>(
                              value: c['id'], 
                              child: Text(c['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
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
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Years')),
                          ...years.map((y) => DropdownMenuItem<String>(
                              value: y, 
                              child: Text(y),
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
                  value: _studentId,
                  dropdownColor: AppColors.inkNavy800,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Select Student',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  hint: Text(
                    hasFilter ? 'Select a student' : 'Select Branch, Course, and Year first...',
                    style: TextStyle(
                      color: hasFilter ? AppColors.textMuted : Colors.orangeAccent,
                    ),
                  ),
                  items: filteredStudents
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s['id'].toString(),
                          child: Text(
                            '${s['name'] ?? 'Unknown'} (${s['reg_no'] ?? 'N/A'})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: hasFilter ? (v) => setState(() => _studentId = v) : null,
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
                          return Center(
                            child: Text(
                              'No result rows found for this student.',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.textSecondary,
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
                                onPressed: _isPreparing
                                    ? null
                                    : () => _prepareMarksheet(
                                        selectedStudent.first,
                                        rows,
                                      ),
                                icon: _isPreparing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_outlined),
                                label: Text(
                                  _isPreparing
                                      ? 'Preparing...'
                                      : 'Prepare Marksheet Summary',
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _exportSummaryPdf(
                                  selectedStudent.first,
                                  rows,
                                ),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Export PDF'),
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
