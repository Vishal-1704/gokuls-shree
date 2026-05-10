import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDuesReportScreen extends ConsumerWidget {
  const AdminDuesReportScreen({super.key});

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, dynamic>> dues,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Dues Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['Student', 'Reg No', 'Status', 'Due', 'Paid'],
            data: dues
                .map(
                  (row) => [
                    row['student_name']?.toString() ?? '-',
                    row['registration_number']?.toString() ?? '-',
                    row['status']?.toString().toUpperCase() ?? 'PENDING',
                    (row['due_amount'] as num?)?.toStringAsFixed(0) ?? '0',
                    (row['amount_paid'] as num?)?.toStringAsFixed(0) ?? '0',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'dues_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(adminDuesReportProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'Dues Report',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: duesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Text(
              'Unable to load dues report: $e',
              style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (dues) {
          final totalDue = dues.fold<double>(
            0,
            (sum, item) =>
                sum + ((item['due_amount'] as num?)?.toDouble() ?? 0),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: OutlinedButton.icon(
                  onPressed: dues.isEmpty
                      ? null
                      : () => _exportPdf(context, dues),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSpacing.screenPadding),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pending Collection',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'INR ${totalDue.toStringAsFixed(0)}',
                      style: AppTypography.headingLg.copyWith(
                        color: AppColors.goldCta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dues.length} students with pending amount',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: dues.isEmpty
                    ? Center(
                        child: Text(
                          'No pending dues found',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          0,
                          AppSpacing.screenPadding,
                          AppSpacing.screenPadding,
                        ),
                        itemCount: dues.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = dues[index];
                          final due =
                              (item['due_amount'] as num?)?.toDouble() ?? 0;
                          final paid =
                              (item['amount_paid'] as num?)?.toDouble() ?? 0;
                          final total =
                              (item['total_amount'] as num?)?.toDouble() ?? 0;
                          final status = (item['status'] ?? 'pending')
                              .toString();

                          final statusColor = status == 'overdue'
                              ? AppColors.danger
                              : AppColors.warning;

                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['student_name']?.toString() ??
                                            'Unknown',
                                        style: AppTypography.bodyLg.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: AppTypography.bodySm.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reg: ${item['registration_number'] ?? '-'}',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Due: INR ${due.toStringAsFixed(0)}',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.goldCta,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Paid ${paid.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
