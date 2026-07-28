// lib/services/document_service.dart
// PDF generation service — Dart port of document.service.js using the 'pdf' package.
// Pixel coordinate tuning is deferred (user confirmed).

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DocumentService {
  static final String _assetsDir = 'assets/documents';
  static final String _signingAuthority =
      'Gokulshree School Of Management And Technology Private Limited';
  static final String _verifyBase =
      String.fromEnvironment('VERIFICATION_URL', defaultValue: 'https://gokulshreeschool.com/verify');

  static String _generateDocId(String type, String regNo) {
    final prefix = type == 'marksheet' ? 'MS' : 'CT';
    final ts     = DateTime.now().millisecondsSinceEpoch;
    // Simple hash-like suffix using regNo + timestamp
    final hash   = (regNo + ts.toString()).hashCode.abs().toRadixString(16).substring(0, 8).toUpperCase();
    return '$prefix-$hash';
  }

  /// Main entry point — generates PDF based on regno + type (marksheet|certificate).
  static Future<Uint8List> generatePdf({
    required String regno,
    required String type,
  }) async {
    // In production, fetch student data from DB here.
    // For now, create a placeholder PDF so the endpoint works.
    // TODO: wire up real Supabase query to fetch student + marksheet data.
    final studentData = <String, dynamic>{
      'regNo': regno,
      'name': 'Student Name',
      'fatherName': 'Father Name',
      'courseName': 'Course Name',
      'rollNo': 'ROLL001',
      'session': '2024-25',
      'subjects': <Map<String, dynamic>>[],
      'totalMarks': 0,
      'obtainedMarks': 0,
      'percentage': '0.00',
      'grade': 'N/A',
      'result': 'PASS',
    };

    if (type == 'marksheet') {
      return _generateMarksheet(studentData);
    } else if (type == 'certificate') {
      return _generateCertificate(studentData);
    } else if (type == 'experience_certificate') {
      // In production, fetch employee data from DB.
      final empData = {
        'name': 'Employee Name',
        'designation': 'Senior Faculty',
        'doj': '2022-01-01',
        'issueDate': DateTime.now().toUtc().toIso8601String().substring(0, 10),
      };
      return _generateExperienceCertificate(empData);
    } else {
      throw Exception('Unknown document type: $type');
    }
  }

  static Future<Uint8List> _generateMarksheet(Map<String, dynamic> data) async {
    final doc  = pw.Document();
    final docId = _generateDocId('marksheet', data['regNo'] as String);

    // Load assets if they exist
    pw.MemoryImage? bgImage;
    pw.MemoryImage? logoImage;
    final bgPath   = File('$_assetsDir/marksheet.jpg');
    final logoPath = File('$_assetsDir/school_logo.png');
    if (bgPath.existsSync())   bgImage   = pw.MemoryImage(bgPath.readAsBytesSync());
    if (logoPath.existsSync()) logoImage = pw.MemoryImage(logoPath.readAsBytesSync());

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return pw.Stack(children: [
          // Background image (if loaded)
          if (bgImage != null)
            pw.Positioned.fill(child: pw.Image(bgImage, fit: pw.BoxFit.fill)),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(children: [
                if (logoImage != null)
                  pw.Image(logoImage, width: 65, height: 65),
                pw.SizedBox(width: 10),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    'Gokulshree School Of Management And Technology',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700),
                  ),
                  pw.Text('Private Limited',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700)),
                  pw.Text('Registered Under Companies Act 2013. CIN: U80900UP2021PTC154024',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                  pw.Text('MSME: UDYAM-UP-69-0000812. ISO 9001:2015 Certified.',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                ]),
              ]),
              pw.Divider(),

              // Banner
              pw.Container(
                color: PdfColor.fromHex('#800000'),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Center(
                  child: pw.Text('STATEMENT OF MARKS',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                          color: PdfColors.yellow)),
                ),
              ),
              pw.SizedBox(height: 8),

              // Student details
              pw.Text('Enroll. No.: ${data['regNo']}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Serial. No.: $docId',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _detailRow('Student Name:', data['name'] as String),
              _detailRow("Father's Name:", data['fatherName'] as String? ?? 'N/A'),
              _detailRow('Course Name:', data['courseName'] as String? ?? ''),
              pw.Row(children: [
                pw.Expanded(child: _detailRow('Roll No.:', data['rollNo'] as String? ?? '')),
                pw.Expanded(child: _detailRow('Exam Session:', data['session'] as String? ?? 'N/A')),
              ]),
              pw.SizedBox(height: 10),

              // Subjects table
              _buildSubjectsTable(data['subjects'] as List? ?? []),

              pw.SizedBox(height: 8),

              // Result summary
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total: ${data['totalMarks']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Obtained: ${data['obtainedMarks']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Percentage: ${data['percentage']}%',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Grade: ${data['grade']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Result: ${data['result']}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: data['result'] == 'PASS' ? PdfColors.green800 : PdfColors.red700,
                    )),
              ]),

              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.Text('Branch Head Signature'),
                ]),
                pw.Column(children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.Text('Authorized Signatory'),
                ]),
              ]),

              pw.SizedBox(height: 8),
              pw.Text('Verify at: www.gokulshreeschool.com | Doc ID: $docId',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        ]);
      },
    ));

    return doc.save();
  }

  static Future<Uint8List> _generateCertificate(Map<String, dynamic> data) async {
    final doc   = pw.Document();
    final docId = _generateDocId('certificate', data['regNo'] as String);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context ctx) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('CERTIFICATE OF COMPLETION',
                  style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700)),
              pw.SizedBox(height: 20),
              pw.Text('This is to certify that',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
              pw.SizedBox(height: 12),
              pw.Text(data['name'] as String,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('has successfully completed the course',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
              pw.SizedBox(height: 8),
              pw.Text(data['courseName'] as String? ?? '',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Session: ${data['session']}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 40),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.Text('Branch Head'),
                ]),
                pw.Column(children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.Text('Director'),
                ]),
              ]),
              pw.SizedBox(height: 10),
              pw.Text('Certificate No: $docId | Verify at: www.gokulshreeschool.com',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        );
      },
    ));

    return doc.save();
  }

  static Future<Uint8List> _generateExperienceCertificate(Map<String, dynamic> data) async {
    final doc   = pw.Document();
    final docId = 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('EXPERIENCE CERTIFICATE',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Date: ${data['issueDate']}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Certificate No: $docId', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 40),
              pw.Text('TO WHOMSOEVER IT MAY CONCERN',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text: 'This is to certify that ${data['name']} has been employed with Gokulshree School Of Management And Technology as a ${data['designation']} since ${data['doj']}.',
                style: const pw.TextStyle(fontSize: 14, lineSpacing: 2),
              ),
              pw.Paragraph(
                text: 'During their tenure, we found them to be highly professional, dedicated, and a valuable asset to our institution. They have consistently demonstrated a strong commitment to their duties.',
                style: const pw.TextStyle(fontSize: 14, lineSpacing: 2),
              ),
              pw.Paragraph(
                text: 'We wish them all the best in their future endeavors.',
                style: const pw.TextStyle(fontSize: 14, lineSpacing: 2),
              ),
              pw.SizedBox(height: 60),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Gokulshree School', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ]),
              ]),
            ],
          ),
        );
      },
    ));

    return doc.save();
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Expanded(child: pw.Text(value)),
      ]),
    );
  }

  static pw.Widget _buildSubjectsTable(List subjects) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('Subject / Paper Name', bold: true),
            _cell('Max Marks', bold: true),
            _cell('Min Marks', bold: true),
            _cell('Obtained', bold: true),
          ],
        ),
        ...List.generate(subjects.isNotEmpty ? subjects.length : 5, (i) {
          if (i < subjects.length) {
            final s = subjects[i] as Map<String, dynamic>;
            return pw.TableRow(children: [
              _cell(s['name'] as String? ?? ''),
              _cell(s['max_marks']?.toString() ?? '100'),
              _cell(s['min_marks']?.toString() ?? '33'),
              _cell(s['obtained']?.toString() ?? ''),
            ]);
          }
          return pw.TableRow(children: [_cell(''), _cell(''), _cell(''), _cell('')]);
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
    );
  }
}
