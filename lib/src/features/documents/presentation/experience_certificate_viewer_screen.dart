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
    final designation = employee['designation']?.toString() ?? 'Faculty Member';
    final department = employee['department']?.toString() ?? 'Academic Affairs';
    final doj = employee['doj']?.toString() ?? 'N/A';
    final branchName = branch['name']?.toString() ?? 'Main Branch';
    final certId = certificate['id']?.toString() ?? 'N/A';
    final isSigned = certificate['signature_hash'] != null;

    final rawIssue = certificate['issue_date'] ?? DateTime.now().toString();
    final issueDate = DateTime.tryParse(rawIssue.toString());
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final issueDateStr = issueDate != null
        ? '${issueDate.day.toString().padLeft(2, '0')}-${months[issueDate.month - 1]}-${issueDate.year}'
        : '08-Sep-2025';

    final refNo = 'GSMT/EXP/${issueDate?.year ?? 2025}/$certId';

    return DocumentA4Frame(
      appBarTitle: 'Experience Certificate',
      subtitleLine: 'CERTIFICATE OF EXPERIENCE',
      verifyType: 'experience_certificate',
      verifyId: certId,
      isSigned: isSigned,
      pdfFilenamePrefix: 'ExperienceCertificate_${name.replaceAll(' ', '_')}',
      signatoryTitle: 'Director / Authorised Signatory',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Reference Number & Date Row ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Ref No: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DocumentColors.navy)),
                    Text(refNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DocumentColors.text)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Date: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DocumentColors.navy)),
                    Text(issueDateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DocumentColors.text)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── Formal Header ───
          Center(
            child: Column(
              children: [
                const Text(
                  'TO WHOMSOEVER IT MAY CONCERN',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: DocumentColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 220,
                  height: 1.5,
                  color: DocumentColors.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Main Body Paragraph ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.85,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      const TextSpan(text: 'This is to certify that '),
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: DocumentColors.navy,
                          fontSize: 15.0,
                        ),
                      ),
                      const TextSpan(
                        text: ' has been an esteemed employee with ',
                      ),
                      const TextSpan(
                        text: 'Gokulshree School of Management and Technology Private Limited',
                        style: TextStyle(fontWeight: FontWeight.bold, color: DocumentColors.navy),
                      ),
                      const TextSpan(text: ', stationed at our '),
                      TextSpan(
                        text: '$branchName Campus',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: DocumentColors.navy),
                      ),
                      const TextSpan(text: ', serving as '),
                      TextSpan(
                        text: designation,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: DocumentColors.navy),
                      ),
                      const TextSpan(text: ' in the '),
                      TextSpan(
                        text: '$department Department',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: DocumentColors.navy),
                      ),
                      const TextSpan(text: ' since '),
                      TextSpan(
                        text: doj,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: DocumentColors.navy),
                      ),
                      const TextSpan(
                        text: '. During their tenure with our institution, they have demonstrated high professional competence, diligence, and remarkable dedication towards their assigned responsibilities.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Their conduct, moral character, and interpersonal relations with colleagues, students, and administration have been exemplary throughout their service period.',
                  style: TextStyle(
                    fontSize: 14.0,
                    height: 1.7,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'We take this privilege to place on record our sincere appreciation for their valuable contributions and wish them boundless success in all their future professional endeavors.',
                  style: TextStyle(
                    fontSize: 14.0,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Conduct & Status Summary Badge ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Conduct & Character: Exemplary',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
                Text(
                  'Performance Rating: Outstanding (Grade A+)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
