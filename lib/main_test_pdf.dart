import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/features/documents/services/marksheet_service.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatefulWidget {
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  String status = 'Generating...';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final service = MarksheetService();
      // Load assets (paths relative to where command is run, usually project root)
      // Note: In a real app, rootBundle works. In this test app, rootBundle works if assets are in pubspec.
      // But passing bytes manually is safer for this test script if we encounter bundle issues.
      // However, MarksheetService now uses rootBundle internally if bytes are null.
      // Let's pass bytes to be sure, reading from filesystem.

      final bgBytes = await File(
        r'C:\Users\mevis\-GM-\backend\assets\documents\marksheet.jpg',
      ).readAsBytes();
      final logoBytes = await File(
        r'C:\Users\mevis\-GM-\assets\images\school_logo.png',
      ).readAsBytes();
      final isoBytes = await File(
        r'C:\Users\mevis\-GM-\assets\images\iso.png',
      ).readAsBytes();
      final msmeBytes = await File(
        r'C:\Users\mevis\-GM-\assets\images\msme.png',
      ).readAsBytes();
      final skillBytes = await File(
        r'C:\Users\mevis\-GM-\assets\images\skill.png',
      ).readAsBytes();

      final pdfBytes = await service.generateMarksheet(
        studentName: 'HTML Test Student',
        regNo: 'HTML-1234',
        courseName: 'ADCA',
        session: '2025-2026',
        marksheetId: 'MS-HTML-001',
        verificationUrl: 'https://gokulshreeschool.com/verify',
        subjects: [
          SubjectResult(name: 'HTML', maxMarks: 100, obtainedMarks: 90),
          SubjectResult(name: 'CSS', maxMarks: 100, obtainedMarks: 85),
          SubjectResult(name: 'JS', maxMarks: 100, obtainedMarks: 88),
        ],
        bgImageBytes: bgBytes,
        logoImageBytes: logoBytes,
        isoImageBytes: isoBytes,
        msmeImageBytes: msmeBytes,
        skillImageBytes: skillBytes,
      );

      final file = File('marksheet_html_output.pdf');
      await file.writeAsBytes(pdfBytes);

      setState(() {
        status = 'Generated: ${file.absolute.path}';
      });

      print('PDF GENERATION SUCCESS: ${file.absolute.path}');

      // Exit after a short delay to allow print to flush
      await Future.delayed(const Duration(seconds: 2));
      exit(0);
    } catch (e, st) {
      setState(() {
        status = 'Error: $e';
      });
      print('PDF GENERATION ERROR: $e');
      print(st);
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text(status))),
    );
  }
}
