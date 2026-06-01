import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
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
          pw.Text('Reg No: ${student['registration_number'] ?? '-'}'),
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
          'Reg No: ${student['registration_number'] ?? '-'}\n'
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
          final selectedStudent = students
              .where((s) {
                return s['id']?.toString() == _studentId;
              })
              .cast<Map<String, dynamic>>()
              .toList();

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _studentId,
                  decoration: const InputDecoration(
                    labelText: 'Select Student',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  items: students
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s['id'].toString(),
                          child: Text(
                            '${s['name'] ?? 'Unknown'} (${s['reg_no'] ?? 'N/A'})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _studentId = v),
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
