import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

class _StudentAdmitCardScreenState extends ConsumerState<StudentAdmitCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<pw.Document> _buildPdfDocument(AdmitCardData data) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load(EnvConfig.logoAssetPath);
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with official logo
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          EnvConfig.legalName.toUpperCase(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL EXAMINATION ADMIT CARD',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'Academic Session ${data.session} • Varanasi, Uttar Pradesh',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Details Grid & QR
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
                            width: 85,
                            height: 85,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Scan to Verify', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'Scheduled Examinations:',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
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
            width: 95,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
          ),
        ],
      ),
    );
  }

  void _openFullScreenViewer(BuildContext context, AdmitCardData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: AppColors.inkNavy800,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              'A4 Hall Ticket Document',
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
          body: InteractiveViewer(
            constrained: false,
            minScale: 0.4,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(40),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 595,
                  child: AdmitCardWidget(data: data),
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
          'Examination Admit Card',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.inkNavy800,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.goldCta,
              indicatorWeight: 3,
              labelColor: AppColors.goldCta,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.badge_rounded, size: 18),
                  text: 'Digital Pass',
                ),
                Tab(
                  icon: Icon(Icons.article_rounded, size: 18),
                  text: 'Official Paper',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final upcoming = examsAsync.value ?? [];
            final cardData = _buildAdmitCardData(profile, upcoming);

            return TabBarView(
              controller: _tabController,
              children: [
                _buildDigitalPassTab(cardData),
                _buildOfficialPaperTab(cardData),
              ],
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

  // ─────────────────────────────────────────────
  // TAB 1: MODERN DIGITAL PASS (Mobile-First UX)
  // ─────────────────────────────────────────────
  Widget _buildDigitalPassTab(AdmitCardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Digital Hall Pass Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2837), Color(0xFF161F2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top institute banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.asset(
                            EnvConfig.logoAssetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 20, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EnvConfig.shortName.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Hall Ticket • Session ${data.session}',
                              style: const TextStyle(
                                color: AppColors.goldCta,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Candidate Details Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      Container(
                        width: 76,
                        height: 94,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider, width: 1),
                          color: AppColors.inkNavy800,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                              ? Image.network(
                                  data.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white54),
                                )
                              : const Icon(Icons.person, size: 40, color: Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.studentName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.courseName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _badgeField('Roll Number', data.rollNo, Icons.numbers_rounded),
                            const SizedBox(height: 4),
                            _badgeField('Registration', data.registrationNo, Icons.badge_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Code Barcode verification row
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (data.qrData != null && data.qrData!.isNotEmpty)
                        QrImageView(
                          data: data.qrData!,
                          version: QrVersions.auto,
                          size: 64,
                          padding: EdgeInsets.zero,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Official Digital Gate Pass',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Present this QR at ${data.centreName} gate for fast attendance scan.',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Action buttons (Print / Save & Share)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: AppColors.inkNavy900,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                  onPressed: _isProcessing ? null : () => _printOrSavePdf(data),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.goldCta,
                    side: const BorderSide(color: AppColors.goldCta),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _isProcessing ? null : () => _sharePdf(data),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Examination Centre Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'EXAMINATION CENTRE',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Code: ${data.examCentreCode}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.centreName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.examCentreAddress,
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
          const SizedBox(height: 20),

          // 4. Scheduled Papers Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Examination Schedule',
                style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldCta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.subjects.length} Papers',
                  style: const TextStyle(
                    color: AppColors.goldCta,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Paper Cards Feed
          ...data.subjects.map((subject) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${subject.serialNo}',
                              style: const TextStyle(
                                color: AppColors.goldCta,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.subjectName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      subject.examType,
                                      style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Max: ${subject.maxMarks} marks',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.divider10),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppColors.goldCta),
                        const SizedBox(width: 6),
                        Text(
                          subject.examDate,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          subject.examTime,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // 5. Exam Day Instructions Checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.goldCta, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Exam Hall Mandatory Checklist',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _checklistRow('Printed copy of this Admit Card (or digital pass if authorized)'),
                _checklistRow('Original Govt. Photo ID proof (Aadhaar / Voter ID / PAN)'),
                _checklistRow('Report at least 30 minutes before scheduled exam start time'),
                _checklistRow('No mobile phones, smartwatches, or electronic devices allowed'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _badgeField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.goldCta),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _checklistRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: OFFICIAL A4 PAPER (Authentic Document)
  // ─────────────────────────────────────────────
  Widget _buildOfficialPaperTab(AdmitCardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner with hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: AppColors.goldCta, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tap document preview to open fullscreen interactive zoom (up to 400%).',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _openFullScreenViewer(context, data),
                  child: const Text('Zoom', style: TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // The formal document preview
          GestureDetector(
            onTap: () => _openFullScreenViewer(context, data),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 595,
                        child: AdmitCardWidget(data: data),
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
                              'Tap to Expand',
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
          const SizedBox(height: 20),

          // Actions
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
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Print Official PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _isProcessing ? null : () => _printOrSavePdf(data),
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
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Fullscreen Zoom', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openFullScreenViewer(context, data),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
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
            examType: 'Theory',
            examDate: date,
            examTime: '10:00 AM - 01:00 PM',
            maxMarks: maxMarks,
          ),
        );
      }
    }

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
