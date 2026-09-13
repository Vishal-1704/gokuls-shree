import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

/// Same institutional palette as MarksheetViewerScreen's private
/// _MarksheetColors — duplicated here rather than made public there, to
/// avoid touching an already-working, heavily-tuned file for this.
class DocumentColors {
  DocumentColors._();
  static const navy = Color(0xFF12324A);
  static const gold = Color(0xFFC8A951);
  static const goldSoft = Color(0xFFF7F1DF);
  static const pageBackground = Color(0xFFF3F5F7);
  static const text = Color(0xFF1F2937);
  static const mutedText = Color(0xFF64748B);
  static const pass = Color(0xFF167C5C);
  static const warning = Color(0xFF9A6700);
  static const fail = Color(0xFFB42318);
}

/// Shared A4 document chrome (header, accreditation footer, signature
/// stamp, PDF export) used by payslip/experience-certificate viewers —
/// the same proven layout mechanics as MarksheetViewerScreen (fixed
/// 800px design width + FittedBox.scaleDown + true A4 ratio, so the
/// letterbox-free PDF export behavior carries over unchanged), just
/// parameterized instead of copy-pasted per document type.
class DocumentA4Frame extends StatefulWidget {
  const DocumentA4Frame({
    super.key,
    required this.appBarTitle,
    required this.subtitleLine,
    required this.body,
    required this.verifyType,
    required this.verifyId,
    required this.isSigned,
    required this.pdfFilenamePrefix,
  });

  final String appBarTitle;
  final String subtitleLine;
  final Widget body;
  final String verifyType;
  final String verifyId;
  final bool isSigned;
  final String pdfFilenamePrefix;

  @override
  State<DocumentA4Frame> createState() => _DocumentA4FrameState();
}

class _DocumentA4FrameState extends State<DocumentA4Frame> {
  final GlobalKey _sheetKey = GlobalKey();
  bool _isExporting = false;

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary =
          _sheetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportPdf({bool isShare = false}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final pngBytes = await _capturePng();
      if (pngBytes == null) throw Exception('Could not render document');

      final pdf = pw.Document();
      final image = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
      final pdfBytes = await pdf.save();
      final filename = '${widget.pdfFilenamePrefix}_${widget.verifyId}.pdf';

      if (isShare) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } else {
        await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: filename);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: DocumentColors.fail),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocumentColors.pageBackground,
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        backgroundColor: DocumentColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF',
            onPressed: _isExporting ? null : () => _exportPdf(isShare: true),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print / Save as PDF',
            onPressed: _isExporting ? null : () => _exportPdf(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: RepaintBoundary(
            key: _sheetKey,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 800,
                height: 800 * 297 / 210,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/marksheet_bg.jpg'),
                      fit: BoxFit.fill,
                      opacity: 0.45,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeader(),
                      widget.body,
                      _buildFooterRow(),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 68,
          errorBuilder: (_, __, ___) => const SizedBox(height: 68),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: double.infinity,
          child: Text(
            'GOKULSHREE SCHOOL OF MANAGEMENT AND TECHNOLOGY PRIVATE LIMITED',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              height: 1.25,
              color: DocumentColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitleLine,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: DocumentColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1.5, color: DocumentColors.gold),
      ],
    );
  }

  Widget _buildFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/iso-logo.png', height: 74, fit: BoxFit.contain),
              Image.asset('assets/images/msme_logo.png', height: 56, fit: BoxFit.contain),
              Image.asset('assets/images/skill_India-logo.png', height: 74, fit: BoxFit.contain),
              _buildSignatureStamp(),
              QrImageView(
                data: '${EnvConfig.verifyBaseUrl}/${widget.verifyType}/${widget.verifyId}',
                version: QrVersions.auto,
                size: 64.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureStamp() {
    final color = widget.isSigned ? DocumentColors.pass : DocumentColors.warning;
    final label = widget.isSigned ? 'Signature valid' : 'Validity unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Digitally signed by', style: TextStyle(fontSize: 13, color: DocumentColors.mutedText)),
                Text('Controller of Examninations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DocumentColors.navy)),
                Text('GSMT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DocumentColors.navy)),
              ],
            ),
            Positioned(
              left: 30,
              top: -8,
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  widget.isSigned ? 'assets/images/chekcIconpng .png' : 'assets/images/uncheck.png',
                  width: 70,
                  height: 70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared label/value row for document body content — matches
/// MarksheetViewerScreen's _buildInfoRow styling.
Widget documentInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: const TextStyle(fontSize: 15, color: DocumentColors.mutedText)),
        ),
        const Text(':  ', style: TextStyle(fontSize: 15, color: DocumentColors.mutedText)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: DocumentColors.text, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
