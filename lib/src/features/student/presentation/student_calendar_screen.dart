import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';

/// Academic Calendar — was a dashboard quick-action pointing at a route
/// (/calendar) that didn't exist. getAcademicCalendarEvents() /
/// studentAcademicCalendarProvider already existed (exams + notices merged
/// and deduped); this was purely a missing screen + route.
class StudentCalendarScreen extends ConsumerWidget {
  const StudentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(studentAcademicCalendarProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Academic Calendar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (e, _) => Center(
          child: Text('Error loading calendar: $e', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: AppColors.inkNavy800, shape: BoxShape.circle),
                    child: const Icon(Icons.event_note_rounded, size: 64, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No upcoming events', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = events[i];
              final type = (e['type'] ?? 'event').toString();
              final color = type == 'exam'
                  ? AppColors.primaryViolet
                  : type == 'holiday'
                      ? AppColors.warning
                      : type == 'result'
                          ? AppColors.success
                          : AppColors.info;
              final icon = type == 'exam'
                  ? Icons.emoji_events_rounded
                  : type == 'holiday'
                      ? Icons.beach_access_rounded
                      : type == 'result'
                          ? Icons.bar_chart_rounded
                          : Icons.event_note_rounded;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (e['text'] ?? 'Event').toString(),
                        style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      (e['date'] ?? 'TBA').toString(),
                      style: AppTypography.bodySm.copyWith(color: color, fontWeight: FontWeight.bold),
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
}
