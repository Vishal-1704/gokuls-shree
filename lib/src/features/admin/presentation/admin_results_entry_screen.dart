import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class AdminResultsEntryScreen extends ConsumerStatefulWidget {
  final String? initialStudentId;
  const AdminResultsEntryScreen({super.key, this.initialStudentId});

  @override
  ConsumerState<AdminResultsEntryScreen> createState() =>
      _AdminResultsEntryScreenState();
}

class _AdminResultsEntryScreenState
    extends ConsumerState<AdminResultsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examController = TextEditingController();
  final _subjectController = TextEditingController();
  final _obtainedController = TextEditingController();
  final _totalController = TextEditingController(text: '100');
  final _gradeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
  }

  @override
  void dispose() {
    _examController.dispose();
    _subjectController.dispose();
    _obtainedController.dispose();
    _totalController.dispose();
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.addStudentResult(
        studentId: _selectedStudentId!,
        examName: _examController.text.trim(),
        subjectName: _subjectController.text.trim(),
        marksObtained: double.parse(_obtainedController.text.trim()),
        totalMarks: double.parse(_totalController.text.trim()),
        grade: _gradeController.text.trim().isEmpty
            ? null
            : _gradeController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _subjectController.clear();
      _obtainedController.clear();
      _gradeController.clear();
      _notesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save result: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsFuture = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Text(
          'Results Entry',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: studentsFuture.when(
        data: (students) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Select Student',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.person_search_outlined, color: AppColors.textMuted),
                    ),
                    items: students
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['id'].toString(),
                            child: Text(
                              '${s['name'] ?? 'Unknown'} (${s['reg_no'] ?? 'N/A'})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStudentId = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _examController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Exam Name',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.assignment_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Exam name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.menu_book_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Subject is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _obtainedController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Obtained Marks',
                            labelStyle: TextStyle(color: AppColors.textMuted),
                            prefixIcon: Icon(Icons.score_outlined, color: AppColors.textMuted),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            final n = double.tryParse(v.trim());
                            if (n == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _totalController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                            labelStyle: TextStyle(color: AppColors.textMuted),
                            prefixIcon: Icon(Icons.straighten_outlined, color: AppColors.textMuted),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            final n = double.tryParse(v.trim());
                            if (n == null || n <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _gradeController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Grade (Optional)',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.workspace_premium_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.notes_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSubmitting ? 'Saving...' : 'Save Result'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (e, _) => Center(
          child: Text(
            'Unable to load students: $e',
            style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
