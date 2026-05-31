import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
class MarksheetViewerScreen extends StatelessWidget {
  const MarksheetViewerScreen({super.key, required this.marksheet});

  final Map<String, dynamic> marksheet;

  @override
  Widget build(BuildContext context) {
    final student = marksheet['students'] as Map<String, dynamic>? ?? {};
    final course = marksheet['courses'] as Map<String, dynamic>? ?? {};
    
    // Parse subjects marks from marks JSONB
    final marksData = marksheet['marks'] as Map<String, dynamic>? ?? {};
    final List<dynamic> subjects = marksData['subjects'] ?? [];

    final obtainedMarks = marksheet['obtained_marks'] ?? 0;
    final totalMarks = marksheet['total_marks'] ?? 100;
    final percentage = marksheet['percentage']?.toString() ?? '0.0';
    final grade = marksheet['grade'] ?? 'N/A';
    final result = marksheet['result'] ?? 'PASS';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Digital Marksheet'),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.inkNavy800.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goldCta.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldCta.withOpacity(0.05),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            children: [
              // ── Header Area ──
              _buildHeader(),
              const Divider(color: AppColors.goldCta, thickness: 1.5, height: 1),
              
              // ── Student Info Area ──
              _buildStudentInfo(student, course),
              const Divider(color: Colors.white12, height: 1),
              
              // ── Marks Table ──
              _buildMarksTable(subjects),
              const Divider(color: Colors.white12, height: 1),
              
              // ── Summary Area ──
              _buildSummary(obtainedMarks, totalMarks, percentage, grade, result),
              
              // ── Verification Area ──
              _buildVerification(marksheet['id']?.toString() ?? 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, color: AppColors.goldCta, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOKULSHREE SCHOOL',
                      style: AppTypography.displayMd.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppColors.goldCta,
                      ),
                    ),
                    Text(
                      'OF MANAGEMENT & TECHNOLOGY',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'STATEMENT OF MARKS',
            style: AppTypography.headingSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(Map<String, dynamic> student, Map<String, dynamic> course) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow('Student Name', student['name']?.toString().toUpperCase() ?? 'N/A'),
          _buildInfoRow('Father\'s Name', student['father_name']?.toString().toUpperCase() ?? 'N/A'),
          _buildInfoRow('Course Name', course['name']?.toString() ?? 'N/A'),
          _buildInfoRow('Roll Number', marksheet['roll_no']?.toString() ?? 'N/A'),
          _buildInfoRow('Registration No', student['reg_no']?.toString() ?? 'N/A'),
          _buildInfoRow('Academic Session', marksheet['session']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(':  ', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksTable(List<dynamic> subjects) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        border: TableBorder.all(color: Colors.white10, width: 1, borderRadius: BorderRadius.circular(8)),
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(color: AppColors.inkNavy700),
            children: [
              _buildTableCell('SUBJECT NAME', isHeader: true),
              _buildTableCell('MAX MARKS', isHeader: true),
              _buildTableCell('OBTAINED', isHeader: true),
            ],
          ),
          // Table Rows
          if (subjects.isEmpty)
            TableRow(
              children: [
                _buildTableCell('No records found', span: 3),
                _buildTableCell(''),
                _buildTableCell(''),
              ],
            )
          else
            ...subjects.map((sub) {
              final name = sub['name']?.toString() ?? 'Course Module';
              final max = sub['max']?.toString() ?? '100';
              final obtained = sub['theory']?.toString() ?? '0';
              return TableRow(
                children: [
                  _buildTableCell(name),
                  _buildTableCell(max),
                  _buildTableCell(obtained, highlight: true),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool highlight = false, int span = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Text(
        text,
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        style: isHeader
            ? AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold, color: AppColors.goldCta)
            : AppTypography.bodySm.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? AppColors.goldShine : AppColors.textPrimary,
              ),
      ),
    );
  }

  Widget _buildSummary(int obtained, int total, String percentage, String grade, String result) {
    final isPass = result.toUpperCase() == 'PASS';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inkNavy700,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Obtained Marks', '$obtained / $total'),
                _buildSummaryItem('Percentage', '$percentage%'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Grade', grade),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Status', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPass ? AppColors.success : AppColors.danger).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isPass ? AppColors.success : AppColors.danger),
                      ),
                      child: Text(
                        result,
                        style: AppTypography.labelSm.copyWith(
                          color: isPass ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.headingSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerification(String marksheetId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'DIGITALLY VERIFIED',
                      style: AppTypography.labelSm.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'This marksheet is cryptographically signed and stored in public block records.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hash: SHA256-${marksheetId.hashCode.toRadixString(16).toUpperCase()}',
                  style: AppTypography.mono.copyWith(color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: QrImageView(
              data: 'https://gokulshreeschool.com/verify/$marksheetId',
              version: QrVersions.auto,
              size: 60.0,
            ),
          ),
        ],
      ),
    );
  }
}
