import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';

class StudentNoticeBoard extends StatelessWidget {
  final StudentRepository repo;

  const StudentNoticeBoard({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getNotices(),
      builder: (context, snap) {
        final notices = snap.data ?? [];
        if (notices.isEmpty) return _buildEmptyNotice();
        
        return Column(
          children: notices.take(2).map((n) => _buildNoticeTile(n)).toList(),
        );
      },
    );
  }

  Widget _buildNoticeTile(Map<String, dynamic> notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.goldCta.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.campaign_rounded, color: AppColors.goldCta, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice['title'] ?? 'Notice', style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                Text(notice['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotice() => Center(child: Text('No active notices', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)));
}
