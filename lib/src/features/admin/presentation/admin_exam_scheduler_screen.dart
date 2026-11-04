import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';

final schedulerCoursesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(adminRepositoryProvider).getCourses(),
);

class AdminExamSchedulerScreen extends ConsumerStatefulWidget {
  const AdminExamSchedulerScreen({super.key});

  @override
  ConsumerState<AdminExamSchedulerScreen> createState() =>
      _AdminExamSchedulerScreenState();
}

class _AdminExamSchedulerScreenState
    extends ConsumerState<AdminExamSchedulerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _maxAttemptsController = TextEditingController(text: '1');
  final _marksCorrectController = TextEditingController(text: '1');
  final _marksWrongController = TextEditingController(text: '0');
  final _marksUnansweredController = TextEditingController(text: '0');
  final _negativeFormulaController = TextEditingController();
  final _assignmentValueController = TextEditingController();

  String? _selectedPaperSetId;
  String? _selectedAssignmentValue;
  String? _selectedAssignmentLabel;
  String _assignmentType = 'student';
  DateTime? _startAt;
  DateTime? _publishAt;
  DateTime? _endAt;
  bool _negativeMarking = false;
  bool _loading = false;

  String get _assignmentValueLabel {
    switch (_assignmentType) {
      case 'course':
        return 'Course ID';
      case 'batch':
        return 'Batch ID';
      case 'branch':
        return 'Branch ID';
      default:
        return 'Student UUID';
    }
  }

  String? _validateAssignmentValue(String? value) {
    final raw = (_selectedAssignmentValue ?? value)?.trim() ?? '';
    if (raw.isEmpty) return 'Required';

    if (_assignmentType == 'student') {
      return null;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 'Must be a valid numeric ID';
    }
    return null;
  }

  Future<void> _openSearchablePicker({
    required String title,
    required List<Map<String, dynamic>> rows,
    required String Function(Map<String, dynamic>) valueBuilder,
    required String Function(Map<String, dynamic>) labelBuilder,
    FormFieldState<String>? formState,
  }) async {
    final queryController = TextEditingController();
    var filtered = List<Map<String, dynamic>>.from(rows);

    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: queryController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (q) {
                        final needle = q.trim().toLowerCase();
                        setDialogState(() {
                          if (needle.isEmpty) {
                            filtered = List<Map<String, dynamic>>.from(rows);
                            return;
                          }
                          filtered = rows.where((row) {
                            final text = labelBuilder(row).toLowerCase();
                            return text.contains(needle);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final row = filtered[index];
                                final value = valueBuilder(row);
                                final label = labelBuilder(row);
                                return ListTile(
                                  dense: true,
                                  title: Text(label),
                                  onTap: () => Navigator.of(
                                    dialogContext,
                                  ).pop({'value': value, 'label': label}),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    queryController.dispose();
    if (!mounted || selected == null) return;

    setState(() {
      _selectedAssignmentValue = selected['value'];
      _selectedAssignmentLabel = selected['label'];
      _assignmentValueController.text = selected['value'] ?? '';
    });
    formState?.didChange(_selectedAssignmentValue);
  }

  Widget _buildSearchableAssignmentField({
    required String label,
    required List<Map<String, dynamic>> rows,
    required String pickerTitle,
    required String Function(Map<String, dynamic>) valueBuilder,
    required String Function(Map<String, dynamic>) labelBuilder,
  }) {
    return FormField<String>(
      validator: _validateAssignmentValue,
      initialValue: _selectedAssignmentValue,
      builder: (state) {
        final hasValue =
            _selectedAssignmentValue != null &&
            _selectedAssignmentValue!.trim().isNotEmpty;

        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            helperText: 'Tap to search and select',
            helperStyle: const TextStyle(color: AppColors.textMuted),
            errorText: state.errorText,
          ),
          child: InkWell(
            onTap: () => _openSearchablePicker(
              title: pickerTitle,
              rows: rows,
              valueBuilder: valueBuilder,
              labelBuilder: labelBuilder,
              formState: state,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? (_selectedAssignmentLabel ??
                                _selectedAssignmentValue!)
                          : 'Select $label',
                      style: TextStyle(
                        color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.goldCta),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentPicker() {
    switch (_assignmentType) {
      case 'student':
        final studentsAsync = ref.watch(adminStudentsProvider);
        return studentsAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return _buildManualAssignmentValueField();
            }
            return _buildSearchableAssignmentField(
              label: 'Student',
              pickerTitle: 'Select Student',
              rows: rows,
              valueBuilder: (s) => (s['id'] ?? '').toString(),
              labelBuilder: (s) =>
                  '${s['name'] ?? 'Student'} (${s['reg_no'] ?? 'N/A'})',
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _buildPickerFallback(
            message: 'Unable to load students: $error',
            onRetry: () => ref.invalidate(adminStudentsProvider),
          ),
        );
      case 'course':
        final coursesAsync = ref.watch(schedulerCoursesProvider);
        return coursesAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return _buildManualAssignmentValueField();
            }
            return _buildSearchableAssignmentField(
              label: 'Course',
              pickerTitle: 'Select Course',
              rows: rows,
              valueBuilder: (c) => (c['id'] ?? '').toString(),
              labelBuilder: (c) => '${c['title'] ?? 'Course'}',
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _buildPickerFallback(
            message: 'Unable to load courses: $error',
            onRetry: () => ref.invalidate(schedulerCoursesProvider),
          ),
        );
      case 'branch':
        final branchesAsync = ref.watch(branchesProvider);
        return branchesAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return _buildManualAssignmentValueField();
            }
            return _buildSearchableAssignmentField(
              label: 'Branch',
              pickerTitle: 'Select Branch',
              rows: rows,
              valueBuilder: (b) => (b['id'] ?? '').toString(),
              labelBuilder: (b) => '${b['name'] ?? 'Branch'}',
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _buildPickerFallback(
            message: 'Unable to load branches: $error',
            onRetry: () => ref.invalidate(branchesProvider),
          ),
        );
      case 'batch':
        final batchesAsync = ref.watch(adminBatchTargetsProvider);
        return batchesAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return _buildPickerFallback(
                message: 'No batches are available yet.',
                onRetry: () => ref.invalidate(adminBatchTargetsProvider),
              );
            }
            return _buildSearchableAssignmentField(
              label: 'Batch',
              pickerTitle: 'Select Batch',
              rows: rows,
              valueBuilder: (b) => (b['id'] ?? '').toString(),
              labelBuilder: (b) => (b['label'] ?? 'Batch').toString(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _buildPickerFallback(
            message: 'Unable to load batches: $error',
            onRetry: () => ref.invalidate(adminBatchTargetsProvider),
          ),
        );
      default:
        return _buildManualAssignmentValueField();
    }
  }

  Widget _buildPickerFallback({required String message, required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildManualAssignmentValueField() {
    return TextFormField(
      controller: _assignmentValueController,
      decoration: InputDecoration(
        labelText: _assignmentValueLabel,
        helperText: _assignmentType == 'student'
            ? 'Provide student user id/uuid from students table'
            : 'Provide numeric id for selected assignment type',
      ),
      validator: _validateAssignmentValue,
      onChanged: (v) => _selectedAssignmentValue = v.trim().isEmpty ? null : v,
    );
  }

  String _formatDateTime(DateTime? value, String fallback) {
    if (value == null) return fallback;
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date $time';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxAttemptsController.dispose();
    _marksCorrectController.dispose();
    _marksWrongController.dispose();
    _marksUnansweredController.dispose();
    _negativeFormulaController.dispose();
    _assignmentValueController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required int field}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (field == 0) {
        _startAt = dt;
      } else if (field == 1) {
        _publishAt = dt;
      } else {
        _endAt = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaperSetId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select paper set')));
      return;
    }
    if (_startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exam start time')),
      );
      return;
    }
    if (_publishAt != null && _publishAt!.isAfter(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publish time must be before or equal to start time'),
        ),
      );
      return;
    }
    if (_endAt != null && _startAt != null && _endAt!.isBefore(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(examRepositoryProvider);
      final assignmentRaw =
          (_selectedAssignmentValue ?? _assignmentValueController.text).trim();
      await repo.createExamSchedule(
        paperSetId: int.parse(_selectedPaperSetId!),
        title: _titleController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
        startAt: _startAt!,
        publishAt: _publishAt,
        endAt: _endAt,
        assignmentType: _assignmentType,
        assignmentValue: assignmentRaw,
        maxAttempts: int.parse(_maxAttemptsController.text.trim()),
        negativeMarkingEnabled: _negativeMarking,
        marksCorrect: double.parse(_marksCorrectController.text.trim()),
        marksWrong: double.parse(_marksWrongController.text.trim()),
        marksUnanswered: double.parse(_marksUnansweredController.text.trim()),
        negativeFormula: _negativeFormulaController.text.trim().isEmpty
            ? null
            : _negativeFormulaController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam scheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState?.reset();
      _titleController.clear();
      _assignmentValueController.clear();
      setState(() {
        _selectedPaperSetId = null;
        _selectedAssignmentValue = null;
        _selectedAssignmentLabel = null;
        _startAt = null;
        _publishAt = null;
        _endAt = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paperSetsAsync = ref.watch(adminPaperSetsProvider);
    final sessionAsync = ref.watch(sessionProvider);
    final isBranchAdmin = sessionAsync?.role == UserRole.branchAdmin;
    final titleText = isBranchAdmin ? 'Test Scheduler' : 'Exam Scheduler';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminPaperSetsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'View Results',
            onPressed: () => context.push(
              isBranchAdmin ? '/admin/schedule-results' : '/super-admin/schedule-results',
            ),
          ),
        ],
      ),
      body: paperSetsAsync.when(
        data: (paperSets) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (paperSets.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'No paper sets found. Please create an exam paper first.',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/super-admin/papers'),
                          child: const Text('Create Paper', style: TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: (paperSets.any((p) => p['id'].toString() == _selectedPaperSetId))
                      ? _selectedPaperSetId
                      : null,
                  dropdownColor: AppColors.inkNavy800,
                  iconEnabledColor: AppColors.goldCta,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Paper Set',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'Select a paper set',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  isExpanded: true,
                  items: paperSets.isEmpty
                      ? [
                          const DropdownMenuItem<String>(
                            value: null,
                            enabled: false,
                            child: Text(
                              'No paper sets available — create one first',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        ]
                      : paperSets
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text(
                                (p['title'] ?? 'Paper Set').toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: paperSets.isEmpty ? null : (v) => setState(() => _selectedPaperSetId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Schedule Title',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Invalid duration';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(field: 0),
                        icon: const Icon(Icons.schedule),
                        label: Text(_formatDateTime(_startAt, 'Pick Start At (Required)')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(field: 2),
                        icon: const Icon(Icons.event_busy_outlined),
                        label: Text(_formatDateTime(_endAt, 'Pick End At (Optional Deadline)')),
                      ),
                    ),
                    if (_endAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear End Date',
                        onPressed: () => setState(() => _endAt = null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(field: 1),
                        icon: const Icon(Icons.publish),
                        label: Text(
                          _formatDateTime(
                            _publishAt,
                            'Pick Publish At (Optional)',
                          ),
                        ),
                      ),
                    ),
                    if (_publishAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear Publish Date',
                        onPressed: () => setState(() => _publishAt = null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _assignmentType,
                  dropdownColor: AppColors.inkNavy800,
                  iconEnabledColor: AppColors.goldCta,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Assignment Type',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'student',
                      child: Text('Per Student', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    DropdownMenuItem(
                      value: 'course',
                      child: Text('By Course', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    DropdownMenuItem(
                      value: 'batch',
                      child: Text('By Batch', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    DropdownMenuItem(
                      value: 'branch',
                      child: Text('By Branch', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _assignmentType = v ?? 'student';
                      _selectedAssignmentValue = null;
                      _selectedAssignmentLabel = null;
                      _assignmentValueController.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildAssignmentPicker(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxAttemptsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Attempts'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Invalid attempts';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _negativeMarking,
                  onChanged: (v) => setState(() => _negativeMarking = v),
                  title: const Text('Enable Negative Marking'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marksCorrectController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Correct answer multiplier',
                    helperText: '1 = full marks for that question. e.g. a 2-mark question awards 2.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marksWrongController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Wrong answer multiplier (- or 0)',
                    helperText: '-0.25 = lose a quarter of that question\'s marks. Scales with each question\'s own weight.',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null) return 'Invalid number';
                    if (n > 0) return 'Keep this 0 or negative';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marksUnansweredController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Unanswered multiplier',
                    helperText: 'Usually 0. Same scaling as above.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _negativeFormulaController,
                  enabled: _negativeMarking,
                  decoration: const InputDecoration(
                    labelText: 'Formula (Optional)',
                    helperText: 'Example: score = c*1 - w*0.25',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_loading ? 'Saving...' : (isBranchAdmin ? 'Schedule Test' : 'Schedule Exam')),
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading paper sets...', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.invalidate(adminPaperSetsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Failed to load paper sets: $e')),
      ),
    );
  }
}
