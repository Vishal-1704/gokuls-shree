import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
class CertificateViewerScreen extends StatelessWidget {
  const CertificateViewerScreen({super.key, required this.certificate});

  final Map<String, dynamic> certificate;

  @override
  Widget build(BuildContext context) {
    final student = certificate['students'] as Map<String, dynamic>? ?? {};
    final course = certificate['courses'] as Map<String, dynamic>? ?? {};
    
    final studentName = student['name']?.toString().toUpperCase() ?? 'STUDENT NAME';
    final courseName = course['name']?.toString() ?? 'COURSE MODULE';
    final session = certificate['session'] ?? '2024-2025';
    final grade = certificate['grade'] ?? 'A';
    final certNo = certificate['certificate_no'] ?? 'GS-CERT-XXXX';
    final issueDate = certificate['issue_date'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Digital Certificate'),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E), // deep dark paper backdrop
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goldCta, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldCta.withOpacity(0.08),
                blurRadius: 40,
                spreadRadius: 8,
              )
            ],
          ),
          child: Stack(
            children: [
              // ── Decorative Corner Frames ──
              Positioned(left: 8, top: 8, child: _buildCorner(0)),
              Positioned(right: 8, top: 8, child: _buildCorner(90)),
              Positioned(left: 8, bottom: 8, child: _buildCorner(270)),
              Positioned(right: 8, bottom: 8, child: _buildCorner(180)),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  children: [
                    // School Name Display
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.goldCta, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'GOKULSHREE SCHOOL',
                      style: AppTypography.displayLg.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'OF MANAGEMENT & TECHNOLOGY',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'CERTIFICATE OF EXCELLENCE',
                      style: AppTypography.headingSm.copyWith(
                        color: AppColors.goldShine,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'This is proudly presented to',
                      style: AppTypography.bodyMd.copyWith(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      studentName,
                      style: AppTypography.displayMd.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'for successfully completing the course of study in $courseName during the academic session $session, and obtaining Grade "$grade".',
                        style: AppTypography.bodyMd.copyWith(height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Signatures & QR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/director_signature.png',
                              height: 40,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    'Director Sign',
                                    style: TextStyle(
                                      fontFamily: 'cursive',
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 120, height: 1, color: Colors.white30),
                            const SizedBox(height: 4),
                            Text('DIRECTOR', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: QrImageView(
                            data: 'https://gokulshreeschool.com/verify/cert/$certNo',
                            version: QrVersions.auto,
                            size: 64.0,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFooterDetail('CERTIFICATE NO', certNo),
                        _buildFooterDetail('DATE OF ISSUE', issueDate),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'SECURE DIGITAL RECORD VERIFIED',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildCorner(double angle) {
    return Transform.rotate(
      angle: angle * 3.14159 / 180,
      child: Container(
        height: 24,
        width: 24,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.goldCta, width: 2),
            top: BorderSide(color: AppColors.goldCta, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm.copyWith(fontSize: 8, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.mono.copyWith(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
