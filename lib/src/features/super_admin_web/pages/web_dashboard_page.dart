import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import '../web_providers.dart';
import '../widgets/web_ui.dart';

class WebDashboardPage extends ConsumerWidget {
  const WebDashboardPage({super.key});

  void _refresh(WidgetRef ref) {
    invalidatePendingApprovals(ref);
    ref.invalidate(adminStudentsProvider);
    ref.invalidate(branchesProvider);
    ref.invalidate(adminRevenueByBranchProvider);
    ref.invalidate(adminDuesReportProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTotal = ref.watch(webPendingTotalProvider);
    final students = ref.watch(adminStudentsProvider);
    final branches = ref.watch(branchesProvider);
    final revenue = ref.watch(adminRevenueByBranchProvider);
    final dues = ref.watch(adminDuesReportProvider);

    String count(AsyncValue<List<Map<String, dynamic>>> v, bool Function(Map<String, dynamic>) test) =>
        v.whenOrNull(data: (rows) => '${rows.where(test).length}') ?? '…';

    final totalRevenue = revenue.whenOrNull(
      data: (rows) => rows.fold<double>(0, (s, r) => s + ((r['total_revenue'] as num?) ?? 0)),
    );
    final dueRows = dues.whenOrNull(data: (rows) => rows);
    final totalDue = dueRows?.fold<double>(0, (s, r) => s + ((r['due_amount'] as num?) ?? 0));

    return WebPage(
      title: 'Dashboard',
      subtitle: 'Everything across all branches at a glance',
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => _refresh(ref),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: () => context.go('/super-admin/add-student'),
          icon: const Icon(Icons.person_add_alt_rounded, size: 18),
          label: const Text('Add student'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final kpis = [
            StatTile(
              label: 'PENDING APPROVALS',
              value: pendingTotal.whenOrNull(data: (n) => '$n') ?? '…',
              icon: Icons.fact_check_outlined,
              color: AppColors.warning,
              hint: 'Registrations, documents, payroll',
              onTap: () => context.go('/super-admin/approvals'),
            ),
            StatTile(
              label: 'ACTIVE STUDENTS',
              value: count(students, (s) => s['status'] == 1),
              icon: Icons.school_outlined,
              onTap: () => context.go('/super-admin/students'),
            ),
            StatTile(
              label: 'ACTIVE BRANCHES',
              value: count(branches, (b) => b['status'] == 1),
              icon: Icons.account_balance_outlined,
              color: AppColors.primaryIndigo,
              hint: branches.whenOrNull(data: (b) => 'of ${b.length} total'),
              onTap: () => context.go('/super-admin/branches'),
            ),
            StatTile(
              label: 'TOTAL REVENUE',
              value: totalRevenue == null ? '…' : inr(totalRevenue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
              hint: 'All-time fee collections',
              onTap: () => context.go('/super-admin/reports'),
            ),
            StatTile(
              label: 'OUTSTANDING DUES',
              value: totalDue == null ? '…' : inr(totalDue),
              icon: Icons.request_quote_outlined,
              color: AppColors.danger,
              hint: dueRows == null ? null : '${dueRows.length} students',
              onTap: () => context.go('/admin/dues-report'),
            ),
          ];

          final attention = _AttentionPanel();
          final revenuePanel = _RevenuePanel(revenue: revenue);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(children: [
                  for (var i = 0; i < kpis.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: kpis[i]),
                  ],
                ])
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [for (final k in kpis) SizedBox(width: (constraints.maxWidth - 14) / 2, child: k)],
                ),
              const SizedBox(height: 20),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: attention),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: revenuePanel),
                  ],
                )
              else ...[
                attention,
                const SizedBox(height: 20),
                revenuePanel,
              ],
              const SizedBox(height: 20),
              const _QuickActions(),
            ],
          );
        },
      ),
    );
  }
}

class _AttentionPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(webPendingStudentsProvider);
    final docs = ref.watch(webPendingDocumentsProvider);
    final exp = ref.watch(webPendingExpCertsProvider);
    final salary = ref.watch(webPendingSalaryProvider);

    Widget queueRow(String label, IconData icon, AsyncValue<int> n) {
      final value = n.whenOrNull(data: (v) => v);
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/super-admin/approvals'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppTypography.bodyMd)),
              Text(
                value == null ? '…' : '$value pending',
                style: AppTypography.labelMd.copyWith(
                  color: (value ?? 0) > 0 ? AppColors.warning : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WebPanel(
      title: 'Needs your attention',
      trailing: TextButton(onPressed: () => context.go('/super-admin/approvals'), child: const Text('Open approvals')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          queueRow('Student registrations', Icons.person_outline, students.whenData((v) => v.length)),
          queueRow('Marksheets', Icons.description_outlined, docs.whenData((v) => v['marksheets']?.length ?? 0)),
          queueRow('Certificates', Icons.workspace_premium_outlined, docs.whenData((v) => v['certificates']?.length ?? 0)),
          queueRow('Experience certificates', Icons.badge_outlined, exp.whenData((v) => v.length)),
          queueRow('Salary revisions', Icons.trending_up_outlined, salary.whenData((v) => v.length)),
          const Divider(height: 24, color: AppColors.divider),
          Text('OLDEST PENDING REGISTRATIONS', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          students.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: webLoading),
            error: (e, _) => Text('Could not load: $e', style: AppTypography.bodySm),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No registrations waiting.', style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted)),
                  )
                : Column(
                    children: [
                      for (final s in rows.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              InitialsAvatar(s['name'], size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CellText(
                                  str(s['name'], 'Unnamed'),
                                  secondary: '${str((s['courses'] as Map?)?['short_name'] ?? (s['courses'] as Map?)?['name'])} · ${str((s['branches'] as Map?)?['name'])}',
                                ),
                              ),
                              Text(shortDate(s['doj']), style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.revenue});
  final AsyncValue<List<Map<String, dynamic>>> revenue;

  @override
  Widget build(BuildContext context) {
    return WebPanel(
      title: 'Revenue by branch',
      trailing: TextButton(onPressed: () => context.go('/super-admin/reports'), child: const Text('Full report')),
      child: revenue.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: webLoading),
        error: (e, _) => Text('Could not load: $e', style: AppTypography.bodySm),
        data: (rows) {
          final top = rows.take(6).map((r) => (str(r['branch_name']), (r['total_revenue'] as num?)?.toDouble() ?? 0.0)).toList();
          return RevenueBarChart(items: top);
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    ('Add student', Icons.person_add_alt_outlined, '/super-admin/add-student'),
    ('Register branch admin', Icons.how_to_reg_outlined, '/super-admin/branch-registration'),
    ('Reset a password', Icons.lock_reset_outlined, '/super-admin/reset-password'),
    ('Exam papers', Icons.quiz_outlined, '/super-admin/paper-manager'),
    ('Marksheets & certificates', Icons.workspace_premium_outlined, '/admin/marksheet-generator'),
    ('Collect fee', Icons.payments_outlined, '/admin/fee-collection'),
    ('Generate payslip', Icons.receipt_long_outlined, '/super-admin/payslip-generator'),
    ('Salary revision', Icons.trending_up_outlined, '/super-admin/propose-salary'),
    ('Attendance session', Icons.qr_code_2_outlined, '/super-admin/attendance'),
  ];

  @override
  Widget build(BuildContext context) {
    return WebPanel(
      title: 'Quick actions',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (label, icon, path) in _actions)
            OutlinedButton.icon(
              style: webSecondaryButton(),
              onPressed: () => context.go(path),
              icon: Icon(icon, size: 18, color: AppColors.goldDeep),
              label: Text(label),
            ),
        ],
      ),
    );
  }
}
