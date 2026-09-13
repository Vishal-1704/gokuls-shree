import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/widgets/document_a4_frame.dart';

class ExperienceCertificateViewerScreen extends StatelessWidget {
  const ExperienceCertificateViewerScreen({super.key, required this.certificate});

  final Map<String, dynamic> certificate;

  @override
  Widget build(BuildContext context) {
    final employee = certificate['employees'] as Map<String, dynamic>? ?? {};
    final branch = employee['branches'] as Map<String, dynamic>? ?? {};

    final name = (employee['name'] ?? 'N/A').toString().toUpperCase();
    final designation = employee['designation']?.toString() ?? 'N/A';
    final department = employee['department']?.toString() ?? 'N/A';
    final doj = employee['doj']?.toString() ?? 'N/A';
    final branchName = branch['name']?.toString() ?? 'N/A';
    final certId = certificate['id']?.toString() ?? 'N/A';
    final isSigned = certificate['signature_hash'] != null;

    final issueDate = DateTime.tryParse(certificate['issue_date']?.toString() ?? '');
    final issueDateStr = issueDate != null
        ? '${issueDate.day.toString().padLeft(2, '0')}/${issueDate.month.toString().padLeft(2, '0')}/${issueDate.year}'
        : 'N/A';

    return DocumentA4Frame(
      appBarTitle: 'Experience Certificate',
      subtitleLine: 'EXPERIENCE CERTIFICATE',
      verifyType: 'experience_certificate',
      verifyId: certId,
      isSigned: isSigned,
      pdfFilenamePrefix: 'ExperienceCertificate',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          documentInfoRow('Certificate No', certId),
          documentInfoRow('Issue Date', issueDateStr),
          const SizedBox(height: 16),
          Text(
            'TO WHOMSOEVER IT MAY CONCERN',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: DocumentColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 15, height: 1.7, color: DocumentColors.text),
              children: [
                const TextSpan(text: 'This is to certify that '),
                TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' has been employed with Gokulshree School of Management and Technology Private Limited, '),
                TextSpan(text: branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' branch, as '),
                TextSpan(text: designation, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' in the '),
                TextSpan(text: department, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' department since '),
                TextSpan(text: doj, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '. During this period, we found their conduct and performance to be satisfactory.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We wish them success in all future endeavors.',
            style: TextStyle(fontSize: 15, color: DocumentColors.text),
          ),
        ],
      ),
    );
  }
}
