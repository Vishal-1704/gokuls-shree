import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

class AdminAdmitCardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> student;

  const AdminAdmitCardScreen({super.key, required this.student});

  @override
  ConsumerState<AdminAdmitCardScreen> createState() =>
      _AdminAdmitCardScreenState();
}

class _AdminAdmitCardScreenState extends ConsumerState<AdminAdmitCardScreen> {
  bool _isGenerating = false;
  Map<String, dynamic>? _admitCardData;

  String get _qrPayload =>
      'ADM:${widget.student['reg_no'] ?? '000'}:${widget.student['name'] ?? 'student'}';

  @override
  void initState() {
    super.initState();
    _generateCard();
  }

  Future<void> _generateCard() async {
    setState(() => _isGenerating = true);
    try {
      final data = await ref
          .read(adminRepositoryProvider)
          .generateAdmitCard(
            studentId: widget.student['reg_no'] ?? '000',
            examId: 'EXAM2025-FINAL',
          );
      if (mounted) {
        setState(() {
          _admitCardData = data;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating card: $e')));
      }
    }
  }

  Future<void> _sharePdf() async {
    final pdf = pw.Document();
    final name = widget.student['name']?.toString() ?? 'Student';
    final regNo = widget.student['reg_no']?.toString() ?? '-';
    final className = widget.student['class']?.toString() ?? '-';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'ADMIT CARD',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Name: $name'),
                pw.Text('Reg No: $regNo'),
                pw.Text('Class: $className'),
                pw.SizedBox(height: 24),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: _qrPayload,
                    width: 140,
                    height: 140,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'admit_card_$regNo.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admit Card'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating Admit Card...'),
                ],
              ),
            )
          : _admitCardData == null
          ? const Center(child: Text('Failed to load.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/school_logo.png',
                              height: 40,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.school, size: 40),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ADMIT CARD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  'Session 2025-26',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            widget.student['photo_url'],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.student['name'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reg No: ${widget.student['reg_no']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoRow('Class', widget.student['class']),
                        _buildInfoRow('Exam Center', 'Main Block, Hall A'),
                        _buildInfoRow('Roll Number', '25010045'),
                        const SizedBox(height: 24),
                        QrImageView(
                          data: _qrPayload,
                          size: 120,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan to Verify',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share),
                          label: const Text('Share PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sent to Printer')),
                            );
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
