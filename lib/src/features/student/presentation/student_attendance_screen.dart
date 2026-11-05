import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/student/presentation/student_checkin_screen.dart';
import 'package:intl/intl.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  late DateTime _selectedMonth;
  DateTime? _selectedDate; // Specific date clicked in the calendar
  String _statusFilter = 'all'; // 'all', 'present', 'absent', 'late'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _selectedDate = null;
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = null;
    });
  }

  DateTime? _parseDate(dynamic d) {
    if (d == null) return null;
    if (d is DateTime) return d;
    try {
      return DateTime.tryParse(d.toString());
    } catch (_) {
      return null;
    }
  }

  String _normalizeStatus(dynamic s) {
    final st = (s ?? '').toString().toLowerCase().trim();
    if (st == 'present' || st == 'p') return 'present';
    if (st == 'late' || st == 'l') return 'late';
    if (st == 'absent' || st == 'a') return 'absent';
    if (st == 'holiday' || st == 'h') return 'holiday';
    return st.isEmpty ? 'unknown' : st;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(studentAttendanceProvider);
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        title: const Text(
          'My Attendance',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (!isCurrentMonth)
            TextButton.icon(
              onPressed: _goToCurrentMonth,
              icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.goldCta),
              label: const Text(
                'Today',
                style: TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: attendanceAsync.when(
        data: (records) {
          // Map records by DateTime (normalized to YYYY-MM-DD)
          final recordsByDay = <String, Map<String, dynamic>>{};
          final recordsInSelectedMonth = <Map<String, dynamic>>[];

          for (final r in records) {
            final dt = _parseDate(r['date']);
            if (dt != null) {
              final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              recordsByDay[key] = r;

              if (dt.year == _selectedMonth.year && dt.month == _selectedMonth.month) {
                recordsInSelectedMonth.add(r);
              }
            }
          }

          // Sort month records descending by date
          recordsInSelectedMonth.sort((a, b) {
            final da = _parseDate(a['date']) ?? DateTime(1970);
            final db = _parseDate(b['date']) ?? DateTime(1970);
            return db.compareTo(da);
          });

          // Compute monthly stats
          int monthPresent = 0;
          int monthAbsent = 0;
          int monthLate = 0;
          for (final r in recordsInSelectedMonth) {
            final st = _normalizeStatus(r['status']);
            if (st == 'present') {
              monthPresent++;
            } else if (st == 'absent') {
              monthAbsent++;
            } else if (st == 'late') {
              monthLate++;
            }
          }
          final monthTotal = recordsInSelectedMonth.length;
          final monthPct = monthTotal == 0 ? 0 : (((monthPresent + monthLate) / monthTotal) * 100).round();

          // Filter records list by selected day or status
          List<Map<String, dynamic>> displayedRecords = recordsInSelectedMonth;
          if (_selectedDate != null) {
            displayedRecords = displayedRecords.where((r) {
              final dt = _parseDate(r['date']);
              return dt != null &&
                  dt.year == _selectedDate!.year &&
                  dt.month == _selectedDate!.month &&
                  dt.day == _selectedDate!.day;
            }).toList();
          } else if (_statusFilter != 'all') {
            displayedRecords = displayedRecords.where((r) {
              return _normalizeStatus(r['status']) == _statusFilter;
            }).toList();
          }

          return RefreshIndicator(
            color: AppColors.goldCta,
            backgroundColor: AppColors.inkNavy800,
            onRefresh: () => ref.refresh(studentAttendanceProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // ── Month Selector Header ──
                _buildMonthSelector(),
                const SizedBox(height: 12),

                // ── Monthly Metric Banner ──
                _buildMonthlyMetricCard(
                  pct: monthPct,
                  present: monthPresent,
                  absent: monthAbsent,
                  lateCount: monthLate,
                  total: monthTotal,
                ),
                const SizedBox(height: 16),

                // ── Interactive Calendar Matrix ──
                _buildCalendarCard(recordsByDay),
                const SizedBox(height: 20),

                // ── Daily Activity Log Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? 'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}'
                          : 'Daily Logs (${DateFormat('MMMM yyyy').format(_selectedMonth)})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedDate != null || _statusFilter != 'all')
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => setState(() {
                          _selectedDate = null;
                          _statusFilter = 'all';
                        }),
                        icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.goldCta),
                        label: const Text('Show All Month', style: TextStyle(color: AppColors.goldCta, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Daily Activity Records List ──
                if (displayedRecords.isEmpty)
                  _buildNoRecordsForSelection()
                else
                  ...displayedRecords.map((r) => _buildDayLogCard(r)),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Unable to load attendance: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.refresh(studentAttendanceProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const StudentCheckinScreen()),
          );
        },
        backgroundColor: AppColors.goldCta,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.inkNavy900),
        label: const Text(
          'Scan Attendance',
          style: TextStyle(color: AppColors.inkNavy900, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Month Selector Bar ──
  Widget _buildMonthSelector() {
    final title = DateFormat('MMMM yyyy').format(_selectedMonth);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: _prevMonth,
            tooltip: 'Previous Month',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.goldCta, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: _nextMonth,
            tooltip: 'Next Month',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Monthly Metric Card ──
  Widget _buildMonthlyMetricCard({
    required int pct,
    required int present,
    required int absent,
    required int lateCount,
    required int total,
  }) {
    final pctColor = pct >= 75 ? Colors.greenAccent : (pct >= 50 ? Colors.amberAccent : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.inkNavy800,
            AppColors.inkNavy700.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Percentage Ring / Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: total == 0 ? 0 : (pct / 100),
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: pctColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Attendance Rate',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total == 0
                          ? 'No marked sessions this month'
                          : '$total session${total == 1 ? "" : "s"} evaluated • Requirement: 75%',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Clickable Metric Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatPill('Present', '$present', Colors.greenAccent, 'present'),
              _buildStatPill('Absent', '$absent', Colors.redAccent, 'absent'),
              _buildStatPill('Late', '$lateCount', Colors.orangeAccent, 'late'),
              _buildStatPill('Total', '$total', AppColors.goldCta, 'all'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color, String filterKey) {
    final isFilterActive = _statusFilter == filterKey && _selectedDate == null;
    return InkWell(
      onTap: () => setState(() {
        _statusFilter = _statusFilter == filterKey ? 'all' : filterKey;
        _selectedDate = null;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFilterActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilterActive ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Month Calendar Matrix ──
  Widget _buildCalendarCard(Map<String, Map<String, dynamic>> recordsByDay) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    // Number of days in this month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Weekday of the 1st of this month (1 = Mon, 7 = Sun)
    final firstWeekday = DateTime(year, month, 1).weekday; // 1..7

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Weekday header labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              final isWeekend = w == 'S';
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      color: isWeekend ? AppColors.goldCta.withValues(alpha: 0.7) : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // Calendar Grid (7 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (firstWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink(); // Empty slot before 1st of month
              }

              final dayNum = index - (firstWeekday - 1) + 1;
              final cellDate = DateTime(year, month, dayNum);
              final dateKey = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
              final record = recordsByDay[dateKey];

              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final isSelected = _selectedDate != null &&
                  cellDate.year == _selectedDate!.year &&
                  cellDate.month == _selectedDate!.month &&
                  cellDate.day == _selectedDate!.day;

              final status = record != null ? _normalizeStatus(record['status']) : null;
              final isPresent = status == 'present';
              final isLate = status == 'late';
              final isAbsent = status == 'absent';
              final isSunday = cellDate.weekday == DateTime.sunday;

              Color? dotColor;
              Color cellBg = Colors.transparent;
              if (isPresent) {
                dotColor = Colors.greenAccent;
                cellBg = Colors.green.withValues(alpha: 0.15);
              } else if (isLate) {
                dotColor = Colors.orangeAccent;
                cellBg = Colors.orange.withValues(alpha: 0.15);
              } else if (isAbsent) {
                dotColor = Colors.redAccent;
                cellBg = Colors.red.withValues(alpha: 0.15);
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = cellDate;
                      _statusFilter = 'all';
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldCta.withValues(alpha: 0.25)
                        : cellBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldCta
                          : (isToday ? AppColors.goldCta.withValues(alpha: 0.5) : Colors.transparent),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.goldCta
                              : (isSunday ? AppColors.textMuted : AppColors.textPrimary),
                          fontWeight: (isToday || isSelected || record != null) ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (dotColor != null)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.greenAccent, 'Present'),
              const SizedBox(width: 14),
              _buildLegendDot(Colors.redAccent, 'Absent'),
              const SizedBox(width: 14),
              _buildLegendDot(Colors.orangeAccent, 'Late'),
              const SizedBox(width: 14),
              _buildLegendDot(AppColors.textMuted, 'Unmarked'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  // ── Daily Attendance Log Card ──
  Widget _buildDayLogCard(Map<String, dynamic> record) {
    final status = _normalizeStatus(record['status']);
    final isPresent = status == 'present';
    final isLate = status == 'late';
    final isAbsent = status == 'absent';

    final Color statusColor = isPresent
        ? Colors.green
        : (isLate ? Colors.orange : (isAbsent ? Colors.red : Colors.grey));
    final String statusLabel = isPresent
        ? 'Present'
        : (isLate ? 'Late Check-in' : (isAbsent ? 'Absent' : status.toUpperCase()));

    final date = _parseDate(record['date']);
    final formattedDate = date != null ? DateFormat('EEEE, dd MMM yyyy').format(date) : (record['date']?.toString() ?? 'N/A');
    final remarks = record['remarks'] ?? record['notes'] ?? record['type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Date icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent
                  ? Icons.check_circle_rounded
                  : (isLate ? Icons.schedule_rounded : Icons.cancel_rounded),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Date & Remarks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remarks != null && remarks.toString().trim().isNotEmpty
                      ? remarks.toString()
                      : (isPresent ? 'Regular session marked' : (isLate ? 'Marked late for class' : 'No attendance recorded')),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordsForSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text(
              _selectedDate != null
                  ? 'No attendance record for ${DateFormat('dd MMM yyyy').format(_selectedDate!)}'
                  : 'No attendance records in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
