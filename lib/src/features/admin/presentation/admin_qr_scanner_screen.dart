import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/widgets/app_image.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

class AdminQRScannerScreen extends ConsumerStatefulWidget {
  const AdminQRScannerScreen({super.key});

  @override
  ConsumerState<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends ConsumerState<AdminQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  int _selectedMode = 0; // 0: Verify Admit Card, 1: Verify Student

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _onCodeDetected(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _onCodeDetected(String code) async {
    setState(() => _isScanning = false);
    _controller.stop();

    // Verify student directly against Supabase
    final result = await ref.read(adminRepositoryProvider).verifyStudentQr(code);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(code, result),
    ).then((_) {
      if (mounted) {
        setState(() => _isScanning = true);
        _controller.start();
      }
    });
  }

  Widget _buildResultSheet(String code, Map<String, dynamic> result) {
    final isValid = result['is_valid'] == true;
    final isAttendanceMode = _selectedMode == 1;
    final studentName = result['student_name'] ?? 'Unknown';
    final regNo = result['reg_no'] ?? code;
    final rollNo = result['roll_no'];
    final course = result['course'] ?? 'N/A';
    final branch = result['branch'] ?? 'Main Branch';
    final status = result['status'] ?? 'Unknown';
    final photoUrl = result['photo_url']?.toString();
    final message = result['message']?.toString() ?? (isValid ? 'Student Verified' : 'Invalid QR Code');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.inkNavy900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isValid ? Colors.green : Colors.red,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            isValid
                ? (isAttendanceMode ? 'Student Identity Verified' : 'Valid Student Admit Card')
                : 'Verification Failed',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: isValid ? Colors.green.shade300 : Colors.red.shade300,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isValid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final avatar = resolveAvatarProvider(photoUrl);
                      return CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.inkNavy700,
                        backgroundImage: avatar,
                        onBackgroundImageError: avatar != null ? (_, __) {} : null,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 32, color: AppColors.textSecondary)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reg: $regNo ${rollNo != null ? "• Roll: $rollNo" : ""}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course,
                          style: const TextStyle(color: AppColors.goldCta, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              branch,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: status == 'Active' ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Active' ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inkNavy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.textMuted, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scanned Payload',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? const Color(0xFF006B3F) : AppColors.inkNavy700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scan Another',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          // Overlay
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: AppColors.textPrimary),
                    onPressed: () => _controller.toggleTorch(),
                  ),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch, color: AppColors.textPrimary),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
          // Mode Toggle
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildModeButton(0, 'Verify Admit Card')),
                  Expanded(child: _buildModeButton(1, 'Verify Student')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, String label) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCta : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.inkNavy900 : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
