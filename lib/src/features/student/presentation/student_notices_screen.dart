import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

/// Notice Board — was a dashboard quick-action pointing at a route
/// (/notices) that didn't exist, so it errored on tap. getNotices() /
/// supabaseNoticesProvider already existed and worked; this was purely a
/// missing screen + route.
class StudentNoticesScreen extends ConsumerWidget {
  const StudentNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(supabaseNoticesProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Notice Board', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (e, _) => Center(
          child: Text('Error loading notices: $e', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: AppColors.inkNavy800, shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_rounded, size: 64, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No notices yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final n = notices[i];
              final type = (n['type'] ?? 'general').toString();
              final color = type == 'exam'
                  ? AppColors.primaryViolet
                  : type == 'fee'
                      ? AppColors.warning
                      : type == 'result'
                          ? AppColors.success
                          : AppColors.info;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.campaign_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (n['title'] ?? 'Notice').toString(),
                            style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          if ((n['content'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              n['content'].toString(),
                              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(n['published_at']?.toString()),
                            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String? ts) {
    if (ts == null) return '';
    final d = DateTime.tryParse(ts);
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
