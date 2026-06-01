// lib/src/features/student/presentation/student_id_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/session_provider.dart';

class StudentIdCardScreen extends ConsumerWidget {
  const StudentIdCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('My ID Card', style: TextStyle(color: Colors.white)),
        actions: [
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white70),
              onPressed: () => _downloadCard(context, profile, session),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final regNo = (profile['reg_no'] ?? profile['registration_number'] ?? 'Pending').toString();
          final courseName = (profile['courses']?['title'] ?? profile['course'] ?? 'N/A').toString();
          final validUntil = _formatValidUntil(profile['doj']?.toString());
          final qrPayload = 'STUDENT|$regNo|${profile['id'] ?? ''}|${session?.name ?? ''}';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3A5C), Color(0xFF0A1E35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF5CC45), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5CC45),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1E33),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFFF5CC45), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('GOKUL SHREE', style: TextStyle(color: Color(0xFF0E1E33), fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('School of Mgmt & Technology', style: TextStyle(color: Color(0xFF1A3A5C), fontSize: 9)),
                        ]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 80,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF5CC45), width: 1),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white38, size: 48),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              (session?.name ?? profile['name'] ?? 'Student Name').toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _IdRow('Reg No.', regNo),
                            _IdRow('Course', courseName),
                            _IdRow('Session', _formatSession(profile['doj']?.toString())),
                            _IdRow('Valid', validUntil),
                          ]),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: QrImageView(data: qrPayload, version: QrVersions.auto, size: 84),
                        ),
                        const SizedBox(width: 10),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Scan to verify', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text('gokulshreeschool.com', style: TextStyle(color: Color(0xFFF5CC45), fontSize: 11)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download ID Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5CC45),
                    foregroundColor: const Color(0xFF0E1E33),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _downloadCard(context, profile, session),
                ),
              ]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (error, _) => Center(
          child: Text('Unable to load student profile: $error', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Future<void> _downloadCard(
    BuildContext context,
    Map<String, dynamic> profile,
    UserSession? session,
  ) async {
    try {
      final regNo = (profile['reg_no'] ?? profile['registration_number'] ?? 'Pending').toString();
      final courseName = (profile['courses']?['title'] ?? profile['course'] ?? 'N/A').toString();
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GOKUL SHREE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Name: ${(session?.name ?? profile['name'] ?? 'Student Name').toString()}'),
                pw.Text('Reg No: $regNo'),
                pw.Text('Course: $courseName'),
                pw.Text('Session: ${_formatSession(profile['doj']?.toString())}'),
                pw.Text('Valid: ${_formatValidUntil(profile['doj']?.toString())}'),
              ],
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'id_card_$regNo.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download ID card: $e')),
        );
      }
    }
  }

  String _formatSession(String? doj) {
    if (doj == null || doj.isEmpty) return 'N/A';
    final date = DateTime.tryParse(doj);
    if (date == null) return 'N/A';
    final endYear = date.year + 1;
    return '${date.year}-${endYear.toString().substring(2)}';
  }

  String _formatValidUntil(String? doj) {
    if (doj == null || doj.isEmpty) return 'N/A';
    final date = DateTime.tryParse(doj);
    if (date == null) return 'N/A';
    final end = DateTime(date.year + 1, date.month, date.day);
    return '${_monthName(end.month)} ${end.year}';
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

class _IdRow extends StatelessWidget {
  const _IdRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}
