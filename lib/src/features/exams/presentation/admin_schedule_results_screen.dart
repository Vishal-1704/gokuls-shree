import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/exams/data/exam_repository.dart';

/// Super Admin / Branch Admin: list of scheduled tests & exams. Tap one to
/// see who attempted, who's still in progress, and who never showed up.
class AdminScheduleResultsScreen extends ConsumerStatefulWidget {
  const AdminScheduleResultsScreen({super.key});

  @override
  ConsumerState<AdminScheduleResultsScreen> createState() => _AdminScheduleResultsScreenState();
}

class _AdminScheduleResultsScreenState extends ConsumerState<AdminScheduleResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await ref.read(examRepositoryProvider).getSchedulesForAdmin();
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: const Text('Test / Exam Results', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : _schedules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.goldCta.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fact_check_outlined, size: 48, color: AppColors.goldCta),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Exam Schedules Yet',
                          style: AppTypography.headingSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When exams or tests are scheduled for your branch, student rosters and results will appear here.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/admin/exam-scheduler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: const Text('Schedule New Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.goldCta,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = _schedules[i];
                      final paper = s['paper_sets'] as Map<String, dynamic>? ?? {};
                      final isTest = paper['assessment_type'] == 'test';
                      final startAt = DateTime.tryParse((s['start_at'] ?? '').toString());

                      return Material(
                        color: AppColors.inkNavy800,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleRosterScreen(
                                scheduleId: s['id'] as int,
                                title: s['title'] ?? paper['title'] ?? 'Schedule',
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isTest ? Colors.purple : AppColors.goldCta).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.fact_check_outlined, color: isTest ? Colors.purple : AppColors.goldCta),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['title'] ?? paper['title'] ?? 'Untitled',
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        startAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(startAt) : 'No start date',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Roster vs attempts for one schedule: submitted / started-not-submitted /
/// absent, plus a "Publish Results" action that pushes scores into the
/// student-facing marksheet (exam_results).
class ScheduleRosterScreen extends ConsumerStatefulWidget {
  final int scheduleId;
  final String title;

  const ScheduleRosterScreen({super.key, required this.scheduleId, required this.title});

  @override
  ConsumerState<ScheduleRosterScreen> createState() => _ScheduleRosterScreenState();
}

class _ScheduleRosterScreenState extends ConsumerState<ScheduleRosterScreen> {
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isRefreshingRoster = false;
  List<Map<String, dynamic>> _roster = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final roster = await ref.read(examRepositoryProvider).getScheduleRoster(widget.scheduleId);
      setState(() {
        _roster = roster;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load roster: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  /// Re-materializes the roster so students who enrolled into the assigned
  /// course/batch/branch after this schedule was first created show up —
  /// otherwise they'd never appear in the roster (and so never show as
  /// "absent"), and never see the exam in their own list either.
  Future<void> _refreshRoster() async {
    setState(() => _isRefreshingRoster = true);
    try {
      await ref.read(examRepositoryProvider).refreshScheduleRoster(widget.scheduleId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roster refreshed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingRoster = false);
    }
  }

  Future<void> _publish() async {
    final absentCount = _roster.where((r) => r['state'] == 'absent').length;
    bool markAbsentees = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.inkNavy800,
          title: const Text('Publish Results?', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This pushes every submitted score into the student marksheet, visible in their "My Results" screen.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (absentCount > 0) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markAbsentees,
                  activeColor: AppColors.goldCta,
                  title: Text('Mark $absentCount absent student(s) as "AB"',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  onChanged: (v) => setDialogState(() => markAbsentees = v ?? false),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldCta, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isPublishing = true);
    try {
      final count = await ref
          .read(examRepositoryProvider)
          .publishScheduleResults(widget.scheduleId, markAbsentees: markAbsentees);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Published $count result(s)'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish failed: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _roster.where((r) => r['state'] == 'submitted').toList();
    final started = _roster.where((r) => r['state'] == 'started').toList();
    final absent = _roster.where((r) => r['state'] == 'absent').toList();

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: _isRefreshingRoster
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                : const Icon(Icons.group_add_outlined, color: AppColors.textSecondary),
            tooltip: 'Refresh roster (pick up newly enrolled students)',
            onPressed: _isRefreshingRoster ? null : _refreshRoster,
          ),
        ],
      ),
      floatingActionButton: submitted.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isPublishing ? null : _publish,
              backgroundColor: AppColors.goldCta,
              foregroundColor: Colors.black,
              icon: _isPublishing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_rounded),
              label: Text(_isPublishing ? 'Publishing...' : 'Publish Results'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.goldCta,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    children: [
                      _SummaryChip(label: 'Roster', value: _roster.length, color: AppColors.info),
                      const SizedBox(width: 8),
                      _SummaryChip(label: 'Submitted', value: submitted.length, color: Colors.green),
                      const SizedBox(width: 8),
                      _SummaryChip(label: 'Started', value: started.length, color: Colors.orange),
                      const SizedBox(width: 8),
                      _SummaryChip(label: 'Absent', value: absent.length, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (submitted.isNotEmpty) _SectionHeader('Submitted (${submitted.length})'),
                  ...submitted.map((r) => _StudentRow(row: r)),
                  if (started.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader('Started, not submitted (${started.length})'),
                    ...started.map((r) => _StudentRow(row: r)),
                  ],
                  if (absent.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader('Absent (${absent.length})'),
                    ...absent.map((r) => _StudentRow(row: r)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _StudentRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final state = row['state'] as String;
    final score = row['score'];
    final total = row['total_marks'];
    final result = row['result'] as String?;
    final autoSubmitReason = row['auto_submit_reason'] as String?;

    Widget trailing;
    if (state == 'submitted') {
      final passed = result == 'pass';
      trailing = Text(
        '$score/$total',
        style: TextStyle(color: passed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
      );
    } else if (state == 'started') {
      trailing = const Text('In progress', style: TextStyle(color: Colors.orange, fontSize: 12));
    } else {
      trailing = const Text('Absent', style: TextStyle(color: Colors.red, fontSize: 12));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.inkNavy800, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(row['name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    if (autoSubmitReason != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Auto-submitted: $autoSubmitReason',
                        child: const Icon(Icons.flag_rounded, size: 14, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
                Text(row['reg_no'] ?? '-', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
