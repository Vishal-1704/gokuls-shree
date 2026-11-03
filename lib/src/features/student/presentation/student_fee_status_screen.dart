import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';

class StudentFeeStatusScreen extends ConsumerWidget {
  const StudentFeeStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(studentFeeStatusProvider);
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'Fee Status',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/student'),
        ),
      ),
      body: feeAsync.when(
        data: (fees) {
          final profile = profileAsync.asData?.value;
          final courseName = (profile?['class_section'] ?? 'Enrolled Course').toString();
          final regNo = (profile?['reg_no'] ?? 'N/A').toString();
          final feeSummary = profile?['fee_summary'] as Map<String, dynamic>?;

          // Calculate summary
          final totalPaid = fees
              .where((f) => f['status'] == 'paid')
              .fold<num>(0, (sum, item) => sum + (item['amount'] as num));
          final totalPending = fees
              .where((f) => f['status'] != 'paid')
              .fold<num>(0, (sum, item) => sum + (item['amount'] as num));
          final totalCourseFee = (feeSummary?['course_fee'] as num?) ?? (totalPaid + totalPending);

          if (fees.isEmpty && totalCourseFee == 0 && profile == null) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              _buildSummaryCard(
                totalPaid: totalPaid,
                totalPending: totalPending,
                courseName: courseName,
                totalCourseFee: totalCourseFee,
                regNo: regNo,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Installments',
                style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (fees.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider10),
                  ),
                  child: Center(
                    child: Text(
                      'No installments recorded yet.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...fees.map((fee) => _buildFeeCard(fee)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading fee status: $err',
            style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.inkNavy800,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No fee records found',
            style: AppTypography.headingSm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required num totalPaid,
    required num totalPending,
    required String courseName,
    required num totalCourseFee,
    required String regNo,
  }) {
    final isFullyPaid = totalCourseFee > 0 && totalPending <= 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldCta.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.goldCta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: AppTypography.headingSm.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reg. No: $regNo',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isFullyPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFullyPaid ? 'PAID IN FULL' : 'PENDING DUES',
                  style: AppTypography.labelSm.copyWith(
                    color: isFullyPaid ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Fee',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$totalCourseFee',
                      style: AppTypography.headingSm.copyWith(color: AppColors.goldCta),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid Total',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$totalPaid',
                      style: AppTypography.headingSm.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due / Pending',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$totalPending',
                      style: AppTypography.headingSm.copyWith(
                        color: totalPending > 0 ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> fee) {
    final status = fee['status'] as String;
    final isPaid = status == 'paid';
    final isOverdue = status == 'overdue';

    Color chipBg = AppColors.chipPendingBg;
    Color chipFg = AppColors.chipPendingFg;
    IconData statusIcon = Icons.schedule_rounded;
    String statusLabel = 'PENDING';

    if (isPaid) {
      chipBg = AppColors.chipPaidBg;
      chipFg = AppColors.chipPaidFg;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'PAID';
    } else if (isOverdue) {
      chipBg = AppColors.chipOverdueBg;
      chipFg = AppColors.chipOverdueFg;
      statusIcon = Icons.warning_rounded;
      statusLabel = 'OVERDUE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee['installment'] as String,
                      style: AppTypography.headingSm.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaid ? 'Paid on: ${fee['paidDate']}' : 'Due by: ${fee['dueDate']}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: chipFg),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTypography.labelSm.copyWith(
                        color: chipFg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    '₹${fee['amount']}',
                    style: AppTypography.headingMd.copyWith(color: AppColors.goldCta),
                  ),
                ],
              ),
              if (isPaid && fee['receiptNo'] != null)
                OutlinedButton.icon(
                  onPressed: () {
                    // Download receipt logic
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                )
              else if (!isPaid)
                ElevatedButton(
                  onPressed: () {
                    // Pay now logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: AppColors.inkNavy900,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Pay Now',
                    style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
