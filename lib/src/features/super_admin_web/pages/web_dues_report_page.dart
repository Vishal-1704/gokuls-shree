import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_fee_collection_screen.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

Future<void> _exportPdf(List<_Row> dues) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('Dues Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          headers: const ['Student', 'Reg No', 'Status', 'Due', 'Paid'],
          data: dues
              .map((row) => [
                    row['student_name']?.toString() ?? '-',
                    row['registration_number']?.toString() ?? '-',
                    row['status']?.toString().toUpperCase() ?? 'PENDING',
                    (row['due_amount'] as num?)?.toStringAsFixed(0) ?? '0',
                    (row['amount_paid'] as num?)?.toStringAsFixed(0) ?? '0',
                  ])
              .toList(),
        ),
      ],
    ),
  );
  await Printing.sharePdf(bytes: await pdf.save(), filename: 'dues_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
}

class WebDuesReportPage extends ConsumerStatefulWidget {
  const WebDuesReportPage({super.key});

  @override
  ConsumerState<WebDuesReportPage> createState() => _WebDuesReportPageState();
}

class _WebDuesReportPageState extends ConsumerState<WebDuesReportPage> {
  String _search = '';
  String _status = 'all';
  Object? _openId;

  @override
  Widget build(BuildContext context) {
    final dues = ref.watch(adminDuesReportProvider);

    return WebPage(
      title: 'Dues report',
      subtitle: 'Students with an outstanding fee balance',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => ref.invalidate(adminDuesReportProvider),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: dues.whenOrNull(data: (v) => v.isNotEmpty) == true ? () => _exportPdf(dues.value!) : null,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Export PDF'),
        ),
      ],
      child: dues.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(adminDuesReportProvider)),
        data: (all) {
          final totalDue = all.fold<double>(0, (s, r) => s + ((r['due_amount'] as num?)?.toDouble() ?? 0));
          final rows = all.where((r) {
            if (_status != 'all' && str(r['status'], 'pending') != _status) return false;
            if (_search.isEmpty) return true;
            return '${r['student_name']} ${r['registration_number']}'.toLowerCase().contains(_search);
          }).toList();
          final open = all.where((r) => r['student_id'] == _openId).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'TOTAL PENDING COLLECTION',
                      value: inr(totalDue),
                      icon: Icons.request_quote_outlined,
                      color: AppColors.danger,
                      hint: '${all.length} students with dues',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  WebSearchField(hint: 'Search student, reg no…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
                  const SizedBox(width: 10),
                  WebDropdown<String>(
                    value: _status,
                    items: const {'all': 'All statuses', 'pending': 'Pending', 'partial': 'Partial', 'overdue': 'Overdue'},
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const Spacer(),
                  Text('${rows.length} of ${all.length} students', style: AppTypography.bodySm),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: WebTable<_Row>(
                        columns: const [
                          WebColumn('Student', flex: 3),
                          WebColumn('Total', alignEnd: true),
                          WebColumn('Paid', alignEnd: true),
                          WebColumn('Due', alignEnd: true),
                          WebColumn('Status'),
                        ],
                        rows: rows,
                        keyOf: (r) => r['student_id'] as Object,
                        openKey: _openId,
                        onRowTap: (r) => setState(() => _openId = r['student_id']),
                        emptyTitle: all.isEmpty ? 'No pending dues' : 'No matches',
                        emptyMessage: all.isEmpty ? 'Every student is paid up.' : 'Try a different search or status.',
                        cells: (r) {
                          final status = str(r['status'], 'pending');
                          final color = status == 'overdue' ? AppColors.danger : AppColors.warning;
                          return [
                            CellText(str(r['student_name'], 'Unknown'), secondary: str(r['registration_number'])),
                            PlainCell(inr(r['total_amount'] as num?), alignEnd: true),
                            PlainCell(inr(r['amount_paid'] as num?), alignEnd: true, muted: true),
                            Text(
                              inr(r['due_amount'] as num?),
                              textAlign: TextAlign.right,
                              style: AppTypography.bodyMd.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                            ),
                            StatusChip(status[0].toUpperCase() + status.substring(1), color),
                          ];
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a student to see their fee breakdown and collect payment.')
                    else
                      DetailPanel(
                        onClose: () => setState(() => _openId = null),
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(str(open['student_name'], 'Unknown'), style: AppTypography.headingSm),
                            Text(str(open['registration_number']), style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                        actions: [
                          FilledButton.icon(
                            style: webPrimaryButton(),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminFeeCollectionScreen(
                                  student: {
                                    'id': open['student_id'],
                                    'name': open['student_name'],
                                    'reg_no': open['registration_number'],
                                    'course_name': open['course_name'],
                                    'due_amount': open['due_amount'],
                                    'total_fee': open['total_amount'],
                                    'paid_amount': open['amount_paid'],
                                    'photo_url': open['photo_url'],
                                  },
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: const Text('Collect fee'),
                          ),
                        ],
                        children: [
                          DetailSection('Fee summary', [
                            ('Course', str(open['course_name'])),
                            ('Total fee', inr(open['total_amount'] as num?)),
                            ('Paid', inr(open['amount_paid'] as num?)),
                            ('Due', inr(open['due_amount'] as num?)),
                          ]),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
