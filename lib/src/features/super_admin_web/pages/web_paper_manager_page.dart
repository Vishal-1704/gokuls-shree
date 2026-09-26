import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/exams/presentation/question_manager_screen.dart';
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

final _paperSetsProvider = FutureProvider<List<_Row>>((ref) => ref.watch(examRepositoryProvider).getAdminPaperSets());

class WebPaperManagerPage extends ConsumerStatefulWidget {
  const WebPaperManagerPage({super.key});

  @override
  ConsumerState<WebPaperManagerPage> createState() => _WebPaperManagerPageState();
}

class _WebPaperManagerPageState extends ConsumerState<WebPaperManagerPage> {
  String _search = '';
  String _status = 'all';
  int? _openId;
  bool _busy = false;

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _CreatePaperDialog());
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(examRepositoryProvider).createPaperSet(
            title: result['title'],
            durationMinutes: result['duration'],
            totalMarks: result['marks'],
            assessmentType: result['assessmentType'],
            branchId: result['branchId'],
            courseId: result['courseId'],
          );
      ref.invalidate(_paperSetsProvider);
      if (mounted) showToast(context, 'Paper set created.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not create paper: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePublish(_Row paper) async {
    final publish = paper['status'] != 'published';
    setState(() => _busy = true);
    try {
      await ref.read(examRepositoryProvider).togglePaperSetStatus(paper['id'] as int, publish);
      ref.invalidate(_paperSetsProvider);
      if (mounted) showToast(context, publish ? 'Paper published.' : 'Moved to draft.');
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(_Row paper) async {
    final ok = await confirmAction(
      context,
      title: 'Delete "${str(paper['title'])}"?',
      message: 'This removes the paper set from any schedules. It cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(examRepositoryProvider).deletePaperSet(paper['id'] as int);
      ref.invalidate(_paperSetsProvider);
      if (mounted) {
        setState(() => _openId = null);
        showToast(context, 'Paper set deleted.');
      }
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _manageQuestions(_Row paper) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionManagerScreen(paperSetId: paper['id'] as int, paperTitle: str(paper['title'], 'Paper')),
      ),
    ).then((_) => ref.invalidate(_paperSetsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final papers = ref.watch(_paperSetsProvider);

    return WebPage(
      title: 'Exam papers',
      subtitle: 'Question papers used across tests and exams',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => ref.invalidate(_paperSetsProvider),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New paper'),
        ),
      ],
      child: papers.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(_paperSetsProvider)),
        data: (all) {
          final rows = all.where((p) {
            if (_status == 'published' && p['status'] != 'published') return false;
            if (_status == 'draft' && p['status'] == 'published') return false;
            if (_search.isEmpty) return true;
            return str(p['title'], '').toLowerCase().contains(_search);
          }).toList();
          final open = all.where((p) => p['id'] == _openId).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  WebSearchField(hint: 'Search papers…', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
                  const SizedBox(width: 10),
                  WebDropdown<String>(
                    value: _status,
                    items: const {'all': 'All statuses', 'published': 'Published', 'draft': 'Draft'},
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const Spacer(),
                  if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('${rows.length} of ${all.length} papers', style: AppTypography.bodySm),
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
                          WebColumn('Paper', flex: 3),
                          WebColumn('Type'),
                          WebColumn('Duration'),
                          WebColumn('Questions', alignEnd: true),
                          WebColumn('Status'),
                        ],
                        rows: rows,
                        keyOf: (p) => p['id'] as Object,
                        openKey: _openId,
                        onRowTap: (p) => setState(() => _openId = p['id'] as int?),
                        emptyTitle: all.isEmpty ? 'No paper sets yet' : 'No matches',
                        emptyMessage: all.isEmpty ? 'Create the first one with “New paper”.' : 'Try a different search or status.',
                        cells: (p) => [
                          CellText(str(p['title'], 'Untitled'), secondary: '${str(p['total_marks'], '0')} marks'),
                          StatusChip(
                            (p['assessment_type'] == 'test') ? 'Test' : 'Exam',
                            (p['assessment_type'] == 'test') ? AppColors.primaryViolet : AppColors.goldDeep,
                          ),
                          PlainCell('${str(p['duration_minutes'], '0')} min'),
                          PlainCell(str(p['total_questions'], '0'), alignEnd: true),
                          (p['status'] == 'published')
                              ? const StatusChip('Published', AppColors.success)
                              : const StatusChip('Draft', AppColors.warning),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (open == null)
                      const NoSelection(message: 'Select a paper set to manage its questions or publish it.')
                    else
                      DetailPanel(
                        onClose: () => setState(() => _openId = null),
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(str(open['title'], 'Untitled'), style: AppTypography.headingSm),
                            const SizedBox(height: 6),
                            (open['status'] == 'published')
                                ? const StatusChip('Published', AppColors.success)
                                : const StatusChip('Draft', AppColors.warning),
                          ],
                        ),
                        actions: [
                          IconButton(tooltip: 'Delete', onPressed: _busy ? null : () => _delete(open), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
                          OutlinedButton(
                            style: webSecondaryButton(),
                            onPressed: _busy ? null : () => _togglePublish(open),
                            child: Text(open['status'] == 'published' ? 'Unpublish' : 'Publish'),
                          ),
                          FilledButton(style: webPrimaryButton(), onPressed: () => _manageQuestions(open), child: const Text('Manage questions')),
                        ],
                        children: [
                          DetailSection('Paper', [
                            ('Type', (open['assessment_type'] == 'test') ? 'Test' : 'Exam'),
                            ('Duration', '${str(open['duration_minutes'], '0')} minutes'),
                            ('Total marks', str(open['total_marks'])),
                            ('Questions added', str(open['total_questions'], '0')),
                            ('Branch', str((open['branches'] as Map?)?['name'], 'All branches')),
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

class _CreatePaperDialog extends ConsumerStatefulWidget {
  const _CreatePaperDialog();

  @override
  ConsumerState<_CreatePaperDialog> createState() => _CreatePaperDialogState();
}

class _CreatePaperDialogState extends ConsumerState<_CreatePaperDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '60');
  final _marks = TextEditingController(text: '100');
  int? _courseId;
  String _type = 'exam';

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _marks.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(adminCoursesProvider).whenOrNull(data: (v) => v) ?? const [];

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('New paper set', style: AppTypography.headingLg),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _title,
                  decoration: _dec('Paper title *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SegmentedButton<String>(
                      segments: const [ButtonSegment(value: 'test', label: Text('Test')), ButtonSegment(value: 'exam', label: Text('Exam'))],
                      selected: {_type},
                      onSelectionChanged: (v) => setState(() => _type = v.first),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _courseId,
                  decoration: _dec('Course *'),
                  items: [for (final c in courses) DropdownMenuItem(value: c['id'] as int, child: Text(str(c['name']), overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => _courseId = v),
                  validator: (v) => v == null ? 'Select a course' : null,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Duration (min) *'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter minutes' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _marks,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Total marks *'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter marks' : null,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: webPrimaryButton(),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, {
              'title': _title.text.trim(),
              'duration': int.parse(_duration.text),
              'marks': int.parse(_marks.text),
              'assessmentType': _type,
              'branchId': null,
              'courseId': _courseId,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
