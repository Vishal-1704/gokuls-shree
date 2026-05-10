import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/features/exams/domain/exam_model.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';

class ExamInstructionsScreen extends ConsumerStatefulWidget {
  final Exam exam;

  const ExamInstructionsScreen({super.key, required this.exam});

  @override
  ConsumerState<ExamInstructionsScreen> createState() =>
      _ExamInstructionsScreenState();
}

class _ExamInstructionsScreenState
    extends ConsumerState<ExamInstructionsScreen> {
  bool _agreed = false;
  bool _checkingStart = false;

  Future<void> _handleStartExam() async {
    if (_checkingStart) return;

    setState(() => _checkingStart = true);
    final repo = ref.read(examRepositoryProvider);
    final check = await repo.canStartExam(widget.exam);
    if (!mounted) return;

    setState(() => _checkingStart = false);

    if (check['allowed'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((check['reason'] ?? 'Unable to start exam').toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.pushReplacement(
      '/exam-start/${widget.exam.id}',
      extra: widget.exam,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Exam Instructions'),
        elevation: 0,
        backgroundColor: AppColors.inkNavy800,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──── Exam Info Header ────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.goldCta.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exam.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoBadge(
                        icon: Icons.timer_outlined,
                        text: '${widget.exam.durationMinutes} min',
                      ),
                      const SizedBox(width: 12),
                      _InfoBadge(
                        icon: Icons.quiz_outlined,
                        text: '${widget.exam.questionsCount} Questions',
                      ),
                      const SizedBox(width: 12),
                      _InfoBadge(
                        icon: Icons.star_outline,
                        text: '${widget.exam.totalMarks} marks',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ──── Instructions ────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.goldCta),
                      SizedBox(width: 8),
                      Text(
                        "Read Carefully",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldCta,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _buildInstruction(
                    "1",
                    "Ensure you have a stable internet connection.",
                    Icons.wifi,
                  ),
                  _buildInstruction(
                    "2",
                    "Do NOT switch tabs or minimize the app. Doing so may auto-submit your exam.",
                    Icons.tab_unselected,
                  ),
                  _buildInstruction(
                    "3",
                    "Screenshots are strictly prohibited.",
                    Icons.no_photography,
                  ),
                  _buildInstruction(
                    "4",
                    "Once submitted, you cannot re-attempt the questions.",
                    Icons.lock_outline,
                  ),
                  _buildInstruction(
                    "5",
                    "The timer starts immediately after you click 'Start Exam'.",
                    Icons.play_circle_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ──── Warning Banner ────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "App switching is monitored. Any attempt to leave the exam screen will be recorded and may auto-submit your exam.",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ──── Agreement Checkbox ────
            Container(
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                title: const Text(
                  "I have read the instructions carefully and want to proceed.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                value: _agreed,
                activeColor: AppColors.goldCta,
                checkColor: AppColors.inkNavy900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (val) {
                  setState(() => _agreed = val ?? false);
                },
              ),
            ),
            const SizedBox(height: 24),

            // ──── Start Button ────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_agreed && !_checkingStart)
                    ? _handleStartExam
                    : null,
                icon: _checkingStart
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _checkingStart ? 'Checking...' : 'Start Exam',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldCta,
                  foregroundColor: AppColors.inkNavy900,
                  disabledBackgroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: _agreed ? 4 : 0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.goldCta.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.goldCta,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldCta.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldCta),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
