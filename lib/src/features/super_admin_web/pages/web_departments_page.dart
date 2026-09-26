import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

class WebDepartmentsPage extends ConsumerStatefulWidget {
  const WebDepartmentsPage({super.key});

  @override
  ConsumerState<WebDepartmentsPage> createState() => _WebDepartmentsPageState();
}

class _WebDepartmentsPageState extends ConsumerState<WebDepartmentsPage> {
  String _search = '';
  int? _openId;
  bool _busy = false;

  Future<void> _edit([_Row? department]) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _DepartmentDialog(department: department));
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final client = ref.read(supabaseClientProvider);
      if (department != null) {
        await client.from('departments').update({'name': result['name'], 'status': result['status']}).eq('id', department['id']);
      } else {
        final maxId = await client.from('departments').select('id').order('id', ascending: false).limit(1).maybeSingle();
        final nextId = ((maxId?['id'] as int?) ?? 0) + 1;
        await client.from('departments').insert({'id': nextId, 'name': result['name'], 'status': result['status']});
      }
      ref.invalidate(departmentsProvider);
      if (mounted) showToast(context, department != null ? 'Department updated.' : 'Department created.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not save department: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(_Row department) async {
    final active = department['status'] == 1;
    setState(() => _busy = true);
    try {
      await ref.read(supabaseClientProvider).from('departments').update({'status': active ? 0 : 1}).eq('id', department['id']);
      ref.invalidate(departmentsProvider);
      if (mounted) showToast(context, active ? 'Department deactivated.' : 'Department activated.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not update status: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);

    return WebPage(
      title: 'Departments',
      subtitle: 'Staff departments used across every branch',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => ref.invalidate(departmentsProvider),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: _busy ? null : () => _edit(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New department'),
        ),
      ],
      child: departments.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(departmentsProvider)),
        data: (all) {
          final rows = all.where((d) => _search.isEmpty || str(d['name'], '').toLowerCase().contains(_search)).toList()
            ..sort((a, b) => str(a['name'], '').toLowerCase().compareTo(str(b['name'], '').toLowerCase()));
          final open = all.where((d) => d['id'] == _openId).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  WebSearchField(hint: 'Search departments…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
                  const Spacer(),
                  if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('${rows.length} of ${all.length} departments', style: AppTypography.bodySm),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: WebTable<_Row>(
                        columns: const [WebColumn('Department', flex: 4), WebColumn('Status')],
                        rows: rows,
                        keyOf: (d) => d['id'] as Object,
                        openKey: _openId,
                        onRowTap: (d) => setState(() => _openId = d['id'] as int?),
                        emptyTitle: all.isEmpty ? 'No departments yet' : 'No matches',
                        emptyMessage: all.isEmpty ? 'Create the first department with “New department”.' : 'Try a different search.',
                        cells: (d) => [
                          CellText(str(d['name'], 'Unnamed department')),
                          d['status'] == 1 ? const StatusChip('Active', AppColors.success) : const StatusChip('Inactive', AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a department to edit it or change its status.')
                    else
                      DetailPanel(
                        onClose: () => setState(() => _openId = null),
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(str(open['name'], 'Unnamed department'), style: AppTypography.headingSm),
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
                          FilledButton(style: webPrimaryButton(), onPressed: _busy ? null : () => _edit(open), child: const Text('Edit')),
                        ],
                        children: const [],
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

class _DepartmentDialog extends StatefulWidget {
  const _DepartmentDialog({this.department});
  final Map<String, dynamic>? department;

  @override
  State<_DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<_DepartmentDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: str(widget.department?['name'], ''));
  late bool _active = widget.department == null || widget.department!['status'] == 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.department != null;
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(editing ? 'Edit department' : 'New department', style: AppTypography.headingLg),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: 'Department name *', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: Text('Active', style: AppTypography.bodyMd),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: webPrimaryButton(),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, {'name': _name.text.trim(), 'status': _active ? 1 : 0});
          },
          child: Text(editing ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}
