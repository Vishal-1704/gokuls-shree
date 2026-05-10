import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────

class MarksheetData {
  final String enrollNo;
  final String serialNo;
  final String studentName;
  final String fatherName;
  final String regNo;
  final String courseName;
  final String courseDuration;
  final String centreCode;
  final String centreName;
  final List<SubjectResult> subjects;
  final String percentage;
  final String grade;
  final String result;
  final String issueDate;
  final Uint8List? studentPhoto; // from Supabase storage
  final Uint8List? backgroundImage; // assets/images/marksheet.jpg
  final Uint8List? logoImage; // assets/images/logo.png

  const MarksheetData({
    required this.enrollNo,
    required this.serialNo,
    required this.studentName,
    required this.fatherName,
    required this.regNo,
    required this.courseName,
    required this.courseDuration,
    required this.centreCode,
    required this.centreName,
    required this.subjects,
    required this.percentage,
    required this.grade,
    required this.result,
    required this.issueDate,
    this.studentPhoto,
    this.backgroundImage,
    this.logoImage,
  });

  int get grandTotal => subjects.fold(0, (s, r) => s + r.maxMarks);
  int get totalSecured => subjects.fold(0, (s, r) => s + r.marksSecured);
}

class SubjectResult {
  final int slNo;
  final String subjectName;
  final int maxMarks;
  final int marksSecured;
  const SubjectResult({
    required this.slNo,
    required this.subjectName,
    required this.maxMarks,
    required this.marksSecured,
  });
}

// ─────────────────────────────────────────────────────────────
// COLOUR CONSTANTS (matching original marksheet exactly)
// ─────────────────────────────────────────────────────────────

class _MC {
  static const red = PdfColor.fromInt(0xFFe4322e);
  static const navy = PdfColor.fromInt(0xFF003366);
  static const darkRed = PdfColor.fromInt(0xFF990000);
  static const yellow = PdfColor.fromInt(0xFFFFFF33);
  static const linkRed = PdfColor.fromInt(0xFFCC0000);
  static const dashed = PdfColor.fromInt(0xFF667bb4);
  static const teal = PdfColor.fromInt(0xFF147d8a);
  static const purple = PdfColor.fromInt(0xFF4d0a65);
  static const brightRed = PdfColor.fromInt(0xFFed2123);
  static const black = PdfColors.black;
  static const white = PdfColors.white;
  static const green = PdfColor.fromInt(0xFF15803d);
  static const lightGreen = PdfColor.fromInt(0xFFf0fff4);
  static const greenBorder = PdfColor.fromInt(0xFF15803d);
  static const greenLine = PdfColor.fromInt(0xFFbbf7d0);
  static const greenDark = PdfColor.fromInt(0xFF14532d);
  static const greenMid = PdfColor.fromInt(0xFF166534);
}

// ─────────────────────────────────────────────────────────────
// MAIN GENERATOR
// ─────────────────────────────────────────────────────────────

class MarksheetService {
  /// Call this from your admin app or student app to get PDF bytes
  static Future<Uint8List> generate(MarksheetData data) async {
    final pdf = pw.Document();

    // Load fonts
    final courierBold = await PdfGoogleFonts.sourceCodeProRegular();
    // Note: for exact match use OCR A Std — embed as asset if you have the TTF
    // final ocrFont = pw.Font.ttf(
    //   (await rootBundle.load('assets/fonts/OCRAStd.ttf')).buffer.asByteData()
    // );

    // Load assets
    final bgImage = data.backgroundImage != null
        ? pw.MemoryImage(data.backgroundImage!)
        : null;
    final logoImage = data.logoImage != null
        ? pw.MemoryImage(data.logoImage!)
        : null;
    final photoImage = data.studentPhoto != null
        ? pw.MemoryImage(data.studentPhoto!)
        : null;

    // Generate SHA hash for hidden metadata
    final shaInput =
        '${data.regNo}|${data.studentName}|'
        '${data.courseName}|${data.totalSecured}|${data.issueDate}'
        '|U80900UP2021PTC154024';
    final sha = _sha256short(shaInput);
    final issueTime = DateFormat('HH:mm:ss').format(DateTime.now());

    // Page size = 1000x1410px at 96dpi → 264.6mm x 373.2mm
    const pageFormat = PdfPageFormat(
      264.6 * PdfPageFormat.mm,
      373.2 * PdfPageFormat.mm,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => _buildPage(
          ctx,
          data,
          bgImage,
          logoImage,
          photoImage,
          courierBold,
          sha,
          issueTime,
        ),
      ),
    );

    return pdf.save();
  }

  // ── PAGE LAYOUT ─────────────────────────────────────────────
  static pw.Widget _buildPage(
    pw.Context ctx,
    MarksheetData data,
    pw.ImageProvider? bgImage,
    pw.ImageProvider? logoImage,
    pw.ImageProvider? photoImage,
    pw.Font monoFont,
    String sha,
    String issueTime,
  ) {
    return pw.Stack(
      children: [
        // ── BACKGROUND ──
        if (bgImage != null)
          pw.Positioned.fill(child: pw.Image(bgImage, fit: pw.BoxFit.fill)),

        // ── CONTENT ON TOP OF BACKGROUND ──
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(45, 40, 45, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. ENROLL + SERIAL ROW
              _enrollRow(data),
              pw.SizedBox(height: 6),

              // 2. LOGO + SCHOOL NAME + HEADER
              _headerRow(data, logoImage),
              pw.SizedBox(height: 8),

              // 3. QR + STATEMENT OF MARKS + PHOTO
              _statementRow(data, photoImage),
              pw.SizedBox(height: 16),

              // 4. STUDENT DETAILS
              _studentDetails(data, monoFont),
              pw.SizedBox(height: 8),

              // 5. MARKS TABLE HEADING
              pw.Center(
                child: pw.Text(
                  'SUBJECTS & MARKS SECURED',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: monoFont,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),

              // 6. MARKS TABLE
              _marksTable(data, monoFont),
              pw.SizedBox(height: 8),

              // 7. RESULT BAR
              _resultBar(data, monoFont),
              pw.SizedBox(height: 6),

              // 8. GRADE LEGEND
              _gradeLegend(monoFont),
              pw.Spacer(),

              // 9. FOOTER
              _footer(data, sha, issueTime),
            ],
          ),
        ),
      ],
    );
  }

  // ── ENROLL / SERIAL ROW ──────────────────────────────────────
  static pw.Widget _enrollRow(MarksheetData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Enroll. No.: ${data.enrollNo}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Serial. No.: ${data.serialNo}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ── LOGO + SCHOOL NAME ──────────────────────────────────────
  static pw.Widget _headerRow(MarksheetData data, pw.ImageProvider? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Image(logo, width: 80, height: 80)
        else
          pw.SizedBox(width: 80, height: 80),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text(
                'Gokulshree School Of Management And Technology Private Limited',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: _MC.red,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Registered Under Companies Act 2013. Corporate Identification Number is (CIN) U80900UP2021PTC154024',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'MSME Regirstration: UDYAM-UP-69-0000812.  AN ISO 9001:2015 Certified Institute.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── QR + STATEMENT + PHOTO ──────────────────────────────────
  static pw.Widget _statementRow(MarksheetData data, pw.ImageProvider? photo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // QR placeholder (replace with real QR using qr_flutter package)
        pw.Container(
          width: 90,
          height: 90,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _MC.black, width: 0.5),
          ),
          child: pw.Center(
            child: pw.Text('QR', style: const pw.TextStyle(fontSize: 9)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: _MC.darkRed,
                  border: pw.Border.all(
                    color: _MC.navy,
                    width: 1.5,
                    style: pw.BorderStyle.dotted,
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'STATEMENT OF MARKS',
                    style: pw.TextStyle(
                      color: _MC.yellow,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Verifiy This Marksheet  www.gokulshreeschool.com',
                style: pw.TextStyle(
                  color: _MC.linkRed,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          width: 85,
          height: 95,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFF006600),
              width: 1,
            ),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: photo != null
              ? pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(photo, fit: pw.BoxFit.cover),
                )
              : pw.Center(
                  child: pw.Text(
                    'Photo',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
        ),
      ],
    );
  }

  // ── DASHED UNDERLINE FIELD ──────────────────────────────────
  static pw.Widget _field(
    String label,
    String value, {
    double labelW = 140,
    pw.Font? mono,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.SizedBox(
              width: labelW,
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.only(left: 20, bottom: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: _MC.dashed,
                      width: 1.5,
                      style: pw.BorderStyle.dashed,
                    ),
                  ),
                ),
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: mono,
                  ),
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ── STUDENT DETAILS BLOCK ───────────────────────────────────
  static pw.Widget _studentDetails(MarksheetData data, pw.Font mono) {
    return pw.Column(
      children: [
        _field(
          'Name Of Student',
          ' Mr./Miss.  ${data.studentName}',
          mono: mono,
        ),
        _field('S/O, D/O, W/O', ' ${data.fatherName}', mono: mono),

        // Regd No row — 3 col
        pw.Column(
          children: [
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    'With his/her Regd. No.',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(
                  width: 160,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: _MC.dashed,
                          width: 1.5,
                          style: pw.BorderStyle.dashed,
                        ),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        ' ${data.regNo} ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: mono,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    ' has successfully completed the course',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
          ],
        ),

        // Course name full width
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: _MC.dashed,
                width: 1.5,
                style: pw.BorderStyle.dashed,
              ),
            ),
          ),
          child: pw.Center(
            child: pw.Text(
              ' ${data.courseName} ',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                font: mono,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),

        _field(
          'Course Duration',
          ' ${data.courseDuration}',
          labelW: 110,
          mono: mono,
        ),
        _field(
          'Centre',
          ' (${data.centreCode}) ${data.centreName}',
          labelW: 50,
          mono: mono,
        ),
      ],
    );
  }

  // ── MARKS TABLE ─────────────────────────────────────────────
  static pw.Widget _marksTable(MarksheetData data, pw.Font mono) {
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(
      fontSize: 10,
      font: mono,
      fontWeight: pw.FontWeight.bold,
    );
    final border = pw.TableBorder.all(color: _MC.black, width: 0.5);

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FixedColumnWidth(30),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
      },
      children: [
        // Header
        pw.TableRow(
          children: [
            _tc('SL.\nNO.', headerStyle, align: pw.TextAlign.center),
            _tc('SUBJECTS', headerStyle, align: pw.TextAlign.center),
            _tc('FULL MARK', headerStyle, align: pw.TextAlign.center),
            _tc('MARK SECURED', headerStyle, align: pw.TextAlign.center),
          ],
        ),
        // Data rows
        ...data.subjects.map(
          (s) => pw.TableRow(
            children: [
              _tc('${s.slNo}', cellStyle, align: pw.TextAlign.center),
              _tc(s.subjectName, cellStyle),
              _tc('${s.maxMarks}', cellStyle, align: pw.TextAlign.center),
              _tc('${s.marksSecured}', cellStyle, align: pw.TextAlign.center),
            ],
          ),
        ),
        // Grand total row
        pw.TableRow(
          children: [
            _tc('', cellStyle),
            _tc('GRAND TOTAL', cellStyle, align: pw.TextAlign.right),
            _tc('${data.grandTotal}', cellStyle, align: pw.TextAlign.center),
            _tc('${data.totalSecured}', cellStyle, align: pw.TextAlign.center),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tc(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  // ── RESULT BAR ──────────────────────────────────────────────
  static pw.Widget _resultBar(MarksheetData data, pw.Font mono) {
    final style = pw.TextStyle(
      color: _MC.white,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      font: mono,
    );
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 38,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            color: _MC.teal,
            child: pw.Text(
              'PERCENTAGE OF MARKS   :   ${data.percentage}',
              style: style,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          flex: 25,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            color: _MC.purple,
            child: pw.Text('RESULT   :   ${data.result}', style: style),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          flex: 22,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            color: _MC.brightRed,
            child: pw.Text('GRADE : ${data.grade}', style: style),
          ),
        ),
      ],
    );
  }

  // ── GRADE LEGEND ────────────────────────────────────────────
  static pw.Widget _gradeLegend(pw.Font mono) {
    return pw.Text(
      'GRADE LEGEND :- A+ : 85% and over, A : 75%-84%, B : 65%-74%, '
      'C : 55%-64%, D : 50%-54%, Fail less then 50%',
      style: pw.TextStyle(
        fontSize: 8,
        font: mono,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  // ── FOOTER ──────────────────────────────────────────────────
  static pw.Widget _footer(MarksheetData data, String sha, String issueTime) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Issue date
        pw.SizedBox(
          width: 90,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                data.issueDate,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Issue Date',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        // ISO badge
        _logoBadge('ISO\n9001\n:2015', 54),
        pw.SizedBox(width: 8),
        _logoBadge('msme', 64),
        pw.SizedBox(width: 8),
        _logoBadge('Skill\nIndia', 54),
        pw.Spacer(),
        // DIGITAL SIGNATURE BLOCK
        _digitalSignature(data, sha, issueTime),
      ],
    );
  }

  static pw.Widget _logoBadge(String text, double w) {
    return pw.Container(
      width: w,
      height: 54,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
        borderRadius: pw.BorderRadius.circular(3),
        color: PdfColors.white,
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _MC.navy,
          ),
        ),
      ),
    );
  }

  // ── DIGITAL SIGNATURE ───────────────────────────────────────
  static pw.Widget _digitalSignature(
    MarksheetData data,
    String sha,
    String issueTime,
  ) {
    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        // Main green box
        pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            color: _MC.lightGreen,
            border: pw.Border.all(color: _MC.greenBorder, width: 1.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          padding: const pw.EdgeInsets.fromLTRB(34, 10, 12, 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'DIGITALLY SIGNED',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _MC.greenDark,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(color: _MC.greenLine, thickness: 0.8, height: 1),
              pw.SizedBox(height: 3),
              pw.Text(
                'Controller of Examinations',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _MC.greenMid,
                ),
              ),
              pw.Text(
                'Gokulshree School of Management\nand Technology Pvt. Ltd.',
                style: const pw.TextStyle(fontSize: 8, color: _MC.greenMid),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(color: _MC.greenLine, thickness: 0.8, height: 1),
              pw.SizedBox(height: 3),
              pw.Text(
                '${data.issueDate}   $issueTime IST',
                style: const pw.TextStyle(fontSize: 8, color: _MC.green),
              ),
            ],
          ),
        ),
        // Green circle with V-tick — overlapping top-left
        pw.Positioned(
          top: -16,
          left: -16,
          child: pw.Container(
            width: 42,
            height: 42,
            decoration: pw.BoxDecoration(
              color: _MC.green,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _MC.white, width: 2.5),
            ),
            child: pw.Center(
              child: pw.CustomPaint(
                size: const PdfPoint(22, 22),
                painter: (canvas, size) {
                  canvas
                    ..setStrokeColor(PdfColors.white)
                    ..setLineWidth(2.8)
                    ..setLineCap(PdfLineCap.round)
                    ..setLineJoin(PdfLineJoin.round)
                    ..moveTo(4, 12)
                    ..lineTo(9, 18)
                    ..lineTo(18, 7)
                    ..strokePath();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── UTILITY: short SHA256-like hash ─────────────────────────
  static String _sha256short(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12).toUpperCase();
  }
}
