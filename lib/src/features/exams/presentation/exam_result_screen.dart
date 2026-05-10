import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'dart:math';

class ExamResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String examTitle;

  const ExamResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.examTitle,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation =
        Tween<double>(
          begin: 0,
          end: widget.totalQuestions > 0
              ? widget.score / widget.totalQuestions
              : 0,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.totalQuestions > 0
        ? (widget.score / widget.totalQuestions) * 100
        : 0.0;
    final isPassed = percentage >= 40;
    final color = isPassed ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Exam Result'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ──── Result Icon ────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                size: 44,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPassed ? 'Congratulations! 🎉' : 'Keep Trying! 💪',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.examTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // ──── Animated Score Ring ────
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                final animPct = _scoreAnimation.value * 100;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CustomPaint(
                              painter: _ScoreRingPainter(
                                progress: _scoreAnimation.value,
                                color: color,
                                bgColor: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${animPct.toInt()}%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              Text(
                                'Score',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Score breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            label: 'Correct',
                            value: '${widget.score}',
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                          _StatItem(
                            label: 'Wrong',
                            value: '${widget.totalQuestions - widget.score}',
                            color: Colors.red,
                            icon: Icons.cancel,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                          _StatItem(
                            label: 'Total',
                            value: '${widget.totalQuestions}',
                            color: Colors.blue,
                            icon: Icons.quiz,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ──── Status Badge ────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPassed ? Icons.verified : Icons.info_outline,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPassed
                        ? 'You passed the exam!'
                        : 'You need 40% to pass. Try again!',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ──── Buttons ────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/student-dashboard'),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'Back to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/exams'),
                icon: const Icon(Icons.list_alt),
                label: const Text(
                  'View All Exams',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SCORE RING PAINTER
// ═══════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════
// STAT ITEM
// ═══════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
