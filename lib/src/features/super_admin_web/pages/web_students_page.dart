import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import '../web_providers.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

class WebStudentsPage extends ConsumerStatefulWidget {
  const WebStudentsPage({super.key, this.initialBranchId});
  final int? initialBranchId;

  @override
  ConsumerState<WebStudentsPage> createState() => _WebStudentsPageState();
}

class _WebStudentsPageState extends ConsumerState<WebStudentsPage> {
  String _search = '';
  int? _branchId;
  Object? _courseId;
  String _status = 'all';
  int? _openId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialBranchId;
  }

  @override
  void didUpdateWidget(covariant WebStudentsPage old) {
    super.didUpdateWidget(old);
    if (old.initialBranchId != widget.initialBranchId) _branchId = widget.initialBranchId;
  }

  Future<void> _run(Future<void> Function() op, String success) async {
    setState(() => _busy = true);
    try {
      await op();
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(webPendingStudentsProvider);
      if (mounted) showToast(context, success);
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(_Row s) => _run(
        () => ref.read(adminRepositoryProvider).approveStudent(s['id'] as int),
        '${str(s['name'])} approved.',
      );

  Future<void> _delete(_Row s) async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${str(s['name'])}?',
      message: 'This removes the student record and their sign-in account. It cannot be undone.',
      confirmLabel: 'Delete student',
      danger: true,
    );
    if (!ok) return;
    await _run(() => ref.read(adminRepositoryProvider).deleteStudent('${s['id']}'), 'Student deleted.');
    if (mounted) setState(() => _openId = null);
  }

  Future<void> _edit(_Row s) async {
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => _EditStudentDialog(student: s));
    if (result == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).updateStudent(
            id: '${s['id']}',
            name: result['name'],
            email: result['email'],
            phone: result['phone'],
          ),
      'Student updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final branches = ref.watch(branchesProvider).whenOrNull(data: (b) => b) ?? const [];
    final dues = ref.watch(adminDuesReportProvider).whenOrNull(data: (d) => d) ?? const [];
    final branchName = {for (final b in branches) b['id']: str(b['name'], 'Branch ${b['id']}')};
    final dueBy = {for (final d in dues) d['student_id']: d};

    return WebPage(
      title: 'Students',
      subtitle: 'Every enrolled and pending student across all branches',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () {
            ref.invalidate(adminStudentsProvider);
            ref.invalidate(adminDuesReportProvider);
          },
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
      child: studentsAsync.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(adminStudentsProvider)),
        data: (raw) {
          // Negative status = rejected / deleted records; never shown.
          final all = raw.where((s) => ((s['status'] as num?) ?? 0) >= 0).toList();
          final courses = <Object, String>{};
          for (final s in all) {
            final c = s['courses'];
            if (s['course_id'] != null && c is Map) courses[s['course_id']] = str(c['short_name'] ?? c['name']);
          }

          final rows = all.where((s) {
            if (_branchId != null && s['branch_id'] != _branchId) return false;
            if (_courseId != null && s['course_id'] != _courseId) return false;
            if (_status == 'active' && s['status'] != 1) return false;
            if (_status == 'pending' && s['status'] != 0) return false;
            if (_status == 'inactive' && (s['status'] == 1 || s['status'] == 0)) return false;
            if (_search.isEmpty) return true;
            return '${s['name']} ${s['reg_no']} ${s['contact']} ${s['email']}'.toLowerCase().contains(_search);
          }).toList();
          final open = all.where((s) => s['id'] == _openId).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  WebSearchField(hint: 'Search name, reg no, phone, email…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
                  WebDropdown<int?>(
                    value: _branchId,
                    items: {null: 'All branches', for (final b in branches) b['id'] as int: branchName[b['id']]!},
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  WebDropdown<Object?>(
                    value: _courseId,
                    items: {null: 'All courses', ...courses},
                    onChanged: (v) => setState(() => _courseId = v),
                  ),
                  WebDropdown<String>(
                    value: _status,
                    width: 160,
                    items: const {'all': 'Any status', 'active': 'Active', 'pending': 'Pending', 'inactive': 'Inactive'},
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
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
                          WebColumn('Course'),
                          WebColumn('Branch'),
                          WebColumn('Phone'),
                          WebColumn('Dues', alignEnd: true),
                          WebColumn('Status'),
                        ],
                        rows: rows,
                        keyOf: (s) => s['id'] as Object,
                        openKey: _openId,
                        onRowTap: (s) => setState(() => _openId = s['id'] as int?),
                        emptyTitle: all.isEmpty ? 'No students yet' : 'No matches',
                        emptyMessage: all.isEmpty ? 'Add the first student with “Add student”.' : 'Try a different search or filter.',
                        cells: (s) {
                          final due = (dueBy[s['id']]?['due_amount'] as num?)?.toDouble() ?? 0;
                          return [
                            CellText(
                              str(s['name'], 'Unnamed'),
                              secondary: str(s['reg_no'], 'No reg no'),
                              leading: InitialsAvatar(s['name'], image: resolveAvatarProvider(s['photo_url'])),
                            ),
                            PlainCell(str(courses[s['course_id']])),
                            PlainCell(str(branchName[s['branch_id']])),
                            PlainCell(str(s['contact'])),
                            Text(
                              due > 0 ? inr(due) : '—',
                              style: AppTypography.bodyMd.copyWith(
                                color: due > 0 ? AppColors.danger : AppColors.textMuted,
                                fontWeight: due > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            StatusChip.forStudent(s['status']),
                          ];
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a student to see their profile, fees and actions.')
                    else
                      _StudentPanel(
                        student: open,
                        course: str(courses[open['course_id']] ?? (open['courses'] is Map ? open['courses']['name'] : null)),
                        branch: str(branchName[open['branch_id']]),
                        due: dueBy[open['id']],
                        busy: _busy,
                        onClose: () => setState(() => _openId = null),
                        onApprove: () => _approve(open),
                        onEdit: () => _edit(open),
                        onDelete: () => _delete(open),
                        onResetPassword: () => context.go('/super-admin/reset-password'),
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

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({
    required this.student,
    required this.course,
    required this.branch,
    required this.due,
    required this.busy,
    required this.onClose,
    required this.onApprove,
    required this.onEdit,
    required this.onDelete,
    required this.onResetPassword,
  });

  final Map<String, dynamic> student;
  final String course;
  final String branch;
  final Map<String, dynamic>? due;
  final bool busy;
  final VoidCallback onClose, onApprove, onEdit, onDelete, onResetPassword;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return DetailPanel(
      onClose: onClose,
      header: Row(
        children: [
          InitialsAvatar(s['name'], size: 48, image: resolveAvatarProvider(s['photo_url'])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(str(s['name'], 'Unnamed'), style: AppTypography.headingSm),
                Text(str(s['reg_no'], 'No registration number'), style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                StatusChip.forStudent(s['status']),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Delete student',
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
        OutlinedButton(style: webSecondaryButton(), onPressed: onResetPassword, child: const Text('Reset password')),
        OutlinedButton(style: webSecondaryButton(), onPressed: busy ? null : onEdit, child: const Text('Edit')),
        if (s['status'] == 0)
          FilledButton(style: webPrimaryButton(AppColors.success), onPressed: busy ? null : onApprove, child: const Text('Approve')),
      ],
      children: [
        DetailSection('Enrolment', [
          ('Course', course),
          ('Branch', branch),
          ('Admission date', shortDate(s['doj'])),
          ('Session', str(s['session'])),
        ]),
        DetailSection('Fees', [
          if (due == null)
            ('Status', 'No outstanding dues')
          else ...[
            ('Total fee', inr(due!['total_amount'] as num?)),
            ('Paid', inr(due!['amount_paid'] as num?)),
            ('Due', inr(due!['due_amount'] as num?)),
          ],
        ]),
        DetailSection('Contact', [
          ('Phone', str(s['contact'])),
          ('Email', str(s['email'])),
          ('Address', str(s['address'])),
        ]),
        DetailSection('Personal', [
          ("Father's name", str(s['father_name'])),
          ("Mother's name", str(s['mother_name'])),
          ('Date of birth', shortDate(s['dob'])),
          ('Gender', str(s['gender'])),
        ]),
      ],
    );
  }
}

class _EditStudentDialog extends StatefulWidget {
  const _EditStudentDialog({required this.student});
  final Map<String, dynamic> student;

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: str(widget.student['name'], ''));
  late final _email = TextEditingController(text: str(widget.student['email'], ''));
  late final _phone = TextEditingController(text: str(widget.student['contact'], ''));

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('Edit student', style: AppTypography.headingLg),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: _dec('Full name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                decoration: _dec('Email'),
                validator: (v) => (v != null && v.trim().isNotEmpty && !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _phone, decoration: _dec('Phone')),
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
            Navigator.pop(context, {'name': _name.text.trim(), 'email': _email.text.trim(), 'phone': _phone.text.trim()});
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}
