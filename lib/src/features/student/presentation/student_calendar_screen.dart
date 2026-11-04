import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:intl/intl.dart';

class StudentCalendarScreen extends ConsumerStatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  ConsumerState<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends ConsumerState<StudentCalendarScreen> {
  String _filter = 'all'; // 'all', 'exam', 'holiday', 'event'

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(studentAcademicCalendarProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Academic Calendar',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading calendar: $e',
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (events) {
          final totalCount = events.length;
          final holidaysCount = events.where((e) => (e['type'] ?? '').toString().toLowerCase() == 'holiday').length;
          final examCount = events.where((e) {
            final t = (e['type'] ?? '').toString().toLowerCase();
            return t == 'exam' || t == 'test';
          }).length;
          final eventsCount = totalCount - holidaysCount - examCount;

          final filtered = events.where((e) {
            if (_filter == 'all') return true;
            final t = (e['type'] ?? '').toString().toLowerCase();
            if (_filter == 'exam') return t == 'exam' || t == 'test';
            if (_filter == 'holiday') return t == 'holiday';
            if (_filter == 'event') return t != 'holiday' && t != 'exam' && t != 'test';
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentAcademicCalendarProvider),
            color: AppColors.goldCta,
            backgroundColor: AppColors.inkNavy800,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.goldCta.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.goldCta, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Academic Year ${DateTime.now().year}',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.goldCta,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gazetted Holidays, Scheduled Tests & Official Events',
                              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All ($totalCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('holiday', 'Holidays ($holidaysCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('exam', 'Tests & Exams ($examCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('event', 'Notices & Events ($eventsCount)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No events in this category',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...filtered.map((e) {
                    final type = (e['type'] ?? 'event').toString().toLowerCase();
                    final isHoliday = type == 'holiday';
                    final isExam = type == 'exam' || type == 'test';

                    final color = isHoliday
                        ? const Color(0xFFF59E0B) // Amber
                        : isExam
                            ? AppColors.primaryViolet
                            : AppColors.info;

                    final icon = isHoliday
                        ? Icons.celebration_rounded
                        : isExam
                            ? Icons.edit_calendar_rounded
                            : Icons.campaign_rounded;

                    final badgeText = isHoliday
                        ? 'HOLIDAY'
                        : isExam
                            ? (type == 'test' ? 'TEST' : 'EXAM')
                            : 'EVENT';

                    final dt = e['dateTime'] as DateTime?;
                    final dayStr = dt != null ? dt.day.toString().padLeft(2, '0') : '--';
                    final monthStr = dt != null ? DateFormat('MMM').format(dt).toUpperCase() : 'TBA';
                    final fullDateStr = (e['date'] ?? 'TBA').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.inkNavy800,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          // Calendar Day Badge
                          Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  monthStr,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dayStr,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Event Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (e['text'] ?? 'Event').toString(),
                                        style: AppTypography.bodyLg.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(icon, size: 12, color: color),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        (e['description'] ?? fullDateStr).toString(),
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Badge pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCta : AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldCta : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
