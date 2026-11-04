import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admit_card_widget.dart';

class StudentAdmitCardScreen extends ConsumerStatefulWidget {
  const StudentAdmitCardScreen({super.key});

  @override
  ConsumerState<StudentAdmitCardScreen> createState() => _StudentAdmitCardScreenState();
}

class _StudentAdmitCardScreenState extends ConsumerState<StudentAdmitCardScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf(AdmitCardData data) async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GOKUL SHREE INSTITUTE',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'OFFICIAL EXAMINATION ADMIT CARD',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'Session 2025-2026',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Details Grid
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfRow('Candidate Name:', data.studentName),
                          _pdfRow('Registration No:', data.registrationNo),
                          _pdfRow('Roll Number:', data.rollNo),
                          _pdfRow('Course / Program:', data.courseName),
                          _pdfRow('Father\'s Name:', data.fatherName),
                          _pdfRow('Date of Birth:', data.dateOfBirth),
                          _pdfRow('Exam Centre:', data.centreName),
                          _pdfRow('Centre Code:', data.examCentreCode),
                        ],
                      ),
                    ),
                    if (data.qrData != null)
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: data.qrData!,
                              width: 100,
                              height: 100,
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text('Scan to Verify', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text('Scheduled Examinations:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),

                // Table
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  headers: ['#', 'Subject / Paper', 'Type', 'Date', 'Time', 'Max Marks'],
                  data: data.subjects.map((s) => [
                    s.serialNo.toString(),
                    s.subjectName,
                    s.examType,
                    s.examDate,
                    s.examTime,
                    s.maxMarks.toString(),
                  ]).toList(),
                ),

                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Controller of Examinations', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Valid only with Photo Identity Proof', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'AdmitCard_${data.registrationNo}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9.5)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider);
    final examsAsync = ref.watch(upcomingExamsProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: Text(
          'My Admit Card',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) {
              final cardData = _buildAdmitCardData(profile, examsAsync.value ?? []);
              return IconButton(
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.goldCta),
                tooltip: 'Download PDF',
                onPressed: _isExporting ? null : () => _exportPdf(cardData),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final upcoming = examsAsync.value ?? [];
          final cardData = _buildAdmitCardData(profile, upcoming);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quick info & download CTA bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Hall Ticket',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Valid for active session examinations',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldCta,
                          foregroundColor: AppColors.inkNavy900,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _isExporting ? null : () => _exportPdf(cardData),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Native Admit Card Widget
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AdmitCardWidget(data: cardData),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error loading admit card: $e', style: const TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(studentProfileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AdmitCardData _buildAdmitCardData(Map<String, dynamic> profile, List<Map<String, dynamic>> upcomingExams) {
    final regNo = (profile['reg_no'] ?? 'REG-001').toString();
    final name = (profile['name'] ?? 'Candidate').toString();
    final rollNo = (profile['roll_no'] ?? profile['id'] ?? regNo).toString();
    final courseName = (profile['class_section'] ?? profile['program'] ?? 'General Course').toString();
    final branchName = (profile['branches'] as Map?)?['name']?.toString() ?? 'Main Campus Examination Hall';

    final subjects = <AdmitCardSubject>[];

    if (upcomingExams.isNotEmpty) {
      for (int i = 0; i < upcomingExams.length && subjects.length < 7; i++) {
        final exam = upcomingExams[i];
        final paper = (exam['paper_sets'] as Map?) ?? {};
        final title = (exam['title'] ?? paper['name'] ?? 'Paper ${i + 1}').toString();
        final date = exam['start_time'] != null
            ? DateFormat('dd-MM-yyyy').format(DateTime.tryParse(exam['start_time'].toString()) ?? DateTime.now())
            : DateFormat('dd-MM-yyyy').format(DateTime.now().add(Duration(days: (i + 1) * 3)));
        final maxMarks = (paper['total_marks'] as num?)?.toInt() ?? 100;

        subjects.add(
          AdmitCardSubject(
            serialNo: i + 1,
            subjectName: title,
            examType: 'Online Theory',
            examDate: date,
            examTime: '10:00 AM - 12:00 PM',
            maxMarks: maxMarks,
          ),
        );
      }
    }

    // Fallback standard subjects if no upcoming schedule is registered yet
    if (subjects.isEmpty) {
      subjects.addAll([
        AdmitCardSubject(
          serialNo: 1,
          subjectName: '$courseName - Theory Paper I',
          examType: 'Theory',
          examDate: DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 5))),
          examTime: '10:00 AM - 01:00 PM',
          maxMarks: 100,
        ),
        AdmitCardSubject(
          serialNo: 2,
          subjectName: '$courseName - Practical Assessment',
          examType: 'Practical',
          examDate: DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 8))),
          examTime: '02:00 PM - 05:00 PM',
          maxMarks: 100,
        ),
      ]);
    }

    return AdmitCardData(
      cardNo: 'AC-$regNo',
      rollNo: rollNo,
      examCentreCode: 'GSS-101',
      examCentreAddress: 'Gokul Shree Campus, Varanasi, Uttar Pradesh',
      dateOfIssue: DateFormat('dd-MM-yyyy').format(DateTime.now()),
      session: '2025-2026',
      registrationNo: regNo,
      studentName: name,
      fatherName: (profile['father_name'] ?? profile['parent_name'] ?? 'Father / Guardian').toString(),
      motherName: (profile['mother_name'] ?? 'Mother').toString(),
      dateOfBirth: (profile['dob'] ?? profile['date_of_birth'] ?? '01-01-2005').toString(),
      gender: (profile['gender'] ?? 'Not Specified').toString(),
      photoUrl: profile['photo_url']?.toString(),
      courseName: courseName,
      centreName: branchName,
      subjects: subjects.take(7).toList(),
      qrData: 'ADM:$regNo:$name',
    );
  }
}
