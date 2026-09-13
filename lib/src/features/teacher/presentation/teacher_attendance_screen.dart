import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/navigation/back_handler.dart';

/// Attendance "host" screen for teacher/branch_admin/super_admin. Replaces
/// the old raw BLE MAC-address scan, which could never actually work —
/// Android has blocked apps from reading their own device's real
/// Bluetooth MAC since Android 6, so students.ble_mac_address could never
/// be legitimately populated, and nothing made a student's phone
/// advertise anything for that scan to find in the first place.
///
/// New design: this screen (host) creates a short-lived QR session via
/// create_attendance_session (migration 20240301000015), scoped to the
/// teacher's course / the admin's branch / open, and displays the QR.
/// The student's app (agent, see student_checkin_screen.dart) scans it
/// and reports an optional BLE ambient reading as a supplementary
/// proximity signal — QR is the authoritative signal, BLE only adjusts a
/// confidence score server-side, it never gates the check-in.
class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  final Map<int, String> _attendanceMap = {}; // id -> 'P', 'A'
  bool _showManualList = false;

  // Course picker (teacher only — branch_admin/super_admin sessions are
  // scoped to their branch / open, no picker needed).
  List<MapEntry<int, String>> _courseOptions = [];
  int? _selectedCourseId;

  // Active hosted session state.
  Map<String, dynamic>? _activeSession;
  Timer? _expiryTimer;
  Timer? _rosterPollTimer;
  int _secondsRemaining = 0;
  List<Map<String, dynamic>> _checkedIn = [];
  bool _isStartingSession = false;

  // Whatever handler (RoleShell's, typically) was active before this screen
  // took over — restored on dispose so back-button behavior elsewhere is
  // unaffected by this screen ever having existed.
  Future<bool> Function()? _previousBackHandler;

  @override
  void initState() {
    super.initState();
    _fetchStudents();

    // RoleShell's own handler only pops a *pushed* GoRouter route; this
    // screen's "manual mode" is local widget state, not a route, and
    // teachers reach this screen via context.go() (no route to pop) — so
    // without registering our own handler here, a system back press skips
    // straight to RoleShell's "go to home tab" fallback instead of first
    // collapsing manual mode back to the host/QR view.
    _previousBackHandler = BackHandler.instance.handler;
    BackHandler.instance.handler = _handleBack;
  }

  Future<bool> _handleBack() async {
    if (_showManualList) {
      setState(() => _showManualList = false);
      return true;
    }
    return _previousBackHandler?.call() ?? false;
  }

  @override
  void dispose() {
    // Only restore if we're still the active handler (guards against a
    // newer screen having already taken over, same pattern as RoleShell).
    if (BackHandler.instance.handler == _handleBack) {
      BackHandler.instance.handler = _previousBackHandler;
    }
    _expiryTimer?.cancel();
    _rosterPollTimer?.cancel();
    super.dispose();
  }

  String get _role => ref.read(userRoleProvider) ?? 'teacher';

  /// The manual-list roster, narrowed to the selected course for teachers
  /// (branch_admin/super_admin aren't course-scoped, so no filter for them).
  List<Map<String, dynamic>> get _visibleStudents {
    if (_role != 'teacher') return _students;
    // No course picked yet -> nothing to show, rather than silently
    // defaulting to every student across every course a teacher has.
    if (_selectedCourseId == null) return const [];
    return _students.where((s) => s['course_id'] == _selectedCourseId).toList();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      List<Map<String, dynamic>> list;
      if (_role == 'teacher') {
        // getStudentsForTeacher filters teacher_subjects.teacher_id, which
        // is a profiles(id) FK — the raw auth uid never matches it, so this
        // must be the resolved profile id from the session, not
        // supabase.auth.currentUser?.id.
        final profileId = ref.read(sessionProvider)?.profileId;
        list = (profileId == null || profileId.isEmpty)
            ? []
            : await repo.getStudentsForTeacher(profileId);
      } else {
        // branch_admin (own branch) / super_admin (all branches) — RLS on
        // students already scopes this correctly server-side.
        list = await repo.getStudents();
      }

      final courses = <int, String>{};
      for (final s in list) {
        final cid = s['course_id'] as int?;
        if (cid != null) {
          final courseJoin = s['courses'] as Map<String, dynamic>?;
          courses[cid] = (courseJoin?['name'] ?? courseJoin?['short_name'] ?? 'Course $cid')
              .toString();
        }
      }

      setState(() {
        _students = list;
        _courseOptions = courses.entries
            .map((e) => MapEntry(e.key, e.value))
            .toList();
        // Only auto-pick when there's truly no choice to make (the course
        // dropdown itself is hidden below _courseOptions.length <= 1) —
        // with more than one course, don't silently default to the first
        // one, a teacher could easily mark attendance for the wrong course
        // without realizing it. Require an explicit pick in that case.
        _selectedCourseId = _courseOptions.length == 1 ? _courseOptions.first.key : null;
        for (final s in _students) {
          _attendanceMap[s['id']] = 'A';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _startSession() async {
    setState(() => _isStartingSession = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      late final Map<String, dynamic> result;

      if (_role == 'teacher') {
        if (_selectedCourseId == null) {
          throw Exception(
            _courseOptions.isEmpty
                ? 'No course found for your account — cannot scope a session.'
                : 'Please select a course first.',
          );
        }
        result = await service.createAttendanceSession(
          scopeType: 'course',
          courseId: _selectedCourseId,
        );
      } else if (_role == 'branch_admin') {
        result = await service.createAttendanceSession(scopeType: 'branch');
      } else {
        // super_admin: open session, not tied to one branch/course.
        result = await service.createAttendanceSession(
          scopeType: 'classroom_ble',
        );
      }

      if (result['success'] != true) {
        throw Exception(result['reason'] ?? 'Could not start session');
      }

      final expiresAt = DateTime.parse(result['expires_at'] as String);
      setState(() {
        _activeSession = {
          'session_id': result['session_id'],
          'qr_nonce': result['qr_nonce'],
          'expires_at': expiresAt,
        };
        _checkedIn = [];
        _secondsRemaining = expiresAt
            .difference(DateTime.now().toUtc())
            .inSeconds
            .clamp(0, 100000);
      });

      _expiryTimer?.cancel();
      _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = expiresAt
            .difference(DateTime.now().toUtc())
            .inSeconds;
        if (remaining <= 0) {
          _endSession(auto: true);
        } else {
          setState(() => _secondsRemaining = remaining);
        }
      });

      _rosterPollTimer?.cancel();
      _rosterPollTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _pollCheckedIn(),
      );
      _pollCheckedIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingSession = false);
    }
  }

  Future<void> _pollCheckedIn() async {
    final sessionId = _activeSession?['session_id'];
    if (sessionId == null) return;
    try {
      final rows = await supabase
          .from('attendance_events')
          .select('student_id, marked_at, students(name, reg_no, photo_url)')
          .eq('qr_session_id', sessionId)
          .eq('status', 'present')
          .order('marked_at', ascending: false);
      if (mounted) {
        setState(() => _checkedIn = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {
      // Non-fatal — the host can still see the roster refresh on the next tick.
    }
  }

  Future<void> _endSession({bool auto = false}) async {
    final sessionId = _activeSession?['session_id'];
    _expiryTimer?.cancel();
    _rosterPollTimer?.cancel();
    if (sessionId != null) {
      try {
        await ref.read(supabaseServiceProvider).endAttendanceSession(sessionId);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _activeSession = null);
    if (!auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session ended.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final s in _visibleStudents) {
        _attendanceMap[s['id']] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final dateOnly =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // student_attendance's status CHECK constraint only allows the
      // single-letter codes ('P','A','L','H') already used by
      // _attendanceMap — no need to translate to full words. It also has
      // no marked_at/course_id columns at all, and marked_by references
      // profiles(id), not the raw auth uid.
      final markedBy = ref.read(sessionProvider)?.profileId;

      for (final student in _visibleStudents) {
        final id = student['id'];
        final statusCode = _attendanceMap[id] ?? 'A';

        await supabase.from('student_attendance').upsert({
          'student_id': id,
          'branch_id': student['branch_id'],
          'attendance_date': dateOnly,
          'status': statusCode,
          'marked_by': markedBy,
        }, onConflict: 'student_id,attendance_date');
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // This screen is reached via context.go() from the teacher
        // dashboard (which replaces the route, leaving nothing to pop back
        // to) but via context.push() from admin/super-admin — popping
        // unconditionally left teachers on a blank black screen since
        // there was nothing underneath. Only pop when there's actually
        // something to return to; otherwise just close the manual list.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          setState(() => _showManualList = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Manual mode is a local toggle on this same screen, not a pushed
        // route — Navigator has nothing to pop back to when this screen was
        // reached via context.go() (the teacher dashboard's entry point),
        // so there was previously no way back out of the manual list at
        // all. Always show an explicit back action here instead of relying
        // on Flutter's auto-back (which needs Navigator.canPop()).
        leading: _showManualList
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _showManualList = false),
              )
            : null,
        automaticallyImplyLeading: !_showManualList,
        title: const Text(
          'Mark Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.inkNavy900,
        actions: [
          IconButton(
            onPressed: _fetchStudents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showManualList) Expanded(child: _buildHostUI()),
          if (_showManualList) ...[
            _buildQuickActionHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.success,
                      ),
                    )
                  : _buildStudentList(),
            ),
            _buildBottomAction(),
          ],
        ],
      ),
    );
  }

  Widget _buildHostUI() {
    if (_activeSession != null) return _buildActiveSessionUI();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              size: 100,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Host Attendance Session',
              style: AppTypography.headingLg.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _role == 'teacher'
                  ? 'Students scan the QR to check in for your course.'
                  : 'Students scan the QR to check in. BLE proximity adds a confidence signal.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.textMuted),
            ),
            if (_role == 'teacher' && _courseOptions.length > 1) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DropdownButton<int>(
                  value: _selectedCourseId,
                  isExpanded: true,
                  dropdownColor: AppColors.inkNavy800,
                  hint: const Text('Select Course', style: TextStyle(color: AppColors.textMuted)),
                  items: _courseOptions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCourseId = v),
                ),
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldCta,
                  foregroundColor: AppColors.inkNavy900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isStartingSession ? null : _startSession,
                icon: _isStartingSession
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.inkNavy900,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  _isStartingSession ? 'Starting…' : 'Start Session',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _showManualList = true),
              icon: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                'Mark Attendance Manually',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionUI() {
    final sessionId = _activeSession!['session_id'] as String;
    final nonce = _activeSession!['qr_nonce'] as String;
    final qrPayload = '{"session_id":"$sessionId","nonce":"$nonce"}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Expires in ${_secondsRemaining}s',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.goldCta,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Checked in (${_checkedIn.length})',
              style: AppTypography.headingSm.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_checkedIn.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No one has checked in yet.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ..._checkedIn.map((row) {
              final student = row['students'] as Map<String, dynamic>? ?? {};
              return ListTile(
                leading: Builder(
                  builder: (context) {
                    final avatar = resolveAvatarProvider(student['photo_url']);
                    return CircleAvatar(
                      backgroundColor: AppColors.inkNavy700,
                      backgroundImage: avatar,
                    );
                  },
                ),
                title: Text(
                  student['name'] ?? 'Unknown',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  student['reg_no'] ?? '',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _endSession(),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy900,
        border: const Border(bottom: BorderSide(color: AppColors.divider10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_role == 'teacher' && _courseOptions.length > 1) ...[
            DropdownButton<int>(
              value: _selectedCourseId,
              isExpanded: true,
              dropdownColor: AppColors.inkNavy800,
              hint: const Text('Select Course', style: TextStyle(color: AppColors.textMuted)),
              items: _courseOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  label: 'Mark All Present',
                  color: AppColors.success,
                  icon: Icons.done_all_rounded,
                  onTap: () => _markAll('P'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickBtn(
                  label: 'Mark All Absent',
                  color: AppColors.danger,
                  icon: Icons.close_rounded,
                  onTap: () => _markAll('A'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final visible = _visibleStudents;
    if (visible.isEmpty) {
      final message = (_role == 'teacher' && _selectedCourseId == null && _courseOptions.length > 1)
          ? 'Select a course above to see its students.'
          : 'No students found.';
      return Center(
        child: Text(message, style: AppTypography.bodyLg),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final student = visible[index];
        final id = student['id'];
        final status = _attendanceMap[id] ?? 'A';

        return _AttendanceTile(
          name: student['name'] ?? 'Unknown',
          reg: student['reg_no'] ?? 'N/A',
          photo: student['photo_url'],
          status: status,
          onStatusChanged: (newStatus) {
            setState(() => _attendanceMap[id] = newStatus);
          },
        );
      },
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.inkNavy800,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isLoading ? null : _saveAttendance,
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.textPrimary)
            : const Text(
                'SUBMIT ATTENDANCE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.name,
    required this.reg,
    this.photo,
    required this.status,
    required this.onStatusChanged,
  });

  final String name, reg;
  final String? photo;
  final String status;
  final void Function(String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final avatar = resolveAvatarProvider(photo);
              return CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.inkNavy700,
                backgroundImage: avatar,
                onBackgroundImageError: avatar != null ? (_, __) {} : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0] : 'S',
                        style: const TextStyle(color: AppColors.goldCta),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reg,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _StatusSelector(currentStatus: status, onSelected: onStatusChanged),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.currentStatus,
    required this.onSelected,
  });
  final String currentStatus;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChoice('P', AppColors.success),
        const SizedBox(width: 8),
        _buildChoice('A', AppColors.danger),
      ],
    );
  }

  Widget _buildChoice(String label, Color color) {
    final isSelected = currentStatus == label;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : AppColors.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
