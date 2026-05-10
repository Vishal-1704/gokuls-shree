import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'marksheet_pdf_generator.dart';
import 'marksheet_service.dart';

// ─────────────────────────────────────────────────────────────
// HOW TO USE — Admin App: Generate & Share Marksheet
// ─────────────────────────────────────────────────────────────

class GenerateMarksheetScreen extends StatefulWidget {
  final String studentRegNo;
  const GenerateMarksheetScreen({super.key, required this.studentRegNo});

  @override
  State<GenerateMarksheetScreen> createState() =>
      _GenerateMarksheetScreenState();
}

class _GenerateMarksheetScreenState extends State<GenerateMarksheetScreen> {
  static const String _dummyRegNo = '9999999999';
  bool _loading = true;
  String? _error;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    try {
      if (widget.studentRegNo == _dummyRegNo) {
        // Generate demo marksheet for testing
        final pdfBytes = await MarksheetPdfGenerator.generateMarksheet(
          StudentMarksheetData(
            enrollNo: _dummyRegNo,
            serialNo: '06/ADCA/GO10011002024/0126',
            studentName: 'Pragya Singh',
            fatherName: 'Pankaj Singh',
            courseName: 'Advance Diploma In Computer Application (ADCA)',
            courseDuration: 'January-2025 To December-2025',
            centre: 'Sanjeet Jaiswal Computer Training Centre',
            centreCode: 'GO10011002024',
            subjects: [
              SubjectMark(
                slNo: 1,
                subject: 'Computer Concept & Fundamentals',
                fullMark: 100,
                markSecured: 78,
              ),
              SubjectMark(
                slNo: 2,
                subject: 'OS ( Dos, Windows)',
                fullMark: 100,
                markSecured: 86,
              ),
              SubjectMark(
                slNo: 3,
                subject: 'Computer English Typing',
                fullMark: 100,
                markSecured: 94,
              ),
              SubjectMark(
                slNo: 4,
                subject: 'MS Office(Word, Adv.Excel, Access, PowerPoint)',
                fullMark: 100,
                markSecured: 88,
              ),
              SubjectMark(
                slNo: 5,
                subject: 'Tally Erp9',
                fullMark: 100,
                markSecured: 78,
              ),
              SubjectMark(
                slNo: 6,
                subject: 'Programming In C',
                fullMark: 100,
                markSecured: 88,
              ),
              SubjectMark(
                slNo: 7,
                subject: 'Page Maker',
                fullMark: 100,
                markSecured: 86,
              ),
              SubjectMark(
                slNo: 8,
                subject: 'Internet Technology & E-Mail',
                fullMark: 100,
                markSecured: 72,
              ),
              SubjectMark(
                slNo: 9,
                subject: 'HTML',
                fullMark: 100,
                markSecured: 84,
              ),
              SubjectMark(
                slNo: 10,
                subject: 'Project & Practical',
                fullMark: 100,
                markSecured: 84,
              ),
            ],
            issueDate: '07-Jan-2026',
          ),
        );

        setState(() {
          _pdfBytes = pdfBytes;
          _loading = false;
        });
        return;
      }

      // For real students: Generate local PDF with their registration number
      final pdfBytes = await MarksheetPdfGenerator.generateMarksheet(
        StudentMarksheetData(
          enrollNo: widget.studentRegNo,
          serialNo: 'ISSUED-${DateTime.now().year}',
          studentName: 'Student Name',
          fatherName: 'Guardian Name',
          courseName: 'Course Name',
          courseDuration: 'Duration',
          centre: 'Training Centre',
          centreCode: 'CENTER-CODE',
          subjects: [
            SubjectMark(
              slNo: 1,
              subject: 'Subject 1',
              fullMark: 100,
              markSecured: 0,
            ),
          ],
          issueDate: _formatDate(DateTime.now().toIso8601String()),
        ),
      );

      setState(() {
        _pdfBytes = pdfBytes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating marksheet: ${e.toString()}';
        _loading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month]}-${dt.year}';
  }

  String _formatDuration(String joinDate, int months) {
    final dt = DateTime.parse(joinDate);
    final end = DateTime(
      dt.year + (dt.month + months - 1) ~/ 12,
      (dt.month + months - 1) % 12 + 1,
    );
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[dt.month]}-${dt.year} To '
        '${monthNames[end.month]}-${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marksheet')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Marksheet')),
      body: PdfPreview(
        build: (_) async => _pdfBytes!,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOW TO USE — Student App: View & Download Own Marksheet
// ─────────────────────────────────────────────────────────────

class StudentMarksheetScreen extends StatefulWidget {
  const StudentMarksheetScreen({super.key});

  @override
  State<StudentMarksheetScreen> createState() => _StudentMarksheetScreenState();
}

class _StudentMarksheetScreenState extends State<StudentMarksheetScreen> {
  static const String _dummyEmail = '9999999999@gokul.local';
  static const String _dummyEmailAlt = '9999999999@gokulshree.local';
  static const String _dummyRegNo = '9999999999';

  String? _resolveRegNo() {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    final isDummyIdentity =
        email == _dummyEmail ||
        email == _dummyEmailAlt ||
        (email != null &&
            email.startsWith('9999999999@') &&
            (email.endsWith('@gokul.local') ||
                email.endsWith('@gokulshree.local')));
    if (isDummyIdentity) {
      return _dummyRegNo;
    }

    final metadata = user?.userMetadata;
    return metadata?['reg_no']?.toString() ??
        metadata?['registration_number']?.toString() ??
        metadata?['registrationNo']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final regNo = _resolveRegNo();
    if (regNo == null || regNo.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Unable to find your registration number.')),
      );
    }

    return GenerateMarksheetScreen(studentRegNo: regNo);
  }
}
