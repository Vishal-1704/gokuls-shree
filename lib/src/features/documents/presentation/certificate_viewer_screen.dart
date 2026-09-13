import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class CertificateViewerScreen extends StatefulWidget {
  const CertificateViewerScreen({super.key, required this.certificate});

  final Map<String, dynamic> certificate;

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isExporting = false;

  String _clean(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary =
          _certificateKey.currentContext?.findRenderObject()
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

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
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
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Save / Print as PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'High resolution official document for printing',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
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
                    child: const Icon(
                      Icons.image_rounded,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  title: const Text(
                    'Save as PNG Image',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Clear image for gallery & instant sharing',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final student =
        widget.certificate['students'] as Map<String, dynamic>? ?? {};
    final course = widget.certificate['courses'] as Map<String, dynamic>? ?? {};

    final rawStudentName = student['name']?.toString() ?? 'STUDENT NAME';
    final studentName = (rawStudentName == 'N/A' || rawStudentName.isEmpty)
        ? 'STUDY CENTRE DIRECTOR'
        : rawStudentName.toUpperCase();

    final courseName = course['name']?.toString() ?? 'AUTHORISED STUDY CENTRE';
    final session = widget.certificate['session'] ?? '2024-2027';
    final grade = widget.certificate['grade'] ?? 'A+';
    final certNo = widget.certificate['certificate_no'] ?? 'AUTH-GS-001';
    final issueDate =
        widget.certificate['issue_date'] ??
        DateTime.now().toString().split(' ')[0];

    final isBranchCert =
        courseName.toUpperCase().contains('AUTHORISED') ||
        courseName.toUpperCase().contains('AUTHORIZATION') ||
        certNo.toString().toUpperCase().startsWith('AUTH');

    return Scaffold(
      backgroundColor: const Color(
        0xFFF1F5F9,
      ), // Professional light document canvas
      appBar: AppBar(
        title: Text(
          isBranchCert
              ? 'Branch Authorization Certificate'
              : 'Digital Certificate',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Center(
          child: SizedBox(
            // Fixed width (not screen-derived) so a landscape A4 ratio
            // doesn't get squeezed into a too-short box on a narrow phone
            // — the same class of overflow the portrait marksheet hit.
            width: 640,
            child: RepaintBoundary(
              key: _certificateKey,
              child: AspectRatio(
                aspectRatio: 297 / 210,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/certificate_bg.jpg'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        // Keeps content inside the printed border of the bg image
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.09,
                          vertical: constraints.maxHeight * 0.08,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── School Crest & Institution Header ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFFBEB),
                                    border: Border.all(
                                      color: const Color(0xFFC59B27),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFFC59B27),
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              '${EnvConfig.shortName.toUpperCase()} GROUP OF INSTITUTIONS',
                              style: AppTypography.displayLg.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                                color: const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SCHOOL OF ADVANCED MANAGEMENT & TECHNOLOGY',
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF475569),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'An Autonomous Educational Body Registered under Govt. of India Norms',
                              style: TextStyle(
                                fontSize: 7.8,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 10),

                            // Decorative Gold Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(
                                      0xFFC59B27,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: Color(0xFFC59B27),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(
                                      0xFFC59B27,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ── Certificate Title Banner ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFD97706),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                isBranchCert
                                    ? 'CERTIFICATE OF AUTHORIZATION'
                                    : 'CERTIFICATE OF EXCELLENCE',
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── Sub-header / Statement ──
                            Text(
                              isBranchCert
                                  ? 'This is to officially certify that'
                                  : 'This certificate is proudly presented to',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            // ── Director / Candidate Name ──
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 120,
                              height: 1.5,
                              color: const Color(0xFFC59B27),
                            ),

                            const SizedBox(height: 8),

                            // ── Accreditation / Course Text ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                isBranchCert
                                    ? 'has been accredited and authorized to operate an official Study & Training Centre for $courseName under Academic Session $session.'
                                    : 'for successfully completing the course of study in $courseName during the academic session $session, and obtaining Grade "$grade".',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Official Seals & Signatures ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Left: Signature of Director
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/images/director_signature.png',
                                      height: 30,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(
                                            height: 30,
                                            child: Center(
                                              child: Text(
                                                'Director Sign',
                                                style: TextStyle(
                                                  fontFamily: 'cursive',
                                                  color: Color(0xFF1E293B),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                    Container(
                                      width: 95,
                                      height: 1.0,
                                      color: const Color(0xFF334155),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'DIRECTOR',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const Text(
                                      'Authorized Signatory',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 7.8,
                                      ),
                                    ),
                                  ],
                                ),

                                // Center: Official Seal Badge
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFFBEB),
                                    border: Border.all(
                                      color: const Color(0xFFC59B27),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFC59B27,
                                        ).withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified_outlined,
                                          size: 16,
                                          color: Color(0xFFB45309),
                                        ),
                                        SizedBox(height: 1),
                                        Text(
                                          'OFFICIAL\nSEAL',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 6.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF92400E),
                                            letterSpacing: 0.4,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Right: QR Code for Instant Verification
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: QrImageView(
                                        data:
                                            '${EnvConfig.verifyBaseUrl}/certificate/${widget.certificate['id']}',
                                        version: QrVersions.auto,
                                        size: 42.0,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0F172A),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                              color: Color(0xFF0F172A),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'SCAN TO VERIFY',
                                      style: TextStyle(
                                        fontSize: 7.0,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Divider(color: Colors.grey.shade300, height: 1),
                            const SizedBox(height: 6),

                            // ── Footer Details ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildFooterDetail('CERTIFICATE NO', certNo),
                                _buildFooterDetail('DATE OF ISSUE', issueDate),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF059669),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'VERIFIED DIGITAL CREDENTIAL & OFFICIAL RECORD',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 7.8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
