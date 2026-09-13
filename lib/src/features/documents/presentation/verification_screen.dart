import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/documents/data/document_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String? documentType; // 'marksheet' | 'certificate' — for deep linking
  final int? documentId;

  const VerificationScreen({super.key, this.documentType, this.documentId});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isScanning = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.documentType != null && widget.documentId != null) {
      _verifyDocument(widget.documentType!, widget.documentId!);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code == null || !code.contains('/verify/')) continue;

      // Expected shape: .../verify/<type>/<id> — type is 'marksheet' or
      // 'certificate', matching what verify_document_signature expects.
      final uri = Uri.parse(code);
      final segments = uri.pathSegments;
      final index = segments.indexOf('verify');
      if (index != -1 && index + 2 < segments.length) {
        final type = segments[index + 1];
        final id = int.tryParse(segments[index + 2]);
        if (id != null &&
            (type == 'marksheet' ||
                type == 'certificate' ||
                type == 'payslip' ||
                type == 'experience_certificate')) {
          _verifyDocument(type, id);
          break;
        }
      }
    }
  }

  Future<void> _verifyDocument(String type, int id) async {
    setState(() {
      _isScanning = false;
      _isLoading = true;
    });

    try {
      final result = await ref
          .read(documentRepositoryProvider)
          .verifyDocument(type, id);

      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog({'result': 'not_found', 'document': null});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// [outcome] is the map returned by DocumentRepository.verifyDocument:
  /// {'result': 'valid'|'tampered'|'unsigned'|'not_found', 'document': {...}?}
  void _showResultDialog(Map<String, dynamic> outcome) {
    final result = (outcome['result'] ?? 'not_found').toString();
    final doc = outcome['document'] as Map<String, dynamic>?;

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String message;

    switch (result) {
      case 'valid':
        icon = Icons.verified_rounded;
        color = Colors.green;
        title = 'Signature Valid';
        message =
            'This document is authentic and has not been altered since it was issued.';
        break;
      case 'tampered':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        title = 'Signature Invalid';
        message =
            'This document exists in our records but its data does not match what was originally signed — it may have been altered.';
        break;
      case 'unsigned':
        icon = Icons.help_rounded;
        color = Colors.amber.shade700;
        title = 'Validity Unknown';
        message =
            'This document exists but has not been digitally signed (not yet approved, or issued before signing was enabled).';
        break;
      default:
        icon = Icons.help_outline_rounded;
        color = Colors.grey;
        title = 'Not Found';
        message =
            'No document matches this code. It may be fake or the record may have been removed.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (result == 'valid' && doc != null) ...[
              _buildDetailRow(
                'Document Type',
                (doc['type'] as String).toUpperCase(),
              ),
              _buildDetailRow('Student Name', doc['students']['name']),
              _buildDetailRow(
                'Registration No',
                doc['students']['registration_number'],
              ),
              const Divider(height: 24),
              if (doc['data'] != null)
                ...(doc['data'] as Map<String, dynamic>).entries.map((e) {
                  String key = e.key
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map(
                        (str) => str.isNotEmpty
                            ? '${str[0].toUpperCase()}${str.substring(1)}'
                            : '',
                      )
                      .join(' ');
                  return _buildDetailRow(key, e.value.toString());
                }),
              const Divider(height: 24),
              _buildDetailRow(
                'Issued Date',
                doc['created_at'].toString().split('T')[0],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isScanning = true); // Resume scanning
              },
              child: const Text('Scan Another'),
            ),
            if (widget.documentId !=
                null) // If opened from link, allow going home
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false),
                child: const Text('Go Home'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define scan window size for A4 Landscape aspect ratio (approx 1.41)
    final scanWindowSize = Size(
      MediaQuery.of(context).size.width * 0.85,
      (MediaQuery.of(context).size.width * 0.85) / 1.414,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Certificate'),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textPrimary,
      ),
      backgroundColor: Colors.black,
      body: widget.documentId != null
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Waiting for auto-verify
          : Stack(
              children: [
                MobileScanner(
                  onDetect: _onDetect,
                  scanWindow: Rect.fromCenter(
                    center: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2,
                    ),
                    width: scanWindowSize.width,
                    height: scanWindowSize.height,
                  ),
                ),
                // Colored Overlay with transparent hole
                _ScannerOverlay(scanWindowSize: scanWindowSize),

                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Align certificate within the frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanning for QR code...',
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Size scanWindowSize;

  const _ScannerOverlay({required this.scanWindowSize});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: scanWindowSize.width,
              height: scanWindowSize.height,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
