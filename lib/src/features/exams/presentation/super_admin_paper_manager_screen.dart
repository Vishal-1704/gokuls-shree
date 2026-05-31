import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';

/// Super Admin: Manage Exam Paper Sets & Questions
/// Route: /super-admin/paper-manager
class SuperAdminPaperManagerScreen extends ConsumerStatefulWidget {
  const SuperAdminPaperManagerScreen({super.key});

  @override
  ConsumerState<SuperAdminPaperManagerScreen> createState() =>
      _SuperAdminPaperManagerScreenState();
}

class _SuperAdminPaperManagerScreenState
    extends ConsumerState<SuperAdminPaperManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paperSets = [];

  @override
  void initState() {
    super.initState();
    _loadPaperSets();
  }

  Future<void> _loadPaperSets() async {
    setState(() => _isLoading = true);
    try {
      final papers =
          await ref.read(examRepositoryProvider).getAdminPaperSets();
      setState(() {
        _paperSets = papers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to load papers: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _createPaperSet() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreatePaperSetDialog(),
    );
    if (result == null) return;

    try {
      final repo = ref.read(examRepositoryProvider);
      await repo.createPaperSet(
        title: result['title'],
        durationMinutes: result['duration'],
        totalMarks: result['marks'],
        courseId: result['courseId'],
      );
      _snack('✅ Paper set created!');
      await _loadPaperSets();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> paper) async {
    final newStatus = !(paper['is_active'] as bool? ?? false);
    try {
      await ref
          .read(examRepositoryProvider)
          .togglePaperSetStatus(paper['id'] as int, newStatus);
      _snack(newStatus ? '✅ Paper set published!' : '📦 Moved to draft');
      await _loadPaperSets();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  Future<void> _deletePaperSet(Map<String, dynamic> paper) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('Delete Paper Set?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete "${paper['title']}" and ALL its questions. This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(examRepositoryProvider)
          .deletePaperSet(paper['id'] as int);
      _snack('🗑️ Paper set deleted');
      await _loadPaperSets();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  void _openQuestionManager(Map<String, dynamic> paper) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuestionManagerScreen(
          paperSetId: paper['id'] as int,
          paperTitle: paper['title'] as String? ?? 'Paper',
        ),
      ),
    ).then((_) => _loadPaperSets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A2E),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam Paper Manager',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Create & manage question papers',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadPaperSets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPaperSet,
        backgroundColor: AppColors.goldCta,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Paper', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : _paperSets.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPaperSets,
                  color: AppColors.goldCta,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _paperSets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PaperSetCard(
                      paper: _paperSets[i],
                      onToggle: () => _toggleStatus(_paperSets[i]),
                      onDelete: () => _deletePaperSet(_paperSets[i]),
                      onManageQuestions: () => _openQuestionManager(_paperSets[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text('No paper sets yet',
              style: AppTypography.headingSm.copyWith(color: Colors.white38)),
          const SizedBox(height: 8),
          Text('Tap + New Paper to create your first exam',
              style: AppTypography.bodySm.copyWith(color: Colors.white24)),
        ],
      ),
    );
  }
}

// ─── Paper Set Card ────────────────────────────────────────────────────────

class _PaperSetCard extends StatelessWidget {
  final Map<String, dynamic> paper;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onManageQuestions;

  const _PaperSetCard({
    required this.paper,
    required this.onToggle,
    required this.onDelete,
    required this.onManageQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = paper['is_active'] as bool? ?? false;
    final qCount = paper['total_questions'] ?? 0;
    final duration = paper['duration_minutes'] ?? 0;
    final marks = paper['total_marks'] ?? 0;
    final courseName = paper['courses']?['title'] ?? 'No course';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: isActive ? Colors.green : Colors.white38,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paper['title'] ?? 'Untitled',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatChip(Icons.help_outline_rounded, '$qCount Qs', Colors.blue),
                const SizedBox(width: 8),
                _StatChip(Icons.timer_outlined, '$duration min', Colors.purple),
                const SizedBox(width: 8),
                _StatChip(Icons.score_rounded, '$marks marks', AppColors.goldCta),
              ],
            ),
          ),

          // Actions
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_note_rounded,
                  label: 'Questions ($qCount)',
                  color: AppColors.goldCta,
                  onTap: onManageQuestions,
                ),
                const Spacer(),
                _ActionBtn(
                  icon: isActive
                      ? Icons.unpublished_rounded
                      : Icons.publish_rounded,
                  label: isActive ? 'Unpublish' : 'Publish',
                  color: isActive ? Colors.orange : Colors.green,
                  onTap: onToggle,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

// ─── Create Paper Set Dialog ───────────────────────────────────────────────

class _CreatePaperSetDialog extends StatefulWidget {
  const _CreatePaperSetDialog();

  @override
  State<_CreatePaperSetDialog> createState() => _CreatePaperSetDialogState();
}

class _CreatePaperSetDialogState extends State<_CreatePaperSetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _marksCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Create New Paper Set',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              controller: _titleCtrl,
              label: 'Paper Title',
              hint: 'e.g. Computer Fundamentals – Unit 1',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DialogField(
                    controller: _durationCtrl,
                    label: 'Duration (min)',
                    hint: '60',
                    keyboard: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Enter minutes'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogField(
                    controller: _marksCtrl,
                    label: 'Total Marks',
                    hint: '100',
                    keyboard: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Enter marks'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldCta,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'title': _titleCtrl.text.trim(),
              'duration': int.parse(_durationCtrl.text),
              'marks': int.parse(_marksCtrl.text),
              'courseId': null,
            });
          },
          child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldCta),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Question Manager Screen (push on top of paper manager)
// ═══════════════════════════════════════════════════════════════════════════

class _QuestionManagerScreen extends ConsumerStatefulWidget {
  final int paperSetId;
  final String paperTitle;
  const _QuestionManagerScreen({required this.paperSetId, required this.paperTitle});

  @override
  ConsumerState<_QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

class _QuestionManagerScreenState extends ConsumerState<_QuestionManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final qs = await ref
          .read(examRepositoryProvider)
          .getAdminQuestions(widget.paperSetId);
      setState(() {
        _questions = qs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to load questions: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _addOrEditQuestion({Map<String, dynamic>? existing}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _QuestionFormDialog(existing: existing),
    );
    if (result == null) return;

    try {
      final repo = ref.read(examRepositoryProvider);
      if (existing != null) {
        await repo.updateQuestion(
          questionId: existing['id'] as int,
          questionText: result['text'],
          optionA: result['a'],
          optionB: result['b'],
          optionC: result['c'],
          optionD: result['d'],
          correctOption: result['correct'],
          marks: result['marks'],
        );
        _snack('✅ Question updated');
      } else {
        await repo.addQuestion(
          paperSetId: widget.paperSetId,
          questionText: result['text'],
          optionA: result['a'],
          optionB: result['b'],
          optionC: result['c'],
          optionD: result['d'],
          correctOption: result['correct'],
          marks: result['marks'],
        );
        _snack('✅ Question added');
      }
      await _loadQuestions();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('Delete Question?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Q${q['question_number']}: ${(q['question_text'] as String? ?? '').substring(0, (q['question_text'] as String? ?? '').length.clamp(0, 60))}...',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(examRepositoryProvider)
          .deleteQuestion(q['id'] as int, widget.paperSetId);
      _snack('🗑️ Question deleted');
      await _loadQuestions();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A2E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.paperTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text('${_questions.length} question(s)',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditQuestion(),
        backgroundColor: AppColors.goldCta,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline_rounded,
                          size: 64, color: Colors.white12),
                      const SizedBox(height: 16),
                      Text('No questions yet',
                          style: AppTypography.headingSm
                              .copyWith(color: Colors.white38)),
                      const SizedBox(height: 8),
                      Text('Tap + Add Question to begin',
                          style: AppTypography.bodySm
                              .copyWith(color: Colors.white24)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final q = _questions[i];
                    final correct = (q['correct_option'] as String? ?? 'A').toUpperCase();
                    final opts = {'A': q['option_a'], 'B': q['option_b'], 'C': q['option_c'], 'D': q['option_d']};
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.goldCta.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Q${q['question_number'] ?? i + 1}',
                                    style: const TextStyle(
                                        color: AppColors.goldCta,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q['question_text'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: opts.entries.map((e) {
                                final isCorrect = e.key == correct;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCorrect
                                          ? Colors.green.withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCorrect)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Icon(Icons.check_circle_rounded,
                                              size: 12, color: Colors.green),
                                        ),
                                      Text(
                                        '${e.key}. ${e.value ?? ''}',
                                        style: TextStyle(
                                          color: isCorrect
                                              ? Colors.green
                                              : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () =>
                                    _addOrEditQuestion(existing: q),
                                icon: const Icon(Icons.edit_rounded,
                                    size: 14, color: Colors.blue),
                                label: const Text('Edit',
                                    style: TextStyle(
                                        color: Colors.blue, fontSize: 12)),
                              ),
                              TextButton.icon(
                                onPressed: () => _deleteQuestion(q),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 14, color: Colors.red),
                                label: const Text('Delete',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12)),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '${q['marks'] ?? 1} mark',
                                  style: const TextStyle(
                                      color: AppColors.goldCta, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── Question Form Dialog ──────────────────────────────────────────────────

class _QuestionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _QuestionFormDialog({this.existing});

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _aCtrl;
  late final TextEditingController _bCtrl;
  late final TextEditingController _cCtrl;
  late final TextEditingController _dCtrl;
  late final TextEditingController _marksCtrl;
  String _correct = 'A';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _textCtrl = TextEditingController(text: e?['question_text'] ?? '');
    _aCtrl = TextEditingController(text: e?['option_a'] ?? '');
    _bCtrl = TextEditingController(text: e?['option_b'] ?? '');
    _cCtrl = TextEditingController(text: e?['option_c'] ?? '');
    _dCtrl = TextEditingController(text: e?['option_d'] ?? '');
    _marksCtrl = TextEditingController(text: (e?['marks'] ?? 1).toString());
    _correct = (e?['correct_option'] as String? ?? 'A').toUpperCase();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _dCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: const Color(0xFF1A0A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Question' : 'Add Question',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Question text
              _DialogField(
                controller: _textCtrl,
                label: 'Question Text',
                hint: 'Enter the question...',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Options
              ...['A', 'B', 'C', 'D'].map((letter) {
                final ctrl = {'A': _aCtrl, 'B': _bCtrl, 'C': _cCtrl, 'D': _dCtrl}[letter]!;
                final isSelected = _correct == letter;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _correct = letter),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                : Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.white24,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Option $letter',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                            filled: true,
                            fillColor: isSelected
                                ? Colors.green.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.04),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: isSelected ? Colors.green : Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: isSelected
                                      ? Colors.green.withValues(alpha: 0.4)
                                      : Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.goldCta),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Marks
              SizedBox(
                width: 120,
                child: _DialogField(
                  controller: _marksCtrl,
                  label: 'Marks',
                  hint: '1',
                  keyboard: TextInputType.number,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Enter marks' : null,
                ),
              ),

              // Correct answer hint
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text('Tap a letter circle to mark the correct answer',
                        style: AppTypography.bodySm.copyWith(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldCta,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(context, {
                        'text': _textCtrl.text.trim(),
                        'a': _aCtrl.text.trim(),
                        'b': _bCtrl.text.trim(),
                        'c': _cCtrl.text.trim(),
                        'd': _dCtrl.text.trim(),
                        'correct': _correct,
                        'marks': double.parse(_marksCtrl.text),
                      });
                    },
                    child: Text(isEdit ? 'Update' : 'Add Question',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
