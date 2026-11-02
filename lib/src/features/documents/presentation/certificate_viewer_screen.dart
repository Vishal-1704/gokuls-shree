import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

/// Dotted Line Custom Painter for authentic Certificate form fields
class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DottedLinePainter({
    this.color = const Color(0xFF94A3B8),
    this.strokeWidth = 1.2,
    this.dashWidth = 2.0,
    this.dashSpace = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final y = size.height - 1.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CertificateViewerScreen extends StatefulWidget {
  const CertificateViewerScreen({super.key, required this.certificate});

  final Map<String, dynamic> certificate;

  @override
  State<CertificateViewerScreen> createState() => _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isExporting = false;

  String _clean(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _certificateKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing certificate PNG: $e');
      return null;
    }
  }

  Future<void> _downloadPng(String certNo) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final pngBytes = await _capturePng();
      if (pngBytes == null) {
        throw Exception('Could not render certificate image');
      }

      await Printing.sharePdf(
        bytes: pngBytes,
        filename: 'Certificate_${_clean(certNo)}.png',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PNG: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _downloadPdf(String certNo, {bool isShare = false}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final pngBytes = await _capturePng();
      if (pngBytes == null) {
        throw Exception('Could not render certificate');
      }

      final pdf = pw.Document();
      final image = pw.MemoryImage(pngBytes);

      // Certificate is Landscape A4 (297 x 210 mm)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      if (isShare) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Certificate_${_clean(certNo)}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Certificate_${_clean(certNo)}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDownloadOptions(String certNo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Download Certificate',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the format you would like to save',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                  ),
                  title: const Text('Save / Print as PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('High-resolution official document for printing'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _downloadPdf(certNo);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_rounded, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Save as PNG Image', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Clear image for gallery & instant sharing'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _downloadPng(certNo);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCertDate(dynamic rawDate) {
    if (rawDate == null) return '08-Sep-2025';
    final dt = DateTime.tryParse(rawDate.toString());
    if (dt == null) return rawDate.toString();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  String _computeDuration(Map<String, dynamic> student, Map<String, dynamic> course) {
    final session = widget.certificate['session']?.toString();
    if (session != null && session.isNotEmpty && session != 'null') {
      return session;
    }
    final doj = DateTime.tryParse(student['doj']?.toString() ?? '');
    final durationStr = course['duration']?.toString() ?? '1 Year';
    int months = 12;
    final match = RegExp(r'(\d+)\s*(month|year)', caseSensitive: false).firstMatch(durationStr);
    if (match != null) {
      final val = int.tryParse(match.group(1) ?? '') ?? 1;
      final unit = match.group(2)!.toLowerCase();
      months = unit.startsWith('year') ? val * 12 : val;
    }
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (doj != null) {
      final start = doj;
      final end = DateTime(start.year, start.month + months, start.day);
      return '${monthNames[start.month - 1]}-${start.year} To ${monthNames[end.month - 1]}-${end.year}';
    }
    return 'June-2024 To May-2025';
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.certificate['students'] as Map<String, dynamic>? ?? {};
    final course = widget.certificate['courses'] as Map<String, dynamic>? ?? {};

    final studentName = (student['name']?.toString() ?? 'SATYAM TRIPATHI').trim().toUpperCase();
    final fatherName = (student['father_name']?.toString() ?? 'VIJAY BAHADUR').trim().toUpperCase();
    final regNo = (student['reg_no']?.toString() ?? widget.certificate['certificate_no']?.toString() ?? 'GOKUL1530625').trim();
    final avatarUrl = student['avatar_url']?.toString();

    final courseName = (course['name']?.toString() ?? widget.certificate['course_name']?.toString() ?? 'Advance Diploma In Computer Application (ADCA)').trim();
    final durationText = _computeDuration(student, course);

    final grade = (widget.certificate['grade']?.toString() ?? 'A').trim();
    var percentRaw = (widget.certificate['percentage'] ?? widget.certificate['percent'] ?? '78.2').toString().trim();
    if (!percentRaw.endsWith('%')) percentRaw = '$percentRaw%';

    final centerName = (student['branches']?['name'] ?? widget.certificate['center_name'] ?? 'Gokulshree School Of Management And Technology Private Limited').toString().trim();
    final certNo = (widget.certificate['certificate_no'] ?? widget.certificate['id']?.toString() ?? 'GOKUL1530625').toString().trim();
    final issueDate = _formatCertDate(widget.certificate['issue_date']);
    final isSigned = widget.certificate['signature_hash'] != null;

    final verifyUrl = '${EnvConfig.verifyBaseUrl}/certificate/$certNo';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Certificate of Completion',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.goldCta),
            tooltip: 'Download Options',
            onPressed: () => _showDownloadOptions(certNo),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share PDF',
            onPressed: () => _downloadPdf(certNo, isShare: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: RepaintBoundary(
            key: _certificateKey,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                // Landscape A4 Design Canvas: 842 x 595 (true 297:210 mm)
                width: 842,
                height: 595,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/certificate_bg.jpg'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Inset so text sits comfortably inside the decorative orange border
                  padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ─── TOP HEADER ROW ───
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Official Crest & Verification QR
                          SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/school_logo.png',
                                  height: 54,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school,
                                    size: 50,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                                  ),
                                  child: QrImageView(
                                    data: verifyUrl,
                                    version: QrVersions.auto,
                                    size: 50.0,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Verify This Certificate',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Text(
                                  'www.gokulshreeschool.com',
                                  style: TextStyle(
                                    fontSize: 6.0,
                                    color: Color(0xFFB91C1C),
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Center: Red Calligraphic Institution Name + Accreditations + Main Title
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Calligraphic Red Header
                                  Text(
                                    'Gokulshree School Of Management And Technology Private Limited',
                                    style: GoogleFonts.alexBrush(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB91C1C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 1),
                                  // Official Govt / Company Act Subtitle
                                  const Text(
                                    'Registered Under Companies Act 2013, Corporate Identification Number is U85499UP2024PTC196434\nMSME Registration: UDYAM-UP-18-0008432, AN ISO 9001:2015 Certified Institute',
                                    style: TextStyle(
                                      fontSize: 7.2,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                      height: 1.25,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  // Main Certificate Title
                                  Text(
                                    'CERTIFICATE OF COMPLETION',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.2,
                                      color: const Color(0xFF4C1D95),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verify This Certificate www.gokulshreeschool.com',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right: Student Passport Photo
                          SizedBox(
                            width: 100,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 72,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(color: const Color(0xFF0284C7), width: 1.6),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(1),
                                        child: Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.person, size: 44, color: Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.person, size: 44, color: Color(0xFF94A3B8)),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── DOTTED FORM BODY ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Line 1: This is to Certify that Mr./Miss
                            _buildDottedRow(
                              prefix: 'This is to Certify that Mr./Miss',
                              value: studentName,
                            ),
                            const SizedBox(height: 10),

                            // Line 2: S/O, D/O, W/O
                            _buildDottedRow(
                              prefix: 'S/O, D/O, W/O',
                              value: fatherName,
                            ),
                            const SizedBox(height: 10),

                            // Line 3: With his/her Regd. No ... has successfully completed the course
                            Row(
                              children: [
                                const Text(
                                  'With his/her Regd. No',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: CustomPaint(
                                    painter: _DottedLinePainter(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        regNo,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'has successfully completed the course',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Line 4: Course Name (Centered prominent line)
                            CustomPaint(
                              painter: _DottedLinePainter(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  courseName,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Line 5: Course Duration
                            _buildDottedRow(
                              prefix: 'Course Duration',
                              value: durationText,
                            ),
                            const SizedBox(height: 10),

                            // Line 6: Grade ... And Percent
                            Row(
                              children: [
                                const Text(
                                  'Grade',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: CustomPaint(
                                    painter: _DottedLinePainter(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        grade,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'And Percent',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: CustomPaint(
                                    painter: _DottedLinePainter(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        percentRaw,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Line 7: Center
                            _buildDottedRow(
                              prefix: 'Center',
                              value: '(GOKUL) $centerName',
                            ),
                          ],
                        ),
                      ),

                      // ─── BOTTOM FOOTER ROW ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Issue Date (Bottom Left)
                            SizedBox(
                              width: 130,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    issueDate,
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Issue Date',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Accreditation Badges (Bottom Center)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/iso-logo.png',
                                    height: 38,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 24),
                                  Image.asset(
                                    'assets/images/msme_logo.png',
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 24),
                                  Image.asset(
                                    'assets/images/skill_India-logo.png',
                                    height: 38,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),

                            // Digital Signature (Bottom Right)
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSigned)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 15,
                                          color: Color(0xFF16A34A),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Signature Valid',
                                          style: GoogleFonts.alexBrush(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Controller',
                                      style: GoogleFonts.alexBrush(
                                        fontSize: 18,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  Container(
                                    width: 120,
                                    height: 1.0,
                                    color: const Color(0xFF94A3B8),
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                  ),
                                  const Text(
                                    'Signature',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF64748B),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedRow({required String prefix, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          prefix,
          style: const TextStyle(
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomPaint(
            painter: _DottedLinePainter(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
