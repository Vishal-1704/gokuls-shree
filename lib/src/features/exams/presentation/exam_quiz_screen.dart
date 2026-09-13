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
  String? _attemptId;
  Map<String, dynamic>? _resumedAnswers; // question id -> selected_option (1-4)
  bool _appliedResume = false;
  Timer? _pauseGraceTimer;
  List<Question>? _loadedQuestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.examMetadata != null) {
      _remainingSeconds = widget.examMetadata!.durationMinutes * 60;
      _startTimer();
    }
    _startSession();
  }

  /// Creates (or resumes) the `attempts` row for this exam up front so every
  /// answer and the final submission has somewhere to persist to —
  /// previously this screen never called into the repository at all and
  /// scored purely in memory, so nothing about an attempt was ever saved.
  /// Answer taps are blocked in the UI until this resolves (see the
  /// "Preparing your exam" overlay in build()) so a fast tap can't land
  /// before there's an attempt id to attach it to.
  Future<void> _startSession() async {
    try {
      final result = await ref.read(examRepositoryProvider).startExamSession(
            paperSetId: widget.examId,
            studentId: '',
            examScheduleId: widget.examMetadata?.scheduleId,
          );
      if (!mounted || result == null) return;

      // remaining_seconds is computed by the database (attempt_remaining_seconds,
      // migration 20240301000008) from the server's own clock — the
      // student's device clock is never consulted, so a skewed phone
      // clock can't cause a premature auto-submit or a wrong countdown.
      final remainingSeconds = result['remaining_seconds'] as int?;

      setState(() {
        _attemptId = result['attempt_id'] as String?;
        _resumedAnswers = Map<String, dynamic>.from(result['answers'] as Map? ?? {});
        if (remainingSeconds != null) _remainingSeconds = remainingSeconds;
      });

      if (remainingSeconds == 0) {
        // Resumed an attempt whose window already elapsed while the app
        // was closed — submit immediately so it gets graded rather than
        // sitting stuck in_progress forever.
        _submitExam(reason: 'time_expired');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start exam session: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyResumedAnswers(List<Question> questions) {
    if (_resumedAnswers == null || _appliedResume) return;
    for (var i = 0; i < questions.length; i++) {
      final val = _resumedAnswers![questions[i].id];
      if (val is int) _selectedAnswers[i] = val - 1;
    }
    _appliedResume = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only `paused` (actually backgrounded) counts — `inactive` also fires
    // for transient system overlays (an incoming call banner, the
    // notification shade, a permission prompt) that never leave the app,
    // and treating those as switches disqualified students for things
    // that weren't cheating.
    if (state == AppLifecycleState.paused) {
      _pauseGraceTimer?.cancel();
      // 8s (not 3s) — a longer, more forgiving window before a transient
      // system interruption (an incoming call ringing, a permission
      // prompt) that keeps the app backgrounded a few seconds counts as
      // a strike.
      _pauseGraceTimer = Timer(const Duration(seconds: 8), () {
        if (!_isSubmitted) _handleAppSwitch();
      });
    } else if (state == AppLifecycleState.resumed) {
      _pauseGraceTimer?.cancel();
    }
  }

  void _handleAppSwitch() {
    _switchCounts++;
    debugPrint("⚠️ App Switch Detected! Count: $_switchCounts");
    if (mounted) setState(() {});
    if (_switchCounts >= 3) {
      _submitExam(reason: 'app_switch');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitExam(reason: 'time_expired');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pauseGraceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submitExam({String? reason}) async {
    final questions = _loadedQuestions;
    if (_isSubmitted) return;
    _isSubmitted = true;
    _timer?.cancel();
    _pauseGraceTimer?.cancel();

    final attemptId = _attemptId;
    if (attemptId == null) {
      _isSubmitted = false; // never actually started — let the student retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam session was not ready — please try submitting again.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Re-send every currently selected answer before grading. Taps fire
    // submitAnswer without blocking the UI, so if any of those silently
    // failed (a network blip), this flush is the last chance to get the
    // real state to the server before grade_attempt reads it.
    if (questions != null) {
      final repo = ref.read(examRepositoryProvider);
      for (final entry in _selectedAnswers.entries) {
        if (entry.key >= questions.length) continue;
        final optLabel = String.fromCharCode(65 + entry.value);
        try {
          await repo.submitAnswer(
            sessionId: attemptId,
            questionId: questions[entry.key].id,
            selectedOption: optLabel,
          );
        } catch (_) {
          // Best-effort — grade_attempt will just treat that one as
          // unanswered if this resend also fails.
        }
      }
    }

    try {
      final result = await ref.read(examRepositoryProvider).finishExam(attemptId, reason: reason);
      if (!mounted) return;
      context.pushReplacement(
        '/exam-result',
        extra: {
          'score': ((result?['score'] as num?) ?? 0).round(),
          'total': ((result?['total_marks'] as num?) ?? (questions?.length ?? 0)).round(),
          'title': widget.examMetadata?.title ?? 'Exam',
          'passed': result?['result'] == 'pass',
        },
      );
    } catch (e) {
      // grade_attempt raises if the schedule's time window has already
      // closed — surface that instead of showing a fabricated result.
      _isSubmitted = false;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Could not submit'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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
              _loadedQuestions = questions;
              _applyResumedAnswers(questions);
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
                                    color: Color(0xFF0F172A),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    question.imageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ],
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
                                        final attemptId = _attemptId;
                                        if (attemptId != null) {
                                          ref.read(examRepositoryProvider).submitAnswer(
                                                sessionId: attemptId,
                                                questionId: question.id,
                                                selectedOption: optLabel,
                                              );
                                        }
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

          // ──── Session-preparing overlay ────
          // Blocks answer taps until _startSession() resolves, so a fast
          // tap can't land before there's an attempt id for it to attach
          // to (previously that answer would just be silently dropped).
          if (_attemptId == null && !_isSubmitted)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Preparing your exam...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
              _submitExam();
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
