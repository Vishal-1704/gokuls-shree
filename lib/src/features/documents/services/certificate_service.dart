import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CertificateService {
  /// Generate a certificate PDF matching the website template design
  /// Website uses LANDSCAPE A4 with background watermark
  Future<Uint8List> generateCertificate({
    required String studentName,
    required String courseName,
    required String duration,
    required String date,
    required String certificateId,
    required String verificationUrl,
    String? fatherName,
    String? regNo,
    String? grade,
    String? percentage,
    String? centreName,
    Uint8List? bgImageBytes,
    Uint8List? logoImageBytes,
    Uint8List? isoImageBytes,
    Uint8List? msmeImageBytes,
    Uint8List? skillImageBytes,
  }) async {
    final pdf = pw.Document();

    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontItalic = pw.Font.helveticaOblique();

    // Load assets - ONLY Template is needed for background
    final bgImage = pw.MemoryImage(
      bgImageBytes ??
          (await rootBundle.load(
            'assets/images/certificate_bg.jpg',
          )).buffer.asUint8List(),
    );

    // Dynamic Issue Date
    final issueDate = date;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // ──── BACKGROUND TEMPLATE ────
              pw.Positioned.fill(child: pw.Image(bgImage, fit: pw.BoxFit.fill)),

              // ──── OVERLAY TEXT FIELDS ────
              // Coordinates need to be calibrated based on the template image.
              // Assuming A4 Landscape: 842 x 595 points.

              // 1. Student Name
              pw.Positioned(
                left: 280,
                top: 255,
                child: pw.Text(
                  studentName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                    color: PdfColors.black,
                  ),
                ),
              ),

              // 2. Father Name
              pw.Positioned(
                left: 280,
                top: 288,
                child: pw.Text(
                  fatherName ?? '-',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 3. Reg No
              pw.Positioned(
                left: 280,
                top: 320,
                child: pw.Text(
                  regNo ?? '-',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 4. Course Name
              pw.Positioned(
                left: 0,
                right: 0,
                top: 365,
                child: pw.Center(
                  child: pw.Text(
                    courseName,
                    style: pw.TextStyle(font: fontBold, fontSize: 20),
                  ),
                ),
              ),

              // 5. Course Duration
              pw.Positioned(
                left: 280,
                top: 405, // Adjusted based on visual estimation
                child: pw.Text(
                  duration,
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 6. Grade
              pw.Positioned(
                left: 170, // "Grade" label specific
                top: 440,
                child: pw.Text(
                  grade ?? 'A',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 7. Percentage
              pw.Positioned(
                left: 450, // "And Secured" label specific
                top: 440,
                child: pw.Text(
                  '${percentage ?? '-'}%',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 8. Centre Name
              pw.Positioned(
                left: 280,
                top: 475,
                child: pw.Text(
                  centreName ?? 'Gokulshree Computer Education',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),

              // 9. Issue Date (Bottom Left)
              pw.Positioned(
                left: 65,
                bottom: 50,
                child: pw.Column(
                  children: [
                    pw.Text(
                      issueDate,
                      style: pw.TextStyle(font: fontBold, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 10. QR Code (Left Side)
              pw.Positioned(
                left: 60,
                top: 150,
                child: pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: verificationUrl,
                    drawText: false,
                  ),
                ),
              ),

              // 11. Photo Placeholder (Right Side)
              pw.Positioned(
                right: 60,
                top: 150,
                child: pw.Container(
                  width: 80,
                  height: 100,
                  alignment: pw.Alignment.center,
                  // If photo bytes provided, use image, else text
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Text('Photo'),
                ),
              ),

              // ──── DIGITAL SIGNATURE (Classy Vector) ────
              pw.Positioned(
                right: 60,
                bottom: 40,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Digitally Signed',
                            style: pw.TextStyle(
                              font: fontItalic,
                              fontSize: 6,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'Controller of Examinations',
                            style: pw.TextStyle(font: fontBold, fontSize: 9),
                          ),
                          pw.Text(
                            'Gokulshree School',
                            style: pw.TextStyle(font: fontBold, fontSize: 9),
                          ),
                          pw.Text(
                            issueDate,
                            style: pw.TextStyle(font: font, fontSize: 7),
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 8),
                      // Classy checkmark / signature icon
                      pw.Container(
                        width: 30,
                        height: 30,
                        child: pw.CustomPaint(
                          painter: (canvas, size) {
                            // Draw a stylized checkmark inside a circle
                            canvas
                              ..setColor(
                                PdfColor.fromHex('#2e7d32'),
                              ) // Green shade
                              ..setLineWidth(2)
                              ..drawEllipse(15, 15, 14, 14)
                              ..strokePath();

                            canvas
                              ..setColor(PdfColor.fromHex('#2e7d32'))
                              ..setLineWidth(2.5)
                              ..setLineCap(PdfLineCap.round)
                              ..setLineJoin(PdfLineJoin.round)
                              ..moveTo(8, 16)
                              ..lineTo(14, 10) // down stroke
                              ..lineTo(22, 20) // up stroke
                              ..strokePath();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════

  /// Compute SHA-256 hash of document data
  String computeHash(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
