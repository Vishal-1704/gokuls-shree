import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import '../widgets/web_ui.dart';

class WebReportsPage extends ConsumerWidget {
  const WebReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final studentsAsync = ref.watch(adminStudentsProvider);
    final duesAsync = ref.watch(adminDuesReportProvider);
    final revenueAsync = ref.watch(adminRevenueByBranchProvider);

    final branches = branchesAsync.whenOrNull(data: (v) => v);
    final students = studentsAsync.whenOrNull(data: (v) => v);
    final dues = duesAsync.whenOrNull(data: (v) => v);
    final revenue = revenueAsync.whenOrNull(data: (v) => v);

    final totalRevenue = revenue?.fold<double>(0, (s, r) => s + ((r['total_revenue'] as num?) ?? 0));
    final totalDue = dues?.fold<double>(0, (s, r) => s + ((r['due_amount'] as num?) ?? 0));
    final active = students?.where((s) => s['status'] == 1).length;
    final error = [branchesAsync, studentsAsync, duesAsync, revenueAsync].where((a) => a.hasError).firstOrNull;

    void refresh() {
      ref.invalidate(branchesProvider);
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDuesReportProvider);
      ref.invalidate(adminRevenueByBranchProvider);
    }

    return WebPage(
      title: 'Reports',
      subtitle: 'Revenue, enrolment and dues compared across branches',
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: refresh,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: error != null
          ? SizedBox(height: 320, child: WebError(error.error!, onRetry: refresh))
          : LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 1000;
                final kpis = [
                  StatTile(label: 'TOTAL REVENUE', value: totalRevenue == null ? '…' : inr(totalRevenue), icon: Icons.payments_outlined, color: AppColors.success),
                  StatTile(label: 'ACTIVE STUDENTS', value: active == null ? '…' : '$active', icon: Icons.school_outlined),
                  StatTile(label: 'BRANCHES', value: branches == null ? '…' : '${branches.length}', icon: Icons.account_balance_outlined, color: AppColors.primaryIndigo),
                  StatTile(
                    label: 'OUTSTANDING DUES',
                    value: totalDue == null ? '…' : inr(totalDue),
                    icon: Icons.request_quote_outlined,
                    color: AppColors.danger,
                    hint: dues == null ? null : '${dues.length} students',
                  ),
                ];

                final revenuePanel = WebPanel(
                  title: 'Revenue by branch',
                  child: revenue == null
                      ? const Padding(padding: EdgeInsets.all(24), child: webLoading)
                      : RevenueBarChart(
                          items: revenue.map((r) => (str(r['branch_name']), (r['total_revenue'] as num?)?.toDouble() ?? 0.0)).toList(),
                        ),
                );

                final comparison = WebPanel(
                  title: 'Branch comparison',
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: (branches == null || students == null || dues == null || revenue == null)
                      ? const Padding(padding: EdgeInsets.all(24), child: webLoading)
                      : _ComparisonTable(branches: branches, students: students, dues: dues, revenue: revenue),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(children: [
                        for (var i = 0; i < kpis.length; i++) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: kpis[i])],
                      ])
                    else
                      Wrap(spacing: 14, runSpacing: 14, children: [for (final k in kpis) SizedBox(width: (c.maxWidth - 14) / 2, child: k)]),
                    const SizedBox(height: 20),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(flex: 2, child: revenuePanel), const SizedBox(width: 20), Expanded(flex: 3, child: comparison)],
                      )
                    else ...[revenuePanel, const SizedBox(height: 20), comparison],
                    const SizedBox(height: 20),
                    const _ReportLinks(),
                  ],
                );
              },
            ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.branches, required this.students, required this.dues, required this.revenue});

  final List<Map<String, dynamic>> branches, students, dues, revenue;

  @override
  Widget build(BuildContext context) {
    final revenueBy = {for (final r in revenue) r['branch_id']: (r['total_revenue'] as num?)?.toDouble() ?? 0};
    final rows = [
      for (final b in branches)
        (
          name: str(b['name'], 'Branch ${b['id']}'),
          active: students.where((s) => s['branch_id'] == b['id'] && s['status'] == 1).length,
          pending: students.where((s) => s['branch_id'] == b['id'] && s['status'] == 0).length,
          dueAmt: dues.where((d) => d['branch_id'] == b['id']).fold<double>(0, (s, d) => s + ((d['due_amount'] as num?) ?? 0)),
          revenue: revenueBy[b['id']] ?? 0.0,
        ),
    ]..sort((a, b) => b.revenue.compareTo(a.revenue));

    const headers = [('Branch', 3, false), ('Active', 1, true), ('Pending', 1, true), ('Dues', 2, true), ('Revenue', 2, true)];
    TextStyle num0 = AppTypography.bodyMd.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    Widget cell(String t, int flex, bool end, {TextStyle? style}) => Expanded(
          flex: flex,
          child: Text(t, textAlign: end ? TextAlign.end : TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis, style: style ?? num0),
        );

    return Column(
      children: [
        Row(children: [
          for (final (h, f, e) in headers)
            cell(h.toUpperCase(), f, e, style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.6)),
        ]),
        const Divider(height: 18, color: AppColors.divider),
        for (final r in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              cell(r.name, 3, false, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              cell('${r.active}', 1, true),
              cell('${r.pending}', 1, true, style: num0.copyWith(color: r.pending > 0 ? AppColors.warning : null)),
              cell(r.dueAmt > 0 ? inr(r.dueAmt) : '—', 2, true, style: num0.copyWith(color: r.dueAmt > 0 ? AppColors.danger : AppColors.textMuted)),
              cell(inr(r.revenue), 2, true, style: num0.copyWith(color: AppColors.goldDeep, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.inkNavy700),
        ],
      ],
    );
  }
}

class _ReportLinks extends StatelessWidget {
  const _ReportLinks();

  static const _links = [
    ('Fee dues report', 'Outstanding balances per student', Icons.request_quote_outlined, '/admin/dues-report'),
    ('Collect fee', 'Record a payment', Icons.payments_outlined, '/admin/fee-collection'),
    ('Marksheets & certificates', 'Generate official documents', Icons.workspace_premium_outlined, '/admin/marksheet-generator'),
    ('Results entry', 'Record subject marks', Icons.edit_note_outlined, '/super-admin/results-entry'),
    ('Published results', 'Rosters and scores for online exams', Icons.fact_check_outlined, '/super-admin/schedule-results'),
    ('Exam scheduler', 'Plan upcoming tests and exams', Icons.event_note_outlined, '/super-admin/exam-scheduler'),
  ];

  @override
  Widget build(BuildContext context) {
    return WebPanel(
      title: 'Detailed reports & tools',
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (title, sub, icon, path) in _links)
                SizedBox(
                  width: w,
                  child: Material(
                    color: AppColors.inkNavy900,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.go(path),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(icon, color: AppColors.goldDeep, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CellText(title, secondary: sub),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
