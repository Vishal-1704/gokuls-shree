import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/domain/exam_model.dart';
import 'package:gokul_shree_app/src/features/exams/presentation/question_manager_screen.dart';
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePaperSetBottomSheet(),
    );
    if (result == null) return;

    try {
      final repo = ref.read(examRepositoryProvider);
      await repo.createPaperSet(
        title: result['title'],
        durationMinutes: result['duration'],
        totalMarks: result['marks'],
        branchId: result['branchId'],
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
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Delete Paper Set?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'This will permanently delete "${paper['name']}" and ALL its questions. This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
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
        builder: (_) => QuestionManagerScreen(
          paperSetId: paper['id'] as int,
          paperTitle: paper['name'] as String? ?? 'Paper',
        ),
      ),
    ).then((_) => _loadPaperSets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam Paper Manager',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            Text('Create & manage question papers',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
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
          Icon(Icons.quiz_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('No paper sets yet',
              style: AppTypography.headingSm.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Tap + New Paper to create your first exam',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
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
    final isActive = (paper['status'] as int? ?? 0) == 1;
    final qCount = paper['total_questions'] ?? 0;
    final duration = paper['time_limit'] ?? 0;
    final marks = paper['total_marks'] ?? 0;
    final branchName = paper['branches']?['name'] ?? 'All Branches';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.4)
              : AppColors.textPrimary.withValues(alpha: 0.06),
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
                        : AppColors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: isActive ? Colors.green : AppColors.textMuted,
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
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branchName,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
          const Divider(color: AppColors.divider10, height: 1),
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

class _CreatePaperSetBottomSheet extends ConsumerStatefulWidget {
  const _CreatePaperSetBottomSheet();

  @override
  ConsumerState<_CreatePaperSetBottomSheet> createState() => _CreatePaperSetBottomSheetState();
}

class _CreatePaperSetBottomSheetState extends ConsumerState<_CreatePaperSetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _marksCtrl = TextEditingController(text: '100');
  int? _selectedCourseId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(adminCoursesProvider);
    final courses = coursesAsync.value ?? [];
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: keyboardHeight + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.inkNavy900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Create New Paper Set',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill out the details below to initialize a new exam paper.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              _DialogField(
                controller: _titleCtrl,
                label: 'Paper Title',
                hint: 'e.g. Computer Fundamentals – Unit 1',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedCourseId,
                dropdownColor: AppColors.inkNavy800,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Course',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.textPrimary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                items: courses.map((c) => DropdownMenuItem<int>(
                  value: c['id'], 
                  child: Text(c['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCourseId = v),
                validator: (v) => v == null ? 'Please select a course' : null,
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, {
                      'title': _titleCtrl.text.trim(),
                      'duration': int.parse(_durationCtrl.text),
                      'marks': int.parse(_marksCtrl.text),
                      'branchId': null,
                      'courseId': _selectedCourseId,
                    });
                  },
                  child: const Text('Create Paper Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.textPrimary.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldCta),
        ),
      ),
    );
  }
}
