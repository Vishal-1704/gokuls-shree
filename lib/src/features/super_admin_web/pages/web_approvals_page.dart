import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/marksheet_viewer_screen.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/certificate_viewer_screen.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/experience_certificate_viewer_screen.dart';
import '../web_providers.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

/// Everything the page needs to render and act on one approval queue.
class _Queue {
  const _Queue({
    required this.label,
    required this.rows,
    required this.columns,
    required this.cells,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.searchText,
    required this.approve,
    required this.approveLabel,
    required this.refresh,
    this.branchIdOf,
    this.reject,
    this.rejectWarning,
    this.onPreview,
  });

  final String label;
  final AsyncValue<List<_Row>> rows;
  final List<WebColumn> columns;
  final List<Widget> Function(_Row) cells;
  final String Function(_Row) title;
  final String Function(_Row) subtitle;
  final List<Widget> Function(_Row) details;
  final String Function(_Row) searchText;
  final int? Function(_Row)? branchIdOf;
  final Future<void> Function(_Row) approve;
  final String approveLabel;
  final Future<void> Function(_Row)? reject;
  final String Function(_Row)? rejectWarning;
  final void Function(BuildContext, _Row)? onPreview;
  /// Re-fetches this queue (and anything derived from it) after an action.
  final void Function() refresh;
}

Map<String, dynamic>? _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

class WebApprovalsPage extends ConsumerStatefulWidget {
  const WebApprovalsPage({super.key});

  @override
  ConsumerState<WebApprovalsPage> createState() => _WebApprovalsPageState();
}

class _WebApprovalsPageState extends ConsumerState<WebApprovalsPage> {
  int _tab = 0;
  String _search = '';
  int? _branchId;
  Object? _openId;
  Set<Object> _checked = {};
  bool _busy = false;

  List<_Queue> _queues(AdminRepository repo) {
    final students = ref.watch(webPendingStudentsProvider);
    final docs = ref.watch(webPendingDocumentsProvider);
    final exp = ref.watch(webPendingExpCertsProvider);
    final salary = ref.watch(webPendingSalaryProvider);

    String studentName(_Row r) => str(_m(r['students'])?['name'], 'Unknown student');
    String studentReg(_Row r) => str(_m(r['students'])?['reg_no']);
    int? studentBranch(_Row r) => _m(r['students'])?['branch_id'] as int?;
    String empName(_Row r) => str(_m(r['employees'])?['name'], 'Unknown employee');
    double gross(_Row r) => [r['basic_salary'], r['hra'], r['da'], r['other_allowance']]
        .fold<double>(0, (s, v) => s + ((v as num?)?.toDouble() ?? 0));

    return [
      _Queue(
        label: 'Student registrations',
        rows: students,
        refresh: () {
          ref.invalidate(webPendingStudentsProvider);
          ref.invalidate(adminStudentsProvider);
        },
        columns: const [
          WebColumn('Applicant', flex: 3),
          WebColumn('Course'),
          WebColumn('Branch'),
          WebColumn('Phone'),
          WebColumn('Applied'),
        ],
        cells: (r) => [
          CellText(str(r['name'], 'Unnamed'), secondary: str(r['reg_no'], 'No reg no'), leading: InitialsAvatar(r['name'])),
          PlainCell(str(_m(r['courses'])?['short_name'] ?? _m(r['courses'])?['name'])),
          PlainCell(str(_m(r['branches'])?['name'])),
          PlainCell(str(r['contact'])),
          PlainCell(shortDate(r['doj']), muted: true),
        ],
        title: (r) => str(r['name'], 'Unnamed'),
        subtitle: (r) => str(r['reg_no'], 'No registration number'),
        details: (r) => [
          DetailSection('Registration', [
            ('Course', str(_m(r['courses'])?['name'])),
            ('Branch', str(_m(r['branches'])?['name'])),
            ('Applied on', shortDate(r['doj'])),
          ]),
          DetailSection('Personal', [
            ("Father's name", str(r['father_name'])),
            ("Mother's name", str(r['mother_name'])),
            ('Date of birth', shortDate(r['dob'])),
            ('Gender', str(r['gender'])),
          ]),
          DetailSection('Contact', [
            ('Phone', str(r['contact'])),
            ('Email', str(r['email'])),
            ('Address', str(r['address'])),
          ]),
        ],
        searchText: (r) => '${r['name']} ${r['reg_no']} ${r['contact']} ${r['email']}',
        branchIdOf: (r) => r['branch_id'] as int?,
        approve: (r) => repo.approveStudent(r['id'] as int),
        approveLabel: 'Approve',
        reject: (r) => repo.rejectStudent(r['id'] as int),
        rejectWarning: (r) => 'This removes ${str(r['name'], 'this applicant')}\'s registration and sign-in account. It cannot be undone.',
      ),
      _Queue(
        label: 'Marksheets',
        rows: docs.whenData((d) => d['marksheets'] ?? const []),
        refresh: () => ref.invalidate(webPendingDocumentsProvider),
        columns: const [
          WebColumn('Student', flex: 3),
          WebColumn('Course', flex: 3),
          WebColumn('Result', flex: 1),
          WebColumn('Marks'),
          WebColumn('Percent', flex: 1, alignEnd: true),
        ],
        cells: (r) => [
          CellText(studentName(r), secondary: studentReg(r)),
          PlainCell(str(_m(r['courses'])?['name'])),
          StatusChip(str(r['result'], 'PASS'), str(r['result'], 'PASS').toUpperCase() == 'FAIL' ? AppColors.danger : AppColors.success),
          PlainCell('${str(r['obtained_marks'], '0')} / ${str(r['total_marks'], '0')}'),
          PlainCell('${str(r['percentage'], '0')}%', alignEnd: true),
        ],
        title: studentName,
        subtitle: studentReg,
        details: (r) => [
          DetailSection('Marksheet', [
            ('Course', str(_m(r['courses'])?['name'])),
            ('Result', str(r['result'], 'PASS')),
            ('Marks', '${str(r['obtained_marks'], '0')} / ${str(r['total_marks'], '0')}'),
            ('Percentage', '${str(r['percentage'], '0')}%'),
            ('Submitted', shortDate(r['created_at'])),
          ]),
        ],
        searchText: (r) => '${studentName(r)} ${studentReg(r)} ${_m(r['courses'])?['name']}',
        branchIdOf: studentBranch,
        onPreview: (ctx, r) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => MarksheetViewerScreen(marksheet: r)),
        ),
        approve: (r) => repo.approveDocument(type: 'marksheet', id: r['id'] as int),
        approveLabel: 'Approve',
      ),
      _Queue(
        label: 'Certificates',
        rows: docs.whenData((d) => d['certificates'] ?? const []),
        refresh: () => ref.invalidate(webPendingDocumentsProvider),
        columns: const [
          WebColumn('Student', flex: 3),
          WebColumn('Course', flex: 3),
          WebColumn('Type'),
          WebColumn('Generated'),
        ],
        cells: (r) => [
          CellText(studentName(r), secondary: studentReg(r)),
          PlainCell(str(_m(r['courses'])?['name'])),
          PlainCell(str(r['doc_type'], 'Course completion')),
          PlainCell(shortDate(r['created_at']), muted: true),
        ],
        title: studentName,
        subtitle: studentReg,
        details: (r) => [
          DetailSection('Certificate', [
            ('Course', str(_m(r['courses'])?['name'])),
            ('Type', str(r['doc_type'], 'Course completion')),
            ('Generated', shortDate(r['created_at'])),
          ]),
        ],
        searchText: (r) => '${studentName(r)} ${studentReg(r)} ${_m(r['courses'])?['name']}',
        branchIdOf: studentBranch,
        onPreview: (ctx, r) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => CertificateViewerScreen(certificate: r)),
        ),
        approve: (r) => repo.approveDocument(type: 'certificate', id: r['id'] as int),
        approveLabel: 'Approve',
      ),
      _Queue(
        label: 'Experience certificates',
        rows: exp,
        refresh: () => ref.invalidate(webPendingExpCertsProvider),
        columns: const [
          WebColumn('Employee', flex: 3),
          WebColumn('Designation'),
          WebColumn('Department'),
          WebColumn('Joined'),
          WebColumn('Requested'),
        ],
        cells: (r) => [
          CellText(empName(r), leading: InitialsAvatar(empName(r))),
          PlainCell(str(_m(r['employees'])?['designation'])),
          PlainCell(str(_m(r['employees'])?['department'])),
          PlainCell(shortDate(_m(r['employees'])?['doj'])),
          PlainCell(shortDate(r['request_date']), muted: true),
        ],
        title: empName,
        subtitle: (r) => str(_m(r['employees'])?['designation']),
        details: (r) => [
          DetailSection('Employee', [
            ('Designation', str(_m(r['employees'])?['designation'])),
            ('Department', str(_m(r['employees'])?['department'])),
            ('Joined', shortDate(_m(r['employees'])?['doj'])),
            ('Requested', shortDate(r['request_date'])),
          ]),
        ],
        searchText: (r) => '${empName(r)} ${_m(r['employees'])?['designation']}',
        onPreview: (ctx, r) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => ExperienceCertificateViewerScreen(certificate: r)),
        ),
        approve: (r) => repo.approveExperienceCert(r['id'] as int),
        approveLabel: 'Approve & issue',
      ),
      _Queue(
        label: 'Salary revisions',
        rows: salary,
        refresh: () => ref.invalidate(webPendingSalaryProvider),
        columns: const [
          WebColumn('Employee', flex: 3),
          WebColumn('Designation'),
          WebColumn('Effective from'),
          WebColumn('Proposed gross / month', alignEnd: true),
        ],
        cells: (r) => [
          CellText(empName(r), leading: InitialsAvatar(empName(r))),
          PlainCell(str(_m(r['employees'])?['designation'])),
          PlainCell('${str(r['effective_month'])}/${str(r['effective_year'])}'),
          PlainCell(inr(gross(r)), alignEnd: true),
        ],
        title: empName,
        subtitle: (r) => str(_m(r['employees'])?['designation']),
        details: (r) => [
          DetailSection('Proposed salary (monthly)', [
            ('Basic', inr(r['basic_salary'] as num?)),
            ('HRA', inr(r['hra'] as num?)),
            ('DA', inr(r['da'] as num?)),
            ('Other allowance', inr(r['other_allowance'] as num?)),
            ('Gross', inr(gross(r))),
            ('Effective from', '${str(r['effective_month'])}/${str(r['effective_year'])}'),
          ]),
        ],
        searchText: (r) => '${empName(r)} ${_m(r['employees'])?['designation']}',
        approve: (r) => repo.approveSalaryRevision(r['id'] as int),
        approveLabel: 'Approve',
        reject: (r) => repo.rejectSalaryRevision(r['id'] as int),
        rejectWarning: (r) => 'Reject the salary revision proposed for ${empName(r)}?',
      ),
    ];
  }

  Future<void> _act(_Queue q, List<_Row> targets, {required bool approve}) async {
    if (_busy || targets.isEmpty) return;
    if (!approve) {
      final ok = await confirmAction(
        context,
        title: targets.length == 1 ? 'Reject ${q.title(targets.first)}?' : 'Reject ${targets.length} requests?',
        message: q.rejectWarning?.call(targets.first) ?? 'This cannot be undone.',
        confirmLabel: 'Reject',
        danger: true,
      );
      if (!ok) return;
    } else if (targets.length > 1) {
      final ok = await confirmAction(
        context,
        title: 'Approve ${targets.length} requests?',
        message: 'Each selected ${q.label.toLowerCase()} request will be approved.',
        confirmLabel: 'Approve all',
      );
      if (!ok) return;
    }

    setState(() => _busy = true);
    var failed = 0;
    Object? lastError;
    for (final r in targets) {
      try {
        approve ? await q.approve(r) : await q.reject!(r);
      } catch (e) {
        failed++;
        lastError = e;
      }
    }
    if (!mounted) return;
    q.refresh();
    setState(() {
      _busy = false;
      _checked = {};
      _openId = null;
    });
    final done = targets.length - failed;
    if (failed == 0) {
      showToast(context, '${approve ? 'Approved' : 'Rejected'} $done ${done == 1 ? 'request' : 'requests'}.');
    } else {
      showToast(context, '$done done, $failed failed: $lastError', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(adminRepositoryProvider);
    final queues = _queues(repo);
    final q = queues[_tab];
    final branches = ref.watch(branchesProvider).whenOrNull(data: (b) => b) ?? const [];

    return WebPage(
      title: 'Approvals',
      subtitle: 'Review and act on requests from every branch',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => invalidatePendingApprovals(ref),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < queues.length; i++)
                  _QueueTab(
                    label: queues[i].label,
                    count: queues[i].rows.whenOrNull(data: (r) => r.length),
                    selected: i == _tab,
                    onTap: () => setState(() {
                      _tab = i;
                      _openId = null;
                      _checked = {};
                    }),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              WebSearchField(hint: 'Search ${q.label.toLowerCase()}…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
              if (q.branchIdOf != null) ...[
                const SizedBox(width: 10),
                WebDropdown<int?>(
                  value: _branchId,
                  items: {null: 'All branches', for (final b in branches) b['id'] as int: str(b['name'], 'Branch ${b['id']}')},
                  onChanged: (v) => setState(() => _branchId = v),
                ),
              ],
              const Spacer(),
              if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              if (_checked.isNotEmpty && !_busy) ...[
                Text('${_checked.length} selected', style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 10),
                TextButton(onPressed: () => setState(() => _checked = {}), child: const Text('Clear')),
                const SizedBox(width: 6),
                FilledButton.icon(
                  style: webPrimaryButton(AppColors.success),
                  onPressed: () {
                    final rows = q.rows.whenOrNull(data: (r) => r) ?? const [];
                    _act(q, rows.where((r) => _checked.contains(r['id'])).toList(), approve: true);
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text('Approve ${_checked.length}'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: q.rows.when(
              loading: () => webLoading,
              error: (e, _) => WebError(e, onRetry: q.refresh),
              data: (all) {
                final rows = all.where((r) {
                  if (_search.isNotEmpty && !q.searchText(r).toLowerCase().contains(_search)) return false;
                  if (_branchId != null && q.branchIdOf != null && q.branchIdOf!(r) != _branchId) return false;
                  return true;
                }).toList();
                final open = rows.where((r) => r['id'] == _openId).firstOrNull;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: WebTable<_Row>(
                        columns: q.columns,
                        rows: rows,
                        cells: q.cells,
                        keyOf: (r) => r['id'] as Object,
                        openKey: _openId,
                        onRowTap: (r) => setState(() => _openId = r['id']),
                        checked: _checked,
                        onCheckedChanged: (s) => setState(() => _checked = s),
                        emptyTitle: all.isEmpty ? 'All caught up' : 'No matches',
                        emptyMessage: all.isEmpty
                            ? 'There are no pending ${q.label.toLowerCase()}.'
                            : 'Try a different search or branch.',
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a request to see its details and approve or reject it.')
                    else
                      DetailPanel(
                        onClose: () => setState(() => _openId = null),
                        header: Row(
                          children: [
                            InitialsAvatar(q.title(open), size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.title(open), style: AppTypography.headingSm),
                                  Text(q.subtitle(open), style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                                  const SizedBox(height: 6),
                                  const StatusChip('Pending', AppColors.warning),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          if (q.onPreview != null)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.goldCta,
                                side: const BorderSide(color: AppColors.goldCta, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => q.onPreview!(context, open),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('Preview Document', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          if (q.reject != null)
                            OutlinedButton(
                              style: webSecondaryButton(AppColors.danger),
                              onPressed: _busy ? null : () => _act(q, [open], approve: false),
                              child: const Text('Reject'),
                            ),
                          FilledButton.icon(
                            style: webPrimaryButton(AppColors.success),
                            onPressed: _busy ? null : () => _act(q, [open], approve: true),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(q.approveLabel),
                          ),
                        ],
                        children: q.details(open),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        margin: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.goldDeep : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: selected ? AppColors.goldDeep : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: (count ?? 0) > 0 ? AppColors.warning.withValues(alpha: 0.15) : AppColors.inkNavy700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count == null ? '…' : '$count',
                style: AppTypography.labelSm.copyWith(color: (count ?? 0) > 0 ? AppColors.chipPendingFg : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
