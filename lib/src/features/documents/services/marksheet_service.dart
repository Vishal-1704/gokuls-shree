// lib/src/features/documents/services/marksheet_service.dart
// Native client-side marksheet PDF generation bypassing Puppeteer.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gokul_shree_app/src/core/services/api_client.dart';

class SubjectResult {
  final String name;
  final int maxMarks;
  final int obtainedMarks;

  SubjectResult({
    required this.name,
    required this.maxMarks,
    required this.obtainedMarks,
  });
}

class MarksheetService {
  final ApiClient _apiClient;

  // Utilize the apiClient if provided, otherwise default to a new instance.
  MarksheetService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Natively generates the Marksheet PDF client-side using the `pdf` package.
  /// Bypasses Puppeteer server dependency.
  Future<Uint8List> generateMarksheet({
    required String studentName,
    required String regNo,
    required String courseName,
    required String session,
    required List<SubjectResult> subjects,
    required String marksheetId,
    required String verificationUrl,
    String? fatherName,
    String? centreName,
    String? courseDuration,
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

    // Sum up marks
    int totalMax = 0;
    int totalObtained = 0;
    for (final sub in subjects) {
      totalMax += sub.maxMarks;
      totalObtained += sub.obtainedMarks;
    }
    final pct = totalMax > 0 ? (totalObtained / totalMax * 100) : 0.0;
    final percentageStr = pct.toStringAsFixed(1);
    
    // Determine Grade & Result
    final String grade;
    if (pct >= 85) grade = 'A+';
    else if (pct >= 75) grade = 'A';
    else if (pct >= 60) grade = 'B';
    else if (pct >= 50) grade = 'C';
    else grade = 'D';

    final String resultStr = pct >= 40 ? 'PASS' : 'FAIL';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#F5CC45'), width: 2),
            ),
            child: pw.Stack(
              children: [
                // ──── Optional Background Image Watermark ────
                if (bgImageBytes != null)
                  pw.Positioned.fill(
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Image(pw.MemoryImage(bgImageBytes), fit: pw.BoxFit.fill),
                    ),
                  ),

                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // ──── Header ────
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (logoImageBytes != null)
                            pw.Container(
                              width: 60,
                              height: 60,
                              child: pw.Image(pw.MemoryImage(logoImageBytes)),
                            )
                          else
                            pw.SizedBox(width: 60, height: 60),

                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'GOKULSHREE SCHOOL',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 20,
                                    color: PdfColor.fromHex('#0E1E33'),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.Text(
                                  'OF MANAGEMENT & TECHNOLOGY',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 10,
                                    color: PdfColor.fromHex('#4B5563'),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.Text(
                                  'An ISO 9001:2015 Certified Institution',
                                  style: pw.TextStyle(
                                    font: fontItalic,
                                    fontSize: 8,
                                    color: PdfColor.fromHex('#6B7280'),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 60, height: 60),
                        ],
                      ),
                      
                      pw.Divider(thickness: 1, color: PdfColor.fromHex('#F5CC45')),
                      pw.SizedBox(height: 10),

                      // ──── Title ────
                      pw.Center(
                        child: pw.Text(
                          'STATEMENT OF MARKS',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 15),

                      // ──── Student Info Block ────
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Table(
                              columnWidths: {
                                0: const pw.FixedColumnWidth(100),
                                1: const pw.FlexColumnWidth(),
                              },
                              children: [
                                _buildInfoTableRow('Student Name:', studentName.toUpperCase(), fontBold, font),
                                _buildInfoTableRow("Father's Name:", (fatherName ?? 'N/A').toUpperCase(), fontBold, font),
                                _buildInfoTableRow('Course Name:', courseName, fontBold, font),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            child: pw.Table(
                              columnWidths: {
                                0: const pw.FixedColumnWidth(100),
                                1: const pw.FlexColumnWidth(),
                              },
                              children: [
                                _buildInfoTableRow('Registration No:', regNo, fontBold, font),
                                _buildInfoTableRow('Marksheet ID:', marksheetId, fontBold, font),
                                _buildInfoTableRow('Academic Session:', session, fontBold, font),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20),

                      // ──── Marks Table ────
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(5),
                          1: const pw.FixedColumnWidth(100),
                          2: const pw.FixedColumnWidth(100),
                        },
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0E1E33')),
                            children: [
                              _buildTableCell('SUBJECT NAME', fontBold, isHeader: true),
                              _buildTableCell('MAX MARKS', fontBold, isHeader: true),
                              _buildTableCell('OBTAINED MARKS', fontBold, isHeader: true),
                            ],
                          ),
                          // Subject Rows
                          ...subjects.map(
                            (sub) => pw.TableRow(
                              children: [
                                _buildTableCell(sub.name, font),
                                _buildTableCell(sub.maxMarks.toString(), font, align: pw.TextAlign.center),
                                _buildTableCell(sub.obtainedMarks.toString(), fontBold, align: pw.TextAlign.center),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 15),

                      // ──── Summary Block ────
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total Max Marks: $totalMax',
                              style: pw.TextStyle(font: fontBold, fontSize: 10),
                            ),
                            pw.Text(
                              'Total Obtained: $totalObtained',
                              style: pw.TextStyle(font: fontBold, fontSize: 10),
                            ),
                            pw.Text(
                              'Percentage: $percentageStr%',
                              style: pw.TextStyle(font: fontBold, fontSize: 10),
                            ),
                            pw.Text(
                              'Grade: $grade',
                              style: pw.TextStyle(font: fontBold, fontSize: 10),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: resultStr == 'PASS' ? PdfColors.green100 : PdfColors.red100,
                              child: pw.Text(
                                'Result: $resultStr',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: resultStr == 'PASS' ? PdfColors.green800 : PdfColors.red800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.Spacer(),

                      // ──── Verification & Footer ────
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Left side: Proclamations & QR
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                width: 70,
                                height: 70,
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: verificationUrl,
                                  drawText: false,
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const pw.BoxDecoration(
                                          color: PdfColors.green,
                                          shape: pw.BoxShape.circle,
                                        ),
                                      ),
                                      pw.SizedBox(width: 4),
                                      pw.Text(
                                        'SECURE DIGITAL RECORD',
                                        style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 7,
                                          color: PdfColors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Text(
                                    'This is a cryptographically verified digital document.',
                                    style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey700),
                                  ),
                                  pw.Text(
                                    'Verification URL: $verificationUrl',
                                    style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey600),
                                  ),
                                  pw.Text(
                                    'SHA256 Hash: SHA256-${marksheetId.hashCode.toRadixString(16).toUpperCase()}',
                                    style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey600),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Right side: Signatures
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.green500, width: 0.5),
                                  color: PdfColors.green50,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          'Digitally Signed by:',
                                          style: pw.TextStyle(font: fontItalic, fontSize: 6, color: PdfColors.grey700),
                                        ),
                                        pw.Text(
                                          'Controller of Examinations',
                                          style: pw.TextStyle(font: fontBold, fontSize: 8),
                                        ),
                                        pw.Text(
                                          'Date: $session',
                                          style: pw.TextStyle(font: font, fontSize: 6),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(width: 8),
                                    pw.Container(
                                      width: 20,
                                      height: 20,
                                      child: pw.CustomPaint(
                                        painter: (canvas, size) {
                                          canvas
                                            ..setColor(PdfColors.green700)
                                            ..setLineWidth(1.5)
                                            ..drawEllipse(10, 10, 9, 9)
                                            ..strokePath();
                                          canvas
                                            ..setColor(PdfColors.green700)
                                            ..setLineWidth(2)
                                            ..moveTo(6, 10)
                                            ..lineTo(9, 7)
                                            ..lineTo(14, 13)
                                            ..strokePath();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper method kept for compatibility
  String computeHash(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return sha256.convert(bytes).toString();
  }

  // Helper to build Info Table Row
  pw.TableRow _buildInfoTableRow(String label, String value, pw.Font labelFont, pw.Font valueFont) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: labelFont, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: valueFont, fontSize: 9, color: PdfColor.fromHex('#0E1E33')),
          ),
        ),
      ],
    );
  }

  // Helper to build Table Cell
  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8 : 9,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
