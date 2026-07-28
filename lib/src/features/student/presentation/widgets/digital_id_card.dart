import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class DigitalIDCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const DigitalIDCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.inkNavy800, AppColors.inkNavy700],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: AppColors.goldCta.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.school_rounded, size: 150, color: AppColors.textPrimary.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name']?.toUpperCase() ?? 'STUDENT', style: AppTypography.headingMd.copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(data['class_section'] ?? 'Class/Course', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      _buildIDDetail('REG NO', data['reg_no'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildIDDetail('SESSION', '2024-25'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(8)),
                      child: QrImageView(
                        data: 'STU-${data['id']}',
                        version: QrVersions.auto,
                        size: 80.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('SCAN FOR PROFILE', style: AppTypography.labelSm.copyWith(fontSize: 8, color: AppColors.goldCta)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIDDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm.copyWith(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}
