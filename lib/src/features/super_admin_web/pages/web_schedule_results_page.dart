import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';
import 'package:gokul_shree_app/src/features/exams/presentation/admin_schedule_results_screen.dart' show ScheduleRosterScreen;
import '../web_shell.dart' show WebLegacyFrame;
import '../widgets/web_ui.dart';

typedef _Row = Map<String, dynamic>;

final _schedulesProvider = FutureProvider<List<_Row>>((ref) => ref.watch(examRepositoryProvider).getSchedulesForAdmin());

class WebScheduleResultsPage extends ConsumerWidget {
  const WebScheduleResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(_schedulesProvider);

    return WebPage(
      title: 'Published results',
      subtitle: 'Scheduled tests and exams — open one to see who attempted it',
      fill: true,
      actions: [
        OutlinedButton.icon(
          style: webSecondaryButton(),
          onPressed: () => ref.invalidate(_schedulesProvider),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          style: webPrimaryButton(),
          onPressed: () => context.go('/super-admin/exam-scheduler'),
          icon: const Icon(Icons.add_task_rounded, size: 18),
          label: const Text('Schedule new'),
        ),
      ],
      child: schedules.when(
        loading: () => webLoading,
        error: (e, _) => WebError(e, onRetry: () => ref.invalidate(_schedulesProvider)),
        data: (rows) => WebTable<_Row>(
          columns: const [WebColumn('Title', flex: 3), WebColumn('Type'), WebColumn('Starts')],
          rows: rows,
          keyOf: (s) => s['id'] as Object,
          onRowTap: (s) {
            final paper = s['paper_sets'] as Map<String, dynamic>? ?? {};
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebLegacyFrame(
                  maxWidth: 900,
                  child: ScheduleRosterScreen(scheduleId: s['id'] as int, title: str(s['title'] ?? paper['title'], 'Schedule')),
                ),
              ),
            );
          },
          emptyTitle: 'No exam schedules yet',
          emptyMessage: 'When exams or tests are scheduled, rosters and results will appear here.',
          cells: (s) {
            final paper = s['paper_sets'] as Map<String, dynamic>? ?? {};
            final isTest = paper['assessment_type'] == 'test';
            final startAt = DateTime.tryParse(str(s['start_at'], ''));
            return [
              CellText(str(s['title'] ?? paper['title'], 'Untitled')),
              StatusChip(isTest ? 'Test' : 'Exam', isTest ? AppColors.primaryViolet : AppColors.goldDeep),
              PlainCell(startAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(startAt) : 'No start date', muted: true),
            ];
          },
        ),
      ),
    );
  }
}
