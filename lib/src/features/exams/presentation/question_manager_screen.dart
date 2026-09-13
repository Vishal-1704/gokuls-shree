import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';

/// Super Admin: Author MCQ questions for a paper.
class QuestionManagerScreen extends ConsumerStatefulWidget {
  final int paperSetId;
  final String paperTitle;

  const QuestionManagerScreen({
    super.key,
    required this.paperSetId,
    required this.paperTitle,
  });

  @override
  ConsumerState<QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

class _QuestionManagerScreenState extends ConsumerState<QuestionManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final questions = await ref.read(examRepositoryProvider).getAdminQuestions(widget.paperSetId);
      setState(() {
        _questions = questions;
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
    ));
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionFormSheet(existing: existing),
    );
    if (result == null) return;

    try {
      final repo = ref.read(examRepositoryProvider);

      String? imageUrl = result['existingImageUrl'] as String?;
      final newImageBytes = result['imageBytes'] as Uint8List?;
      if (newImageBytes != null) {
        imageUrl = await repo.uploadQuestionImage(result['imageFileName'] as String, newImageBytes);
      }

      if (existing != null) {
        await repo.updateQuestion(
          questionId: existing['id'] as int,
          questionText: result['questionText'],
          optionA: result['optionA'],
          optionB: result['optionB'],
          optionC: result['optionC'],
          optionD: result['optionD'],
          correctOption: result['correctOption'],
          marks: result['marks'],
          subject: result['subject'],
          difficulty: result['difficulty'],
          imageUrl: imageUrl,
        );
        _snack('Question updated');
      } else {
        await repo.addQuestion(
          paperSetId: widget.paperSetId,
          questionText: result['questionText'],
          optionA: result['optionA'],
          optionB: result['optionB'],
          optionC: result['optionC'],
          optionD: result['optionD'],
          correctOption: result['correctOption'],
          marks: result['marks'],
          subject: result['subject'],
          difficulty: result['difficulty'],
          imageUrl: imageUrl,
        );
        _snack('Question added');
      }
      await _load();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Remove Question?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This removes the question from this paper.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(examRepositoryProvider).deleteQuestion(question['id'] as int, widget.paperSetId);
      _snack('Question removed');
      await _load();
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMarks = _questions.fold<double>(0, (sum, q) => sum + ((q['marks'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.paperTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            Text('${_questions.length} questions • $totalMarks marks',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
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
                      Icon(Icons.help_outline_rounded, size: 64, color: AppColors.divider),
                      const SizedBox(height: 16),
                      Text('No questions yet', style: AppTypography.headingSm.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text('Tap + Add Question to start building this paper',
                          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.goldCta,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final q = _questions[i];
                      return _QuestionCard(
                        index: i + 1,
                        question: q,
                        onEdit: () => _openForm(existing: q),
                        onDelete: () => _deleteQuestion(q),
                      );
                    },
                  ),
                ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['A', 'B', 'C', 'D'];
    final correct = question['correct_option'] as String? ?? 'A';
    final subject = question['subject'] as String?;
    final difficulty = question['difficulty'] as String? ?? 'medium';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.goldCta.withValues(alpha: 0.15),
                child: Text('$index', style: const TextStyle(color: AppColors.goldCta, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question['question_text'] ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
            ],
          ),
          if (question['image_url'] != null && (question['image_url'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                question['image_url'],
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...options.map((opt) {
            final isCorrect = opt == correct;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isCorrect ? Colors.green : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question['option_${opt.toLowerCase()}'] ?? '',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : AppColors.textSecondary,
                        fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _Chip('${question['marks'] ?? 1} marks', AppColors.goldCta),
              if (subject != null && subject.isNotEmpty) _Chip(subject, Colors.blue),
              _Chip(difficulty, difficulty == 'hard' ? Colors.red : (difficulty == 'easy' ? Colors.green : Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Add / Edit Question Form ──────────────────────────────────────────────

class _QuestionFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _QuestionFormSheet({this.existing});

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _optionDCtrl;
  late final TextEditingController _marksCtrl;
  late final TextEditingController _subjectCtrl;
  late String _correctOption;
  late String _difficulty;
  String? _existingImageUrl;
  Uint8List? _newImageBytes;
  String? _newImageFileName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _questionCtrl = TextEditingController(text: e?['question_text'] ?? '');
    _optionACtrl = TextEditingController(text: e?['option_a'] ?? '');
    _optionBCtrl = TextEditingController(text: e?['option_b'] ?? '');
    _optionCCtrl = TextEditingController(text: e?['option_c'] ?? '');
    _optionDCtrl = TextEditingController(text: e?['option_d'] ?? '');
    _marksCtrl = TextEditingController(text: (e?['marks'] ?? 1).toString());
    _subjectCtrl = TextEditingController(text: e?['subject'] ?? '');
    _correctOption = e?['correct_option'] as String? ?? 'A';
    _difficulty = e?['difficulty'] as String? ?? 'medium';
    _existingImageUrl = e?['image_url'] as String?;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _newImageBytes = bytes;
      _newImageFileName = picked.name;
    });
  }

  void _removeImage() {
    setState(() {
      _newImageBytes = null;
      _newImageFileName = null;
      _existingImageUrl = null;
    });
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    _marksCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existing != null;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: keyboardHeight + 24),
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
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                isEditing ? 'Edit Question' : 'Add Question',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              _field(_questionCtrl, 'Question', maxLines: 3, required: true),
              const SizedBox(height: 14),
              _buildImagePicker(),
              const SizedBox(height: 14),
              _field(_optionACtrl, 'Option A', required: true),
              const SizedBox(height: 10),
              _field(_optionBCtrl, 'Option B', required: true),
              const SizedBox(height: 10),
              _field(_optionCCtrl, 'Option C', required: true),
              const SizedBox(height: 10),
              _field(_optionDCtrl, 'Option D', required: true),
              const SizedBox(height: 16),
              const Text('Correct Answer', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'A', label: Text('A')),
                  ButtonSegment(value: 'B', label: Text('B')),
                  ButtonSegment(value: 'C', label: Text('C')),
                  ButtonSegment(value: 'D', label: Text('D')),
                ],
                selected: {_correctOption},
                onSelectionChanged: (v) => setState(() => _correctOption = v.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field(_marksCtrl, 'Marks', keyboard: TextInputType.number, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_subjectCtrl, 'Subject (optional)')),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Difficulty', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'easy', label: Text('Easy')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'hard', label: Text('Hard')),
                ],
                selected: {_difficulty},
                onSelectionChanged: (v) => setState(() => _difficulty = v.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, {
                      'questionText': _questionCtrl.text.trim(),
                      'optionA': _optionACtrl.text.trim(),
                      'optionB': _optionBCtrl.text.trim(),
                      'optionC': _optionCCtrl.text.trim(),
                      'optionD': _optionDCtrl.text.trim(),
                      'correctOption': _correctOption,
                      'marks': double.parse(_marksCtrl.text.trim()),
                      'subject': _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
                      'difficulty': _difficulty,
                      'imageBytes': _newImageBytes,
                      'imageFileName': _newImageFileName,
                      'existingImageUrl': _existingImageUrl,
                    });
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Question',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _newImageBytes != null || (_existingImageUrl?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Diagram / Image (optional)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 8),
        if (hasImage)
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _newImageBytes != null
                    ? Image.memory(_newImageBytes!, height: 140, width: double.infinity, fit: BoxFit.contain)
                    : Image.network(_existingImageUrl!, height: 140, width: double.infinity, fit: BoxFit.contain),
              ),
              IconButton(
                icon: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                onPressed: _removeImage,
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inkNavy700,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted),
                    SizedBox(height: 4),
                    Text('Tap to add an image', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text, bool required = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.inkNavy700,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.goldCta)),
      ),
    );
  }
}
