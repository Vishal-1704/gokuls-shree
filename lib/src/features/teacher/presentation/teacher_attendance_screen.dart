import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';


class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  final Map<int, String> _attendanceMap = {}; // id -> 'P', 'A'
  
  bool _isScanning = false;
  int _scanCount = 0;
  bool _showManualList = false;
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanTimer;
  int _scanTimeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final profileId = supabase.auth.currentUser?.id;
      if (profileId != null) {
        // Fetch only students enrolled in this teacher's subjects
        final list = await repo.getStudentsForTeacher(profileId);
        setState(() {
          _students = list;
          // Initialize all as Absent by default (Smart roll call marks them Present)
          for (var s in _students) {
            _attendanceMap[s['id']] = 'A';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _startBleScan() async {
    // Request Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth & Location permissions are required for Smart Roll Call'), backgroundColor: AppColors.danger),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanTimeRemaining = 30;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    } catch (e) {
      debugPrint("Scan Error: $e");
    }

    _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_scanTimeRemaining > 0) {
          _scanTimeRemaining--;
        } else {
          _stopBleScan();
        }
      });
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final macAddress = r.device.remoteId.str.toLowerCase();
        
        // Find if any student matches this MAC
        for (var student in _students) {
          final studentMac = (student['ble_mac_address']?.toString() ?? '').toLowerCase();
          if (studentMac.isNotEmpty && studentMac == macAddress) {
            // Found a match! Mark them present
            setState(() {
              _attendanceMap[student['id']] = 'P';
            });
          }
        }
      }
    });
  }

  void _stopBleScan() {
    FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    
    setState(() {
      _isScanning = false;
      _scanCount++;
    });
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Smart Roll Call session ended.'), backgroundColor: AppColors.success),
       );
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var s in _students) {
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

      for (final student in _students) {
        final id = student['id'];
        final statusCode = _attendanceMap[id] ?? 'A';
        final status = statusCode == 'A'
            ? 'absent'
            : 'present';

        await supabase.from('student_attendance').upsert({
          'student_id': id,
          'attendance_date': dateOnly,
          'status': status,
          'marked_at': DateTime.now().toIso8601String(),
          'marked_by': supabase.auth.currentUser?.id,
          'course_id': student['course'],
        }, onConflict: 'student_id,attendance_date');
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (!_showManualList) _buildSmartRollCallUI(),
          if (_showManualList) ...[
            _buildQuickActionHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.success))
                  : _buildStudentList(),
            ),
            _buildBottomAction(),
          ]
        ],
      ),
    );
  }

  Widget _buildSmartRollCallUI() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching_rounded, 
                size: 100, 
                color: _isScanning ? AppColors.goldCta : AppColors.textMuted
              ),
              const SizedBox(height: 24),
              Text(
                'Smart Roll Call',
                style: AppTypography.headingLg.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _isScanning 
                  ? 'Scanning for students... ($_scanTimeRemaining s)\nAutomatically marking them present.'
                  : 'Tap below to start a 30-second Bluetooth scan for nearby students.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: AppColors.inkNavy900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isScanning ? null : _startBleScan,
                  icon: _isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.inkNavy900))
                    : const Icon(Icons.radar_rounded, size: 24),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Attendance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              // Manual fallback unlock logic
              if (_scanCount >= 2 && !_isScanning)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showManualList = true;
                    });
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.textPrimary),
                  label: const Text('Mark Attendance Manually', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ),
              if (_scanCount < 2 && _scanCount > 0 && !_isScanning)
                const Text('Run scan one more time to unlock manual override', style: TextStyle(color: AppColors.warning, fontSize: 12)),
            ],
          ),
        ),
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
      child: Row(
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
    );
  }

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return Center(child: Text('No students found in your subjects.', style: AppTypography.bodyLg));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final id = student['id'];
        final status = _attendanceMap[id] ?? 'A';

        // Use correct DB columns: reg_no, contact (instead of phone)
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : _saveAttendance,
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.textPrimary)
            : const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label; final Color color; final IconData icon; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
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
        border: Border.all(color: AppColors.divider.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.inkNavy700,
            backgroundImage: photo != null ? NetworkImage(photo!) : null,
            child: photo == null ? Text(name[0], style: const TextStyle(color: AppColors.goldCta)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                Text(reg, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
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
  const _StatusSelector({required this.currentStatus, required this.onSelected});
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
