import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    
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
        actions: [
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.qr_code_2),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.inkNavy800,
                    title: const Text('Digital Profile QR', style: TextStyle(color: AppColors.textPrimary)),
                    content: Container(
                      width: 250,
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(
                        data: 'STU-${profile['id']}',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: AppColors.goldCta)),
                      ),
                    ],
                  ),
                );
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final feeSummary = profile['fee_summary'] as Map<String, dynamic>?;
          final courses = profile['courses'] as Map<String, dynamic>?;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldCta, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        profile['photo_url'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'User')}&background=0D1B2A&color=D4AF37&size=200',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    profile['name'] ?? 'Student Name',
                    style: AppTypography.headingLg.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Tabular Information Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Personal & Course Information',
                          style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      
                      _buildTableRow('Name', profile['name'] ?? 'N/A'),
                      _buildTableRow('Father', profile['father_name'] ?? 'N/A'),
                      _buildTableRow('Date Of Birth', profile['date_of_birth'] ?? profile['dob'] ?? 'N/A'),
                      _buildTableRow('Mobile', profile['phone'] ?? profile['contact'] ?? 'N/A'),
                      _buildTableRow('Gender', profile['gender'] ?? 'N/A'),
                      _buildTableRow('Address', profile['address'] ?? 'N/A'),
                      _buildTableRow('Email', profile['email'] ?? 'N/A'),
                      _buildTableRow('Program Name', courses?['category'] ?? 'N/A'),
                      _buildTableRow('Course Name', courses?['name'] ?? 'N/A', isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Fee Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Course Fee: INR ${feeSummary?['course_fee'] ?? 0}   Paid Total: INR ${feeSummary?['paid_total'] ?? 0}   Due : INR ${feeSummary?['due_amount'] ?? 0}',
                          style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.goldCta,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.people, color: Colors.white, size: 20),
                          onPressed: () {
                            // Example action for the blue button in screenshot
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (error, _) => Center(
          child: Text('Error loading profile: $error', style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
