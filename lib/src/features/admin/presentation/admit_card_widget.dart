import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class AdmitCardSubject {
  final int serialNo;
  final String subjectName;
  final String examType; // Theory / Practical / Viva
  final String examDate; // DD-MM-YYYY
  final String examTime; // e.g. 02:00 PM – 03:00 PM
  final int maxMarks;

  const AdmitCardSubject({
    required this.serialNo,
    required this.subjectName,
    required this.examType,
    required this.examDate,
    required this.examTime,
    required this.maxMarks,
  });
}

class AdmitCardData {
  // From admitcard table
  final String cardNo;
  final String rollNo;
  final String examCentreCode;
  final String examCentreAddress;
  final String dateOfIssue;
  final String session;

  // From members table
  final String registrationNo;
  final String studentName;
  final String fatherName;
  final String motherName;
  final String dateOfBirth;
  final String gender;
  final String? photoUrl;

  // From courses + dept + branch
  final String courseName;
  final String centreName;

  // Up to 7 subjects
  final List<AdmitCardSubject> subjects; // max 7

  // Optional
  final String? qrData;

  const AdmitCardData({
    required this.cardNo,
    required this.rollNo,
    required this.examCentreCode,
    required this.examCentreAddress,
    required this.dateOfIssue,
    required this.session,
    required this.registrationNo,
    required this.studentName,
    required this.fatherName,
    required this.motherName,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    required this.courseName,
    required this.centreName,
    required this.subjects,
    this.qrData,
  }) : assert(subjects.length <= 7, 'Maximum 7 subjects allowed on one admit card');
}

// ─────────────────────────────────────────────
// DESIGN TOKENS — Simple, clean, minimal
// ─────────────────────────────────────────────

class _AC {
  // Only 2 dark colors used → everything else is black/white/gray
  static const Color headerDark = Color(0xFF2D2D2D); // near-black for bands
  static const Color bodyBg     = Color(0xFFFFFFFF);
  static const Color altRow     = Color(0xFFF9F9F9);
  static const Color instrBg    = Color(0xFFF5F5F5);
  static const Color border     = Color(0xFFBBBBBB);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textLabel   = Color(0xFF555555);
  static const Color textWhite   = Color(0xFFFFFFFF);
  static const Color textMuted   = Color(0xFF888888);

  // Font sizes (logical px — same meaning as CSS pt for Flutter)
  static const double f7  = 7.0;
  static const double f8  = 8.0;
  static const double f85 = 8.5;
  static const double f9  = 9.0;
  static const double f10 = 10.0;
  static const double f12 = 12.0;
  static const double f13 = 13.0;
  static const double f14 = 14.0;

  // Fixed layout widths
  static const double labelWidth = 110.0; // label column in student section
  static const double photoW     = 80.0;
  static const double photoH     = 100.0;
  static const double qrSize     = 60.0;

  // A4 in logical pixels at 96 dpi → 794 × 1123
  // We use 595 (A4 at 72dpi) scaled up to screen
  static const double cardWidth = 595.0;
}

// ─────────────────────────────────────────────
// ROOT WIDGET
//
// Usage:
//   AdmitCardWidget(data: yourAdmitCardData)
//
// For PDF: use print_it() with the same widget tree
// via flutter/pdf or printing package.
// ─────────────────────────────────────────────

class AdmitCardWidget extends StatelessWidget {
  final AdmitCardData data;

  const AdmitCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: _AC.cardWidth,
          decoration: BoxDecoration(
            color: _AC.bodyBg,
            border: Border.all(color: _AC.headerDark, width: 2.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildTitleBand(),
              _buildReferenceRow(),
              _buildDivider(),
              _buildStudentSection(),
              _buildDivider(),
              _buildExamSchedule(),
              _buildDivider(),
              _buildCentreInfo(),
              _buildDivider(),
              _buildInstructions(),
              _buildDivider(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. HEADER ─────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _AC.border, width: 1),
              color: _AC.instrBg,
            ),
            child: const Icon(Icons.school, size: 26, color: Color(0xFF444444)),
          ),
          const SizedBox(width: 10),
          // Institution name block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'GOKULSHREE SCHOOL OF MANAGEMENT & TECHNOLOGY PVT. LTD.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: _AC.f13,
                    fontWeight: FontWeight.bold,
                    color: _AC.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Shrawasti, Uttar Pradesh – 271831  |  +91-9628281020',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: _AC.f8, color: _AC.textLabel),
                ),
                Text(
                  'www.gokulshreeschool.com',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: _AC.f7, color: _AC.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Accreditation logos placeholder (ISO, MSME)
          Column(
            children: [
              _miniLogo('ISO'),
              const SizedBox(height: 4),
              _miniLogo('MSME'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniLogo(String label) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: _AC.border),
        borderRadius: BorderRadius.circular(3),
        color: _AC.instrBg,
      ),
      child: Center(
        child: Text(label,
            style: const TextStyle(fontSize: 6.0, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── 2. TITLE BAND ─────────────────────────────
  Widget _buildTitleBand() {
    return Container(
      color: _AC.headerDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'EXAMINATION ADMIT CARD',
            style: TextStyle(
              color: _AC.textWhite,
              fontSize: _AC.f12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Academic Session: ${data.session}',
            style: const TextStyle(
                color: _AC.textWhite, fontSize: _AC.f9),
          ),
        ],
      ),
    );
  }

  // ── 3. REFERENCE ROW ──────────────────────────
  Widget _buildReferenceRow() {
    return Container(
      color: _AC.instrBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          _refItem('Admit Card No.', data.cardNo),
          _vDivider(),
          _refItem('Reg. No.', data.registrationNo),
          _vDivider(),
          _refItem('Date of Issue', data.dateOfIssue),
        ],
      ),
    );
  }

  Widget _refItem(String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: _AC.f8, color: _AC.textLabel)),
          Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: _AC.f8,
                    fontWeight: FontWeight.bold,
                    color: _AC.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 14,
      color: _AC.border,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  // ── 4. STUDENT SECTION ────────────────────────
  Widget _buildStudentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Photo + signature
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo box
              Container(
                width: _AC.photoW,
                height: _AC.photoH,
                decoration: BoxDecoration(
                  border: Border.all(color: _AC.textPrimary, width: 1),
                  color: _AC.instrBg,
                ),
                child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                    ? Image.network(
                        data.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
              const SizedBox(height: 10),
              // Signature line
              Container(width: _AC.photoW, height: 1, color: _AC.textPrimary),
              const SizedBox(height: 3),
              const Text('Candidate\'s Signature',
                  style: TextStyle(fontSize: _AC.f7, color: _AC.textLabel)),
            ],
          ),
          const SizedBox(width: 14),
          // RIGHT: Field list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Registration No.', data.registrationNo),
                _field('Roll No.', data.rollNo),
                _field('Student Name', data.studentName.toUpperCase(),
                    bold: true),
                _field("Father's Name", data.fatherName.toUpperCase()),
                _field("Mother's Name", data.motherName.toUpperCase()),
                _field('Date of Birth', data.dateOfBirth),
                _field('Gender', data.gender),
                _field('Course', data.courseName, maxLines: 2),
                _field('Study Centre', data.centreName, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_outline, size: 30, color: Color(0xFFAAAAAA)),
        SizedBox(height: 4),
        Text('PHOTOGRAPH',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 6.5, color: Color(0xFFAAAAAA))),
      ],
    );
  }

  /// A single label: value row — label is FIXED width, value is EXPANDED
  Widget _field(String label, String value,
      {bool bold = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _AC.labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontSize: _AC.f8, color: _AC.textLabel),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _AC.f85,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: _AC.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. EXAM SCHEDULE TABLE ────────────────────
  Widget _buildExamSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          color: _AC.headerDark,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: const Text(
            'EXAMINATION SCHEDULE',
            style: TextStyle(
                color: _AC.textWhite,
                fontSize: _AC.f9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8),
          ),
        ),
        // Table
        Table(
          border: TableBorder.all(color: _AC.border, width: 0.5),
          columnWidths: const {
            0: FixedColumnWidth(28),  // S.No
            1: FlexColumnWidth(2.8),  // Subject
            2: FixedColumnWidth(62),  // Type
            3: FixedColumnWidth(72),  // Date
            4: FixedColumnWidth(110), // Time
            5: FixedColumnWidth(52),  // Marks
          },
          children: [
            // Column headers
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
              children: [
                _th('S.No', center: true),
                _th('Subject / Paper'),
                _th('Type', center: true),
                _th('Date', center: true),
                _th('Time', center: true),
                _th('Marks', center: true),
              ],
            ),
            // Data rows — up to 7
            ...data.subjects.asMap().entries.map((e) {
              final idx = e.key;
              final s = e.value;
              final isAlt = idx % 2 == 1;
              return TableRow(
                decoration: BoxDecoration(
                    color: isAlt ? _AC.altRow : _AC.bodyBg),
                children: [
                  _td('${s.serialNo}', center: true),
                  _td(s.subjectName),
                  _td(s.examType, center: true),
                  _td(s.examDate, center: true),
                  _td(s.examTime, center: true),
                  _td('${s.maxMarks}', center: true),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _th(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
            fontSize: _AC.f8,
            fontWeight: FontWeight.bold,
            color: _AC.textPrimary),
      ),
    );
  }

  Widget _td(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: _AC.f8, color: _AC.textPrimary),
      ),
    );
  }

  // ── 6. CENTRE INFO ────────────────────────────
  Widget _buildCentreInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _centreField('Centre Code', data.examCentreCode),
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 4),
          _centreField('Centre Address', data.examCentreAddress,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _centreField(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: _AC.f8,
                fontWeight: FontWeight.bold,
                color: _AC.textPrimary)),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: _AC.f8, color: _AC.textPrimary),
          ),
        ),
      ],
    );
  }

  // ── 7. INSTRUCTIONS ───────────────────────────
  Widget _buildInstructions() {
    const instructions = [
      'Carry this Admit Card to the examination centre on all examination days.',
      'Bring a valid government-issued Photo ID (Aadhaar / Voter Card / PAN Card).',
      'No mobile phones, electronic devices or calculators are permitted in the exam hall.',
      'Report to the Examination Centre at least 30 minutes before the scheduled time.',
      'This is a computer-generated document and does not require any physical signature.',
    ];

    return Container(
      color: _AC.instrBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IMPORTANT INSTRUCTIONS:',
            style: TextStyle(
                fontSize: _AC.f8,
                fontWeight: FontWeight.bold,
                color: _AC.textPrimary,
                decoration: TextDecoration.underline),
          ),
          const SizedBox(height: 4),
          ...instructions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text('${e.key + 1}.',
                            style: const TextStyle(
                                fontSize: _AC.f8,
                                color: _AC.textPrimary)),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              fontSize: _AC.f8,
                              color: _AC.textPrimary),
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

  // ── 8. FOOTER ─────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: controller signature
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                        width: 140, height: 1, color: _AC.textPrimary),
                    const SizedBox(height: 3),
                    const Text('Controller of Examinations',
                        style: TextStyle(
                            fontSize: _AC.f8,
                            color: _AC.textPrimary)),
                    const Text('Gokulshree School',
                        style: TextStyle(
                            fontSize: _AC.f7,
                            color: _AC.textLabel)),
                  ],
                ),
              ),
              // Right: QR code
              Column(
                children: [
                  Container(
                    width: _AC.qrSize,
                    height: _AC.qrSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: _AC.border),
                      color: _AC.instrBg,
                    ),
                    child: Center(
                      child: data.qrData != null
                          ? _QrPlaceholder(size: _AC.qrSize - 4)
                          : const Icon(Icons.qr_code,
                              size: 36, color: Color(0xFF888888)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text('Scan to Verify',
                      style: TextStyle(
                          fontSize: _AC.f7, color: _AC.textLabel)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: _AC.border),
          const SizedBox(height: 4),
          const Text(
            'This document is computer-generated and is valid without physical signature or official stamp.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: _AC.f7,
                color: _AC.textMuted,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── UTILITY ───────────────────────────────────
  Widget _buildDivider() =>
      Container(height: 1, color: _AC.border);
}

// ── QR placeholder (replace with qr_flutter when available) ──
class _QrPlaceholder extends StatelessWidget {
  final double size;
  const _QrPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QrGridPainter(),
    );
  }
}

class _QrGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    const cells = 8;
    final cell = size.width / cells;
    for (int r = 0; r < cells; r++) {
      for (int c = 0; c < cells; c++) {
        if ((r + c) % 2 == 0 || (r == 0 || r == cells - 1) ||
            (c == 0 || c == cells - 1)) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell - 0.5, cell - 0.5),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
