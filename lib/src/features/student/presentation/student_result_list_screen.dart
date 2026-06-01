import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/backend_service.dart';

class StudentResultListScreen extends ConsumerWidget {
  const StudentResultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentExamResultsProvider);
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Results',
          style: AppTypography.headingMd.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results yet',
                    style: AppTypography.headingSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final score = result['score'] as num;
              final total = result['total'] as num;

              // Handle division by zero
              final percentage = total > 0 ? (score / total) * 100 : 0.0;

              Color gradeColor = AppColors.success;
              if (percentage < 35) {
                gradeColor = AppColors.danger;
              } else if (percentage < 60) {
                gradeColor = AppColors.warning;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Circular Progress
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: AppColors.inkNavy700,
                                  valueColor: AlwaysStoppedAnimation(gradeColor),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: AppTypography.labelSm.copyWith(
                                  color: gradeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Exam Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result['title'] as String,
                                  style: AppTypography.headingSm.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${result['date']}',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Score fraction
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$score/$total',
                                style: AppTypography.headingMd.copyWith(
                                  color: AppColors.goldCta,
                                ),
                              ),
                              Text(
                                'Score',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final regNo = profileAsync.maybeWhen(
                              data: (profile) => profile['reg_no']?.toString() ?? '',
                              orElse: () => '',
                            );

                            if (regNo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Registration number is not available yet')),
                              );
                              return;
                            }

                            _downloadMarksheet(context, ref, regNo);
                          },
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            'Download Signed Marksheet',
                            style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldCta,
                            side: const BorderSide(color: AppColors.goldCta),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadMarksheet(
    BuildContext context,
    WidgetRef ref,
    String regNo,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading marksheet...')));

      final backendService = ref.read(backendServiceProvider);
      // In real scenario, strip prefix if needed or ensure format matches backend expectation
      // The backend expects just the regNo
      final filePath = await backendService.downloadMarksheet(regNo);

      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                // Open file logic could go here (e.g. open_file package)
                // For now just show path
              },
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
