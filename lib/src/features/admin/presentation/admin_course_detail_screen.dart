import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_add_student_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_course_form_screen.dart';

class AdminCourseDetailScreen extends ConsumerStatefulWidget {
  const AdminCourseDetailScreen({
    super.key,
    required this.course,
  });

  final Map<String, dynamic> course;

  @override
  ConsumerState<AdminCourseDetailScreen> createState() => _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends ConsumerState<AdminCourseDetailScreen> {
  late Map<String, dynamic> _course;

  @override
  void initState() {
    super.initState();
    _course = Map<String, dynamic>.from(widget.course);
  }

  static const Map<String, double> kCourseBenchmarkFees = {
    'DCA': 6500.0,
    'ADCA': 12000.0,
    'O-Level': 15000.0,
    'CCC': 3500.0,
    'PGDCA': 18000.0,
    'Tally Prime': 6500.0,
    'Graphic Design': 14000.0,
    'Web Development': 20000.0,
    'Yoga Teacher Training': 16000.0,
    'Fire & Safety Management': 22000.0,
  };

  double _resolveCourseFee(String courseName, dynamic rawFee) {
    if (rawFee != null) {
      final parsed = double.tryParse(rawFee.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    for (final entry in kCourseBenchmarkFees.entries) {
      if (courseName.toUpperCase().contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    return 8500.0;
  }

  String _formatFee(double fee) {
    final intFee = fee.round();
    final str = intFee.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d\d)+$)'),
      (match) => '${match[1]},',
    );
    return '₹$formattedRest,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final isSuperAdmin = role == UserRole.superAdmin;

    final title = (_course['name'] ?? _course['title'] ?? 'Course Curriculum').toString();
    final shortName = (_course['short_name'] ?? _course['code'] ?? _deriveShortCode(title)).toString();
    final category = (_course['category'] ?? 'Computer & Vocational Studies').toString();
    final duration = (_course['duration'] ?? '12 Months').toString();
    final eligibility = (_course['eligibility'] ?? '10th / 12th Pass from recognized board').toString();
    final rawTotal = (_course['total_marks'] as num?)?.toInt() ?? 0;
    final totalMarks = rawTotal > 0 ? rawTotal : 100;
    final rawPass = (_course['pass_marks'] as num?)?.toInt() ?? 0;
    final passMarks = rawPass > 0 ? rawPass : (totalMarks * 0.4).round();
    final rawClasses = (_course['total_classes'] as num?)?.toInt() ?? 0;
    final totalClasses = rawClasses > 0 ? rawClasses : 120;
    final rawFee = _course['fee'];
    final fee = _resolveCourseFee(title, rawFee);

    final curriculum = _resolveCurriculum(_course['syllabus'], title, category);
    final careerRoles = _resolveCareerRoles(_course['career_opportunities'], title, category);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Course Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 24, color: AppColors.primaryIndigo),
              tooltip: 'Edit Course Details',
              onPressed: () async {
                final updated = await Navigator.of(context, rootNavigator: true).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => AdminCourseFormScreen(course: _course),
                  ),
                );
                if (updated != null && mounted) {
                  setState(() => _course = Map<String, dynamic>.from(updated));
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy Syllabus Outline',
            onPressed: () {
              final outline = '$title ($duration)\nFee: ${_formatFee(fee)}\nEligibility: $eligibility\nModules:\n${curriculum.map((m) => '• ${m['title']}: ${m['topics']}').join('\n')}';
              Clipboard.setData(ClipboardData(text: outline));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course outline copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Program Fee',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFee(fee),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Register Student',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldCta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  final courseId = _course['id']?.toString();
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => AdminAddStudentScreen(
                        preselectedCourseId: courseId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. HERO HEADER BANNER (Coursera Style) ──
            _buildHeroBanner(
              title: title,
              shortCode: shortName,
              category: category,
              duration: duration,
              eligibility: eligibility,
            ),
            const SizedBox(height: 16),

            // ── 2. METRICS & SPECIFICATIONS GRID ──
            _buildMetricsGrid(
              fee: _formatFee(fee),
              totalMarks: totalMarks,
              passMarks: passMarks,
              totalClasses: totalClasses,
            ),
            const SizedBox(height: 20),

            // ── 3. ABOUT THIS PROGRAM ──
            _buildAboutCard(
              title: title,
              category: category,
              description: _course['description']?.toString(),
            ),
            const SizedBox(height: 20),

            // ── 4. WHAT YOU WILL LEARN / SYLLABUS BREAKDOWN ──
            _buildSyllabusSection(curriculum),
            const SizedBox(height: 20),

            // ── 5. EXAMINATION & PASSING CRITERIA ──
            _buildExamCriteriaCard(
              totalMarks: totalMarks,
              passMarks: passMarks,
              theoryMarks: (_course['theory_marks'] as num?)?.toInt(),
              practicalMarks: (_course['practical_marks'] as num?)?.toInt(),
              internalMarks: (_course['internal_marks'] as num?)?.toInt(),
            ),
            const SizedBox(height: 20),

            // ── 6. CAREER OPPORTUNITIES ──
            _buildCareerOpportunitiesCard(careerRoles),
            const SizedBox(height: 20),

            // ── 7. OFFICIAL CERTIFICATION BADGE ──
            _buildCertificationCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── HERO BANNER ────────────────────────────────────────────────────────
  Widget _buildHeroBanner({
    required String title,
    required String shortCode,
    required String category,
    required String duration,
    required String eligibility,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldCta.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, size: 14, color: AppColors.goldShine),
                    const SizedBox(width: 5),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.goldShine,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shortCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildHeroMetaItem(Icons.schedule_rounded, duration),
              _buildHeroMetaItem(Icons.badge_outlined, eligibility),
              _buildHeroMetaItem(Icons.verified_rounded, 'Board Accredited'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.goldShine),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── METRICS SPECIFICATIONS GRID ────────────────────────────────────────
  Widget _buildMetricsGrid({
    required String fee,
    required int totalMarks,
    required int passMarks,
    required int totalClasses,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Fee',
            value: fee,
            caption: 'Benchmark Rate',
            icon: Icons.currency_rupee_rounded,
            iconColor: AppColors.emeraldMint,
            bgColor: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Assessment',
            value: '$totalMarks Marks',
            caption: 'Min $passMarks to Pass',
            icon: Icons.assignment_turned_in_outlined,
            iconColor: AppColors.goldCta,
            bgColor: Colors.blue.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── ABOUT PROGRAM ──────────────────────────────────────────────────────
  Widget _buildAboutCard({
    required String title,
    required String category,
    String? description,
  }) {
    final bodyText = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : 'The $title program is meticulously structured for job readiness, vocational mastery, and practical digital literacy. Students acquire comprehensive conceptual foundations, work on live practical lab exercises, and earn an authenticated institution credential recognized across government recruitment and private sector industries.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.goldCta, size: 20),
              SizedBox(width: 8),
              Text(
                'About This Course',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bodyText,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── WHAT YOU WILL LEARN / SYLLABUS ─────────────────────────────────────
  Widget _buildSyllabusSection(List<Map<String, String>> curriculum) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: AppColors.goldCta, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'What You Will Learn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${curriculum.length} Core Modules',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...curriculum.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            final isLast = idx == curriculum.length;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? 'Module $idx',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['topics'] ?? '',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── EXAMINATION & PASSING CRITERIA ─────────────────────────────────────
  Widget _buildExamCriteriaCard({
    required int totalMarks,
    required int passMarks,
    int? theoryMarks,
    int? practicalMarks,
    int? internalMarks,
  }) {
    final effectiveTotal = totalMarks > 0 ? totalMarks : 100;
    final effectivePass = passMarks > 0 ? passMarks : (effectiveTotal * 0.4).round();
    final passPercentage = effectiveTotal > 0 ? ((effectivePass / effectiveTotal) * 100).round() : 40;

    final resolvedTheory = theoryMarks != null && theoryMarks > 0
        ? theoryMarks
        : (effectiveTotal * 0.6).round();
    final resolvedPractical = practicalMarks != null && practicalMarks > 0
        ? practicalMarks
        : (effectiveTotal * 0.3).round();
    final resolvedInternal = internalMarks != null && internalMarks > 0
        ? internalMarks
        : (effectiveTotal - resolvedTheory - resolvedPractical);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.primaryIndigo, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exam Structure & Passing Criteria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFB45309), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Qualifying Standard: Minimum $passPercentage% ($effectivePass out of $effectiveTotal marks) aggregate across theory, lab practical, and internal assessments.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF78350F),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Evaluation components
          _buildExamRow('Theory Written Paper', '$resolvedTheory Marks', 'Objective & Subjective Exam'),
          _buildExamRow('Lab Practical & Project', '$resolvedPractical Marks', 'Hands-on Computer Demonstration'),
          _buildExamRow('Internal & Attendance', '$resolvedInternal Marks', 'Continuous Class Evaluation'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Text(
            'Grading System',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGradeBadge('A+ (85%+)', 'Outstanding', Colors.green),
              _buildGradeBadge('A (70-84%)', 'First Class', Colors.blue),
              _buildGradeBadge('B (55-69%)', 'Second Class', Colors.indigo),
              _buildGradeBadge('C (40-54%)', 'Pass', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamRow(String label, String marks, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              marks,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBadge(String grade, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        '$grade • $label',
        style: TextStyle(
          color: color.shade800,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── CAREER ROLES ───────────────────────────────────────────────────────
  Widget _buildCareerOpportunitiesCard(List<String> roles) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work_outline_rounded, color: AppColors.goldCta, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Career & Employment Opportunities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles.map((role) {
              return Chip(
                avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                label: Text(role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── CERTIFICATION AWARDED ──────────────────────────────────────────────
  Widget _buildCertificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            Colors.blue.shade50.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.goldDeep,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Certificate of Completion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Awarded upon clearing final examinations with unique verification QR code and registry enrollment.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DYNAMIC RESOLVERS ──────────────────────────────────────────────────
  static List<Map<String, String>> _resolveCurriculum(
    dynamic rawSyllabus,
    String name,
    String category,
  ) {
    if (rawSyllabus != null) {
      List<dynamic> items = [];
      if (rawSyllabus is List) {
        items = rawSyllabus;
      } else if (rawSyllabus is String && rawSyllabus.trim().startsWith('[')) {
        try {
          items = jsonDecode(rawSyllabus) as List;
        } catch (_) {}
      }

      if (items.isNotEmpty) {
        final parsed = <Map<String, String>>[];
        for (final it in items) {
          if (it is Map) {
            final t = (it['title'] ?? '').toString().trim();
            final top = (it['topics'] ?? '').toString().trim();
            if (t.isNotEmpty || top.isNotEmpty) {
              parsed.add({'title': t, 'topics': top});
            }
          }
        }
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return _getCurriculum(name, category);
  }

  static List<String> _resolveCareerRoles(
    dynamic rawRoles,
    String name,
    String category,
  ) {
    if (rawRoles != null) {
      List<dynamic> items = [];
      if (rawRoles is List) {
        items = rawRoles;
      } else if (rawRoles is String) {
        final str = rawRoles.trim();
        if (str.startsWith('[')) {
          try {
            items = jsonDecode(str) as List;
          } catch (_) {}
        } else {
          items = str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }

      if (items.isNotEmpty) {
        final list = items.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        if (list.isNotEmpty) return list;
      }
    }
    return _getCareerRoles(name, category);
  }

  // ── SYLLABUS MAPPERS ───────────────────────────────────────────────────
  static List<Map<String, String>> _getCurriculum(String name, String category) {
    final lower = '$name $category'.toLowerCase();

    if (lower.contains('adca') || lower.contains('advanced diploma')) {
      return [
        {
          'title': 'Computer Fundamentals & OS',
          'topics': 'Computer Architecture, Windows OS, File Systems, System Maintenance, Control Panel, Peripheral Setup'
        },
        {
          'title': 'MS Office Productivity Suite',
          'topics': 'MS Word (Document Formatting & Mail Merge), Advanced Excel (VLOOKUP, Pivot, Formulas), PowerPoint, Access DB'
        },
        {
          'title': 'Financial Accounting with Tally Prime & GST',
          'topics': 'Ledger Creation, Voucher Entry, Inventory Management, GST Calculation, Profit & Loss, Balance Sheet'
        },
        {
          'title': 'Web Designing Fundamentals & DTP',
          'topics': 'HTML5, CSS Basics, Photoshop image editing, CorelDraw banner layout, Publishing & Printing concepts'
        },
        {
          'title': 'Internet, Cyber Security & Capstone Lab',
          'topics': 'Networking concepts, Safe browsing, Digital Payments, Cloud Storage, Practical Viva & Lab Project'
        },
      ];
    }

    if (lower.contains('dca') || lower.contains('computer application')) {
      return [
        {
          'title': 'Computer Basics & Windows Environment',
          'topics': 'Hardware components, Memory types, Input/Output devices, File Explorer management, Operating system tools'
        },
        {
          'title': 'Word Processing (MS Word)',
          'topics': 'Document creation, Paragraph styling, Tables, Mail merge, Page layouts, Document review tools'
        },
        {
          'title': 'Electronic Spreadsheets (MS Excel)',
          'topics': 'Formulas (SUM, IF, COUNTIF), Data sorting, Charts, Conditional formatting, Printing worksheets'
        },
        {
          'title': 'Digital Presentations & Databases',
          'topics': 'MS PowerPoint animation slides, Slide transitions, MS Access simple database tables and queries'
        },
        {
          'title': 'Internet Technologies & Lab Exam',
          'topics': 'Email communication, Web portals, Government services online, Final Lab Practical Exam & Viva'
        },
      ];
    }

    if (lower.contains('tally') || lower.contains('accounting')) {
      return [
        {
          'title': 'Basics of Accounting & Principles',
          'topics': 'Golden rules of accounting, Double entry system, Journal entries, Ledger accounts, Trial Balance'
        },
        {
          'title': 'Company Creation in Tally Prime',
          'topics': 'Company setup, Group creation, Ledger creation, Accounting vouchers, Contra, Payment, Receipt'
        },
        {
          'title': 'Inventory Management & Order Processing',
          'topics': 'Stock items, Stock groups, Units of measure, Purchase order, Sales order, Delivery notes'
        },
        {
          'title': 'Goods & Services Tax (GST) Implementation',
          'topics': 'CGST, SGST, IGST configuration, HSN/SAC codes, Invoicing, E-Way bills, GSTR-1 & GSTR-3B generation'
        },
        {
          'title': 'Financial Reporting & Payroll Basics',
          'topics': 'Bank Reconciliation (BRS), Profit & Loss statement, Balance Sheet audit, Practical Project Exam'
        },
      ];
    }

    if (lower.contains('o-level') || lower.contains('programming') || lower.contains('python')) {
      return [
        {
          'title': 'Information Technology Tools & Network Basics',
          'topics': 'Computer systems, GUI operating systems, Word processing, Spreadsheets, Presentation & Cyber safety'
        },
        {
          'title': 'Web Designing & Publishing',
          'topics': 'HTML5 elements, CSS styling, CSS Frameworks, JavaScript interactivity, Photo editing for web'
        },
        {
          'title': 'Programming with Python',
          'topics': 'Algorithms, Flowcharts, Data types, Control structures, Functions, Modules, File handling, NumPy basics'
        },
        {
          'title': 'Internet of Things (IoT) & Applications',
          'topics': 'IoT ecosystem, Sensors & Actuators, Microcontrollers (Arduino), Security & Smart systems'
        },
        {
          'title': 'Project Work & Practical Examination',
          'topics': 'Hands-on programming assignments, Lab practical execution, Viva voce & Project evaluation'
        },
      ];
    }

    if (lower.contains('yoga')) {
      return [
        {
          'title': 'Foundations of Yogic Science & Philosophy',
          'topics': 'History of Yoga, Ashtanga Yoga principles, Patanjali Yoga Sutras, Yama & Niyama'
        },
        {
          'title': 'Human Anatomy & Physiology in Yoga',
          'topics': 'Musculoskeletal system, Respiratory system, Nervous system, Chakra system, Stress physiology'
        },
        {
          'title': 'Asanas, Pranayama & Kriyas Practicum',
          'topics': 'Standing, Sitting, Supine & Inversion asanas, Nadi Shodhana, Kapalabhati, Shatkarmas'
        },
        {
          'title': 'Meditation, Diet & Yogic Lifestyle',
          'topics': 'Mindfulness, Yoga Nidra, Sattvic diet, Therapeutic applications of yoga for common ailments'
        },
        {
          'title': 'Teaching Methodology & Internship',
          'topics': 'Class sequencing, Hands-on alignment corrections, Demonstration skills, Final Practical Teaching Exam'
        },
      ];
    }

    if (lower.contains('fire') || lower.contains('safety')) {
      return [
        {
          'title': 'Fire Science & Chemistry of Combustion',
          'topics': 'Classification of fires, Heat transfer mechanisms, Fire triangle, Extinguishing agents & principles'
        },
        {
          'title': 'Fire Protection Systems & Equipment',
          'topics': 'Fire extinguishers, Hydrant systems, Sprinkler networks, Fire alarms, Smoke detectors, Breathing apparatus'
        },
        {
          'title': 'Industrial Safety & Hazard Management',
          'topics': 'Risk assessment, Hazard identification (HAZOP), Personal Protective Equipment (PPE), Factory Act rules'
        },
        {
          'title': 'Emergency Response & First Aid Procedures',
          'topics': 'Evacuation planning, CPR techniques, Chemical spill response, Disaster management protocols'
        },
        {
          'title': 'Field Drills & Practical Demonstration',
          'topics': 'Live hose drill, Fire tender operation, Rescue drills, Practical Field Assessment & Viva'
        },
      ];
    }

    // Default Vocational Course Curriculum
    return [
      {
        'title': 'Core Industry Concepts & Foundations',
        'topics': 'Fundamental principles, Terminology, Standard operating procedures, Professional safety & compliance'
      },
      {
        'title': 'Essential Tools & Technical Workflows',
        'topics': 'Hands-on equipment training, Digital software modules, Practical workflow execution, Quality standards'
      },
      {
        'title': 'Advanced Applied Methodologies',
        'topics': 'Specialized problem solving, Complex real-world scenarios, Case study examination, Industry practices'
      },
      {
        'title': 'Practical Lab & Field Projects',
        'topics': 'Capstone project delivery, Hands-on demonstration, Supervisor reviews, Portfolio development'
      },
      {
        'title': 'Comprehensive Assessment & Certification',
        'topics': 'Theory evaluation paper, Practical skill test, Viva voce examination & Certificate clearance'
      },
    ];
  }

  static List<String> _getCareerRoles(String name, String category) {
    final lower = '$name $category'.toLowerCase();
    if (lower.contains('tally') || lower.contains('accounting')) {
      return [
        'Junior Accountant',
        'Tally Operator',
        'GST Billing Executive',
        'Accounts Assistant',
        'Audit Clerk',
      ];
    }
    if (lower.contains('yoga')) {
      return [
        'Certified Yoga Instructor',
        'Wellness Coach',
        'School Yoga Teacher',
        'Fitness Centre Trainer',
        'Personal Yoga Consultant',
      ];
    }
    if (lower.contains('fire') || lower.contains('safety')) {
      return [
        'Safety Officer',
        'Fire Marshal',
        'HSE Inspector',
        'Industrial Safety Supervisor',
        'Emergency Response Team Member',
      ];
    }
    if (lower.contains('programming') || lower.contains('web')) {
      return [
        'Junior Web Developer',
        'Frontend Designer',
        'Python Programmer',
        'Technical Support Engineer',
        'Freelance Web Specialist',
      ];
    }
    return [
      'Data Entry Executive',
      'Office Computer Assistant',
      'Computer Lab Instructor',
      'Administrative Support Staff',
      'Front Desk Coordinator',
      'Digital Documentation Specialist',
    ];
  }

  static String _deriveShortCode(String title) {
    final parts = title.split(' ');
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 3 ? 3 : parts[0].length).toUpperCase();
    return parts.take(3).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }
}
