import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';


class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Actually you can watch the profile provider if it exists,
    // but for now let's just use static values with brand theme
    // until the full profile data is wired up.
    
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldCta, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=Gokul+Kumar&background=0D1B2A&color=D4AF37&size=200',
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gokul Kumar',
              style: AppTypography.headingLg.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              'Class 8-A',
              style: AppTypography.bodyMd.copyWith(color: AppColors.goldCta),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _buildInfoTile(Icons.email_outlined, 'Email', 'gokul@example.com'),
            _buildInfoTile(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
            _buildInfoTile(Icons.calendar_today_outlined, 'DOB', '15 Aug 2010'),
            _buildInfoTile(
              Icons.location_on_outlined,
              'Address',
              '123, Gandhi Nagar, Jaipur',
            ),
            _buildInfoTile(Icons.family_restroom_outlined, 'Guardian', 'Rajesh Kumar'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldCta.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.goldCta, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
