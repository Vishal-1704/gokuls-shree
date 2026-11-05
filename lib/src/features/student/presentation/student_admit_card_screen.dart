import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admit_card_widget.dart';

class StudentAdmitCardScreen extends ConsumerStatefulWidget {
  const StudentAdmitCardScreen({super.key});

  @override
  ConsumerState<StudentAdmitCardScreen> createState() => _StudentAdmitCardScreenState();
}

class _StudentAdmitCardScreenState extends ConsumerState<StudentAdmitCardScreen> {
  bool _isProcessing = false;

  Future<pw.Document> _buildPdfDocument(AdmitCardData data) async {
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
                      EnvConfig.legalName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'OFFICIAL EXAMINATION ADMIT CARD',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'Session ${data.session}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

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
                  if (data.qrData != null && data.qrData!.isNotEmpty)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: data.qrData!,
                            width: 90,
                            height: 90,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Scan to Verify', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text('Scheduled Examinations:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              // Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
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
                  pw.Text('Controller of Examinations', style: const pw.TextStyle(fontSize: 8.5)),
                  pw.Text('Valid only with Photo Identity Proof', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _printOrSavePdf(AdmitCardData data) async {
    setState(() => _isProcessing = true);
    try {
      final doc = await _buildPdfDocument(data);
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'AdmitCard_${data.registrationNo}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sharePdf(AdmitCardData data) async {
    setState(() => _isProcessing = true);
    try {
      final doc = await _buildPdfDocument(data);
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'AdmitCard_${data.registrationNo}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  void _openFullScreenViewer(BuildContext context, AdmitCardData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: AppColors.inkNavy800,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              'Admit Card Preview',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded, color: AppColors.goldCta),
                tooltip: 'Print / Save PDF',
                onPressed: () => _printOrSavePdf(data),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
                tooltip: 'Share PDF',
                onPressed: () => _sharePdf(data),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AdmitCardWidget(data: data),
                  ),
                ),
              ),
            ),
          ),
        ),
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                          )
                        : const Icon(Icons.print_rounded, color: AppColors.goldCta),
                    tooltip: 'Print / Save PDF',
                    onPressed: _isProcessing ? null : () => _printOrSavePdf(cardData),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary),
                    tooltip: 'Share PDF',
                    onPressed: _isProcessing ? null : () => _sharePdf(cardData),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final upcoming = examsAsync.value ?? [];
            final cardData = _buildAdmitCardData(profile, upcoming);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.green, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verified Hall Ticket',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Session ${cardData.session} • Centre Code: ${cardData.examCentreCode}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Action Buttons (Print/Save PDF & Share)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldCta,
                            foregroundColor: AppColors.inkNavy900,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900),
                                )
                              : const Icon(Icons.print_rounded, size: 18),
                          label: const Text(
                            'Print / Save PDF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isProcessing ? null : () => _printOrSavePdf(cardData),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldCta,
                            side: const BorderSide(color: AppColors.goldCta),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'Share PDF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isProcessing ? null : () => _sharePdf(cardData),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Hall Ticket Details Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Candidate Name', cardData.studentName),
                        const Divider(height: 14, color: AppColors.divider10),
                        _summaryRow('Registration No.', cardData.registrationNo),
                        const Divider(height: 14, color: AppColors.divider10),
                        _summaryRow('Roll Number', cardData.rollNo),
                        const Divider(height: 14, color: AppColors.divider10),
                        _summaryRow('Course', cardData.courseName),
                        const Divider(height: 14, color: AppColors.divider10),
                        _summaryRow('Exam Centre', cardData.centreName),
                        const Divider(height: 14, color: AppColors.divider10),
                        _summaryRow('Scheduled Papers', '${cardData.subjects.length} Subjects'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Header for Document Preview with Zoom prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Document Preview',
                        style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
                      ),
                      InkWell(
                        onTap: () => _openFullScreenViewer(context, cardData),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldCta.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, size: 14, color: AppColors.goldCta),
                              SizedBox(width: 4),
                              Text(
                                'Tap to Zoom',
                                style: TextStyle(color: AppColors.goldCta, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 5. Native Admit Card Preview with interactive tap-to-zoom
                  GestureDetector(
                    onTap: () => _openFullScreenViewer(context, cardData),
                    child: Container(
                      width: double.infinity,
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
                        child: Stack(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: 595,
                                child: AdmitCardWidget(data: cardData),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Fullscreen',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
