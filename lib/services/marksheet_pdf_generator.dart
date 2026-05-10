import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

// Self-contained SubjectMark class for PDF generation
class SubjectMark {
  final int slNo;
  final String subject;
  final int fullMark;
  final int markSecured;

  SubjectMark({
    required this.slNo,
    required this.subject,
    required this.fullMark,
    required this.markSecured,
  });

  double get percentage => (markSecured / fullMark) * 100;
}

class StudentMarksheetData {
  final String enrollNo;
  final String serialNo;
  final String studentName;
  final String fatherName;
  final String courseName;
  final String courseDuration;
  final String centre;
  final String centreCode;
  final List<SubjectMark> subjects;
  final String issueDate;
  final Uint8List? studentImage; // Optional student photo

  StudentMarksheetData({
    required this.enrollNo,
    required this.serialNo,
    required this.studentName,
    required this.fatherName,
    required this.courseName,
    required this.courseDuration,
    required this.centre,
    required this.centreCode,
    required this.subjects,
    required this.issueDate,
    this.studentImage,
  });

  int get totalMarks => subjects.fold(0, (sum, s) => sum + s.fullMark);
  int get totalSecured => subjects.fold(0, (sum, s) => sum + s.markSecured);
  double get percentage => (totalSecured / totalMarks) * 100;

  String get grade {
    if (percentage >= 85) return 'A+';
    if (percentage >= 75) return 'A';
    if (percentage >= 65) return 'B';
    if (percentage >= 55) return 'C';
    if (percentage >= 50) return 'D';
    return 'FAIL';
  }

  String get result => percentage >= 50 ? 'PASS' : 'FAIL';
}

class MarksheetPdfGenerator {
  static const String schoolName =
      'Gokulshree School Of Management And Technology Private Limited';
  static const String regInfo =
      'Registered Under Companies Act 2013. Corporate Identification Number is (CIN) U80900UP2021PTC154024';
  static const String msmeInfo =
      'MSME Registration: UDYAM-UP-69-0000812. AN ISO 9001:2015 Certified Institute.';
  static const String verifyUrl = 'www.gokulshreeschool.com';
  static const String gradeLegend =
      'GRADE LEGEND :- A+ : 85% and over, A : 75%-84%, B : 65%-74%, C : 55%-64%, D : 50%-54%, Fail less then 50%';

  static Future<Uint8List> generateMarksheet(StudentMarksheetData data) async {
    final pdf = pw.Document();

    // Colors matching the website design
    const PdfColor primaryRed = PdfColor.fromInt(0xffe4322e);
    const PdfColor deepPurple = PdfColor.fromInt(0xff4d0a65);
    const PdfColor darkRed = PdfColor.fromInt(0xff990000);
    const PdfColor brightYellow = PdfColor.fromInt(0xffFFFF33);
    const PdfColor lightTeal = PdfColor.fromInt(0xff147d8a);
    const PdfColor errorRed = PdfColor.fromInt(0xffed2123);
    const PdfColor borderBlue = PdfColor.fromInt(0xff667bb4);
    const PdfColor textDark = PdfColor.fromInt(0xff000000);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              children: [
                // Header with enrollment and serial no
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 12,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Enroll. No.: ${data.enrollNo}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Serial. No.: ${data.serialNo}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // School header section
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo placeholder
                      pw.Container(
                        width: 100,
                        height: 100,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: textDark, width: 1),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'LOGO',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      // School info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              schoolName,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryRed,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              regInfo,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              msmeInfo,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // QR Code, Title and Student Photo
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // QR Code placeholder
                      pw.Container(
                        width: 90,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: textDark, width: 1),
                          color: PdfColors.grey200,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'QR CODE',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 15),
                      // Statement of marks title
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: textDark, width: 2),
                            color: darkRed,
                          ),
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'STATEMENT OF MARKS',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: brightYellow,
                                  height: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Verify This Marksheet\n$verifyUrl',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xffCC0000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 15),
                      // Student photo placeholder
                      pw.Container(
                        width: 90,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: textDark, width: 2),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: PdfColors.grey100,
                        ),
                        child: data.studentImage != null
                            ? pw.Image(
                                pw.MemoryImage(data.studentImage!),
                                fit: pw.BoxFit.cover,
                              )
                            : pw.Center(
                                child: pw.Text(
                                  'PHOTO',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Student Details Section
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Column(
                    children: [
                      _buildDetailRow('Name Of Student', data.studentName),
                      _buildDetailRow('S/O, D/O, W/O', data.fatherName),
                      _buildDetailRow(
                        'With his/her Regd. No.',
                        data.enrollNo,
                        suffix: 'has successfully completed the course',
                      ),
                      _buildDetailRow('', data.courseName, centered: true),
                      _buildDetailRow(
                        'Course Duration',
                        data.courseDuration,
                        centered: true,
                      ),
                      _buildDetailRow(
                        'Centre',
                        '(${data.centreCode}) ${data.centre}',
                        centered: true,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Subjects Table Title
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Center(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: pw.Text(
                        'Subjects & Marks Secured',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 4),

                // Marks Table
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Table(
                    border: pw.TableBorder.all(width: 1, color: textDark),
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'SL.\nNO.',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'SUBJECTS',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'FULL MARK',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'MARK SECURED',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...data.subjects.map(
                        (s) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(
                                s.slNo.toString(),
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(
                                s.subject,
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(
                                s.fullMark.toString(),
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(
                                s.markSecured.toString(),
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Grand total row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'GRAND TOTAL',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              data.totalMarks.toString(),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              data.totalSecured.toString(),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Results section
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultBox(
                        'Percentage of Marks',
                        '${data.percentage.toStringAsFixed(1)}%',
                        lightTeal,
                      ),
                      _buildResultBox('Result', data.result, deepPurple),
                      _buildResultBox('Grade', data.grade, errorRed),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                // Grade legend
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Text(
                    gradeLegend,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Footer with date and signature
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 50),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.SizedBox(height: 40),
                          pw.Text(
                            data.issueDate,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Issue Date',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 60,
                            height: 40,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: textDark,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            'Signature',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDetailRow(
    String label,
    String value, {
    String? suffix,
    bool centered = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty)
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ),
          if (label.isNotEmpty && !centered)
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xff667bb4),
                      width: 1.5,
                    ),
                  ),
                ),
                padding: pw.EdgeInsets.only(left: 60, top: 4),
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (label.isEmpty || centered)
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xff667bb4),
                      width: 1.5,
                    ),
                  ),
                ),
                padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: pw.Text(
                  value,
                  textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (suffix != null && suffix.isNotEmpty)
            pw.SizedBox(
              width: 160,
              child: pw.Padding(
                padding: pw.EdgeInsets.only(left: 10),
                child: pw.Text(
                  suffix,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildResultBox(
    String label,
    String value,
    PdfColor bgColor,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
