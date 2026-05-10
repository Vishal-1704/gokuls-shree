import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gokul_shree_app/src/features/documents/services/marksheet_service.dart';
import 'package:gokul_shree_app/src/features/documents/services/certificate_service.dart';

void main() {
  test('Generate Marksheet and Certificate PDFs', () async {
    final marksheetService = MarksheetService();
    final certService = CertificateService();

    // Load assets
    final marksheetBgBytes = await File(
      'C:\\Users\\mevis\\-GM-\\backend\\assets\\documents\\marksheet.jpg',
    ).readAsBytes();
    final certBgBytes = await File(
      'C:\\Users\\mevis\\-GM-\\backend\\assets\\documents\\certificate.jpg',
    ).readAsBytes();

    // Load other assets for MarksheetService (Legacy mode)
    final logoBytes = await File(
      'C:\\Users\\mevis\\-GM-\\assets\\images\\school_logo.png',
    ).readAsBytes();
    final isoBytes = await File(
      'C:\\Users\\mevis\\-GM-\\assets\\images\\iso.png',
    ).readAsBytes();
    final msmeBytes = await File(
      'C:\\Users\\mevis\\-GM-\\assets\\images\\msme.png',
    ).readAsBytes();
    final skillBytes = await File(
      'C:\\Users\\mevis\\-GM-\\assets\\images\\skill.png',
    ).readAsBytes();

    // Logos can be placeholders or reused if needed, but overlay strategy mainly uses the full BG.
    // We'll keep them null if the service handles them optionally or doesn't need them.
    // For now, let's just pass the BGs.

    // Generate Marksheet (Old signature for now, until refactored)
    final marksheetPdfBytes = await marksheetService.generateMarksheet(
      studentName: 'Test Student',
      regNo: 'GS-XXXX-YYYY',
      courseName: 'ADCA',
      session: '2025-2026',
      marksheetId: 'MS-12345',
      verificationUrl: 'https://example.com/verify',
      subjects: [
        SubjectResult(
          name: 'Computer Fundamentals',
          maxMarks: 100,
          obtainedMarks: 85,
        ),
        SubjectResult(
          name: 'Programming in C',
          maxMarks: 100,
          obtainedMarks: 82,
        ),
        SubjectResult(
          name: 'Data Structures',
          maxMarks: 100,
          obtainedMarks: 88,
        ),
      ],
      bgImageBytes: marksheetBgBytes,
      logoImageBytes: logoBytes,
      isoImageBytes: isoBytes,
      msmeImageBytes: msmeBytes,
      skillImageBytes: skillBytes,
    );
    final marksheetFile = File('marksheet_output.pdf');
    await marksheetFile.writeAsBytes(marksheetPdfBytes);
    print('Marksheet generated: ${marksheetFile.path}');

    // Generate Certificate (New Overlay signature)
    final certPdfBytes = await certService.generateCertificate(
      studentName: 'Test Student',
      fatherName: 'Mr. Father Name',
      regNo: 'GS-CERT-2026-001',
      percentage: '85.5',
      grade: 'A',
      centreName: 'Gokulshree Computer Education',
      courseName: 'ADCA',
      duration: '12 Months',
      date: '14-Feb-2026',
      certificateId: 'CERT-001',
      verificationUrl: 'https://example.com/verify',
      bgImageBytes: certBgBytes,
    );
    final certFile = File('certificate_output.pdf');
    await certFile.writeAsBytes(certPdfBytes);
    print('Certificate generated: ${certFile.path}');
  });
}
