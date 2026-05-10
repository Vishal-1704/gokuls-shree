import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import '../data/exam_repository.dart';
import '../domain/exam_model.dart';

final examQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  id,
) async {
  return ref.read(examRepositoryProvider).getQuestions(id);
});

class ExamQuizScreen extends ConsumerStatefulWidget {
  final String examId;
  final Exam? examMetadata;

  const ExamQuizScreen({super.key, required this.examId, this.examMetadata});

  @override
  ConsumerState<ExamQuizScreen> createState() => _ExamQuizScreenState();
}

class _ExamQuizScreenState extends ConsumerState<ExamQuizScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitted = false;
  int _switchCounts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.examMetadata != null) {
      _remainingSeconds = widget.examMetadata!.durationMinutes * 60;
      _startTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isSubmitted) _handleAppSwitch();
    }
  }

  void _handleAppSwitch() {
    _switchCounts++;
    debugPrint("⚠️ App Switch Detected! Count: $_switchCounts");
    if (_switchCounts >= 3) {
      _submitExam();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitExam();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submitExam([List<Question>? questions]) {
    if (_isSubmitted) return;
    _isSubmitted = true;
    _timer?.cancel();

    int score = 0;
    int total = questions?.length ?? 0;

    if (questions != null) {
      for (int i = 0; i < total; i++) {
        if (_selectedAnswers[i] == questions[i].correctOptionIndex) {
          score++;
        }
      }
    }

    context.pushReplacement(
      '/exam-result',
      extra: {
        'score': score,
        'total': total,
        'title': widget.examMetadata?.title ?? 'Exam',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(examQuestionsProvider(widget.examId));
    final isTimeWarning = _remainingSeconds < 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          widget.examMetadata?.title ?? 'Exam',
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
        actions: [
          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isTimeWarning ? Colors.red : const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTimeWarning ? Icons.warning_rounded : Icons.timer,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No questions found.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              if (_timer == null && !_isSubmitted) {
                _remainingSeconds = 30 * 60;
                _startTimer();
              }

              final answered = _selectedAnswers.length;

              return Column(
                children: [
                  // ──── Progress Bar ────
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),

                  // ──── Question Counter + Answered ────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        Text(
                          '$answered/${questions.length} answered',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ──── Question + Options ────
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question text
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  question.text,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Options
                              ...List.generate(question.options.length, (
                                optIndex,
                              ) {
                                final isSelected =
                                    _selectedAnswers[index] == optIndex;
                                final optLabel = String.fromCharCode(
                                  65 + optIndex,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedAnswers[index] = optIndex;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                                    .withOpacity(0.08)
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey.shade100,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppTheme.primaryColor
                                                      : Colors.grey.shade400,
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 18,
                                                      color: Colors.white,
                                                    )
                                                  : Text(
                                                      optLabel,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                question.options[optIndex],
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // ──── Bottom Navigation ────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_currentQuestionIndex > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentQuestionIndex--);
                              },
                              icon: const Icon(Icons.arrow_back_ios, size: 14),
                              label: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (_currentQuestionIndex > 0)
                          const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentQuestionIndex < questions.length - 1
                                  ? AppTheme.primaryColor
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (_currentQuestionIndex <
                                  questions.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentQuestionIndex++);
                              } else {
                                // Confirm submit
                                _showSubmitDialog(questions);
                              }
                            },
                            icon: Icon(
                              _currentQuestionIndex < questions.length - 1
                                  ? Icons.arrow_forward_ios
                                  : Icons.check_circle,
                              size: 16,
                            ),
                            label: Text(
                              _currentQuestionIndex < questions.length - 1
                                  ? 'Next'
                                  : 'Submit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          // ──── Anti-Cheat Warning Banner ────
          if (_switchCounts > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "⚠️ App switch detected! ($_switchCounts/3 — auto-submit at 3)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSubmitDialog(List<Question> questions) {
    final unanswered = questions.length - _selectedAnswers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answered: ${_selectedAnswers.length}/${questions.length}',
              style: const TextStyle(fontSize: 15),
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 6),
              Text(
                '$unanswered questions unanswered!',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Once submitted, you cannot change your answers.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam(questions);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
