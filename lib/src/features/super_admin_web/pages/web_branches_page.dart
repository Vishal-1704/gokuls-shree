import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

class WebBranchesPage extends ConsumerStatefulWidget {
  const WebBranchesPage({super.key});

  @override
  ConsumerState<WebBranchesPage> createState() => _WebBranchesPageState();
}

class _WebBranchesPageState extends ConsumerState<WebBranchesPage> {
  String _search = '';
  String _status = 'all';
  int? _openId;
  bool _busy = false;

  Future<void> _edit([_Row? branch]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _BranchDialog(branch: branch),
    );
    if (data == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (branch == null) {
        await repo.createBranch(data);
      } else {
        await repo.updateBranch(branch['id'] as int, data);
      }
      ref.invalidate(branchesProvider);
      if (mounted) showToast(context, branch == null ? 'Branch created.' : 'Branch updated.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not save branch: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(_Row branch) async {
    final active = branch['status'] == 1;
    if (active) {
      final ok = await confirmAction(
        context,
        title: 'Deactivate ${str(branch['name'])}?',
        message: 'The branch will be marked inactive. Its students and records are kept.',
        confirmLabel: 'Deactivate',
        danger: true,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).setBranchActive(branch['id'] as int, !active);
      ref.invalidate(branchesProvider);
      if (mounted) showToast(context, active ? 'Branch deactivated.' : 'Branch activated.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not update status: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final students = ref.watch(adminStudentsProvider).whenOrNull(data: (s) => s) ?? const [];
    final revenue = ref.watch(adminRevenueByBranchProvider).whenOrNull(data: (r) => r) ?? const [];
    final dues = ref.watch(adminDuesReportProvider).whenOrNull(data: (d) => d) ?? const [];

    final activeBy = <Object?, int>{};
    final pendingBy = <Object?, int>{};
    for (final s in students) {
      if (s['status'] == 1) activeBy[s['branch_id']] = (activeBy[s['branch_id']] ?? 0) + 1;
      if (s['status'] == 0) pendingBy[s['branch_id']] = (pendingBy[s['branch_id']] ?? 0) + 1;
    }
    final revenueBy = {for (final r in revenue) r['branch_id']: (r['total_revenue'] as num?)?.toDouble() ?? 0};
    final duesCountBy = <Object?, int>{};
    final duesAmtBy = <Object?, double>{};
    for (final d in dues) {
      duesCountBy[d['branch_id']] = (duesCountBy[d['branch_id']] ?? 0) + 1;
      duesAmtBy[d['branch_id']] = (duesAmtBy[d['branch_id']] ?? 0) + ((d['due_amount'] as num?)?.toDouble() ?? 0);
    }

    return WebPage(
      title: 'Branches',
      subtitle: 'Franchise branches, their status and performance',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () {
            ref.invalidate(branchesProvider);
            ref.invalidate(adminStudentsProvider);
            ref.invalidate(adminRevenueByBranchProvider);
            ref.invalidate(adminDuesReportProvider);
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: _busy ? null : () => _edit(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New branch'),
        ),
      ],
      child: branches.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(branchesProvider)),
        data: (all) {
          final rows = all.where((b) {
            if (_status == 'active' && b['status'] != 1) return false;
            if (_status == 'inactive' && b['status'] == 1) return false;
            if (_search.isEmpty) return true;
            final hay = '${b['name']} ${b['code']} ${b['owner_name']} ${b['city']} ${b['contact']}'.toLowerCase();
            return hay.contains(_search);
          }).toList()
            ..sort((a, b) => str(a['name'], '').toLowerCase().compareTo(str(b['name'], '').toLowerCase()));
          final open = all.where((b) => b['id'] == _openId).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  WebSearchField(hint: 'Search name, code, owner, city…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
                  const SizedBox(width: 10),
                  WebDropdown<String>(
                    value: _status,
                    items: const {'all': 'All statuses', 'active': 'Active', 'inactive': 'Inactive'},
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const Spacer(),
                  if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('${rows.length} of ${all.length} branches', style: AppTypography.bodySm),
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
                          WebColumn('Branch', flex: 3),
                          WebColumn('Owner'),
                          WebColumn('Contact'),
                          WebColumn('Students', flex: 1, alignEnd: true),
                          WebColumn('Revenue', alignEnd: true),
                          WebColumn('Status'),
                        ],
                        rows: rows,
                        keyOf: (b) => b['id'] as Object,
                        openKey: _openId,
                        onRowTap: (b) => setState(() => _openId = b['id'] as int?),
                        emptyTitle: all.isEmpty ? 'No branches yet' : 'No matches',
                        emptyMessage: all.isEmpty ? 'Create the first branch with “New branch”.' : 'Try a different search or status.',
                        cells: (b) => [
                          CellText(str(b['name'], 'Unnamed branch'), secondary: str(b['code'], 'No code')),
                          PlainCell(str(b['owner_name'])),
                          PlainCell(str(b['contact'])),
                          PlainCell('${activeBy[b['id']] ?? 0}', alignEnd: true),
                          PlainCell(inr(revenueBy[b['id']] ?? 0), alignEnd: true),
                          b['status'] == 1 ? const StatusChip('Active', AppColors.success) : const StatusChip('Inactive', AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a branch to see its numbers, contact details and actions.')
                    else
                      DetailPanel(
                        onClose: () => setState(() => _openId = null),
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(str(open['name'], 'Unnamed branch'), style: AppTypography.headingSm),
                            Text('Code ${str(open['code'])}', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            open['status'] == 1 ? const StatusChip('Active', AppColors.success) : const StatusChip('Inactive', AppColors.textMuted),
                          ],
                        ),
                        actions: [
                          OutlinedButton(
                            style: webSecondaryButton(open['status'] == 1 ? AppColors.danger : AppColors.success),
                            onPressed: _busy ? null : () => _toggle(open),
                            child: Text(open['status'] == 1 ? 'Deactivate' : 'Activate'),
                          ),
                          OutlinedButton(
                            style: webSecondaryButton(),
                            onPressed: _busy ? null : () => _edit(open),
                            child: const Text('Edit'),
                          ),
                          FilledButton(
                            style: webPrimaryButton(),
                            onPressed: () => context.go('/super-admin/students?branch=${open['id']}'),
                            child: const Text('View students'),
                          ),
                        ],
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.1,
                            children: [
                              _MiniStat('Active students', '${activeBy[open['id']] ?? 0}'),
                              _MiniStat('Pending approval', '${pendingBy[open['id']] ?? 0}'),
                              _MiniStat('Revenue', inr(revenueBy[open['id']] ?? 0)),
                              _MiniStat('Dues', '${duesCountBy[open['id']] ?? 0} · ${inr(duesAmtBy[open['id']] ?? 0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DetailSection('Contact', [
                            ('Owner', str(open['owner_name'])),
                            ('Phone', str(open['contact'])),
                            ('Email', str(open['email'])),
                          ]),
                          DetailSection('Location', [
                            ('Address', str(open['address'])),
                            ('City', str(open['city'])),
                            ('State', str(open['state'])),
                            ('Pincode', str(open['pincode'])),
                          ]),
                          DetailSection('Record', [('Created', shortDate(open['created_at']))]),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.inkNavy900, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.headingSm, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BranchDialog extends ConsumerStatefulWidget {
  const _BranchDialog({this.branch});
  final Map<String, dynamic>? branch;

  @override
  ConsumerState<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends ConsumerState<_BranchDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late bool _active;
  bool _generating = false;

  static const _fields = ['name', 'code', 'owner_name', 'contact', 'email', 'city', 'state', 'pincode', 'address'];

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _c = {for (final f in _fields) f: TextEditingController(text: str(b?[f], ''))};
    _active = b == null || b['status'] == 1;
    if (b == null) _generateCode();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() => _generating = true);
    try {
      final code = await ref.read(adminRepositoryProvider).generateNextBranchCode();
      if (mounted) _c['code']!.text = code;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _field(String key, String label, {bool required = false, int lines = 1, Widget? suffix, TextInputType? type}) {
    return TextFormField(
      controller: _c[key],
      maxLines: lines,
      keyboardType: type,
      style: AppTypography.bodyMd,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        suffixIcon: suffix,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.branch != null;
    Widget pair(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)]);

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
      title: Text(editing ? 'Edit branch' : 'New branch', style: AppTypography.headingLg),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                pair(
                  _field('name', 'Branch name', required: true),
                  _field(
                    'code',
                    'Branch code',
                    required: true,
                    suffix: IconButton(
                      tooltip: 'Generate next code',
                      onPressed: _generating ? null : _generateCode,
                      icon: _generating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                pair(_field('owner_name', 'Owner name'), _field('contact', 'Phone', type: TextInputType.phone)),
                const SizedBox(height: 14),
                pair(_field('email', 'Email', type: TextInputType.emailAddress), _field('city', 'City')),
                const SizedBox(height: 14),
                pair(_field('state', 'State'), _field('pincode', 'Pincode', type: TextInputType.number)),
                const SizedBox(height: 14),
                _field('address', 'Address', lines: 2),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text('Branch is active', style: AppTypography.bodyMd),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: webPrimaryButton(),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, {
              for (final e in _c.entries) e.key: e.value.text,
              'status': _active,
            });
          },
          child: Text(editing ? 'Save changes' : 'Create branch'),
        ),
      ],
    );
  }
}
