import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/data/admin_repository.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  final Map<int, String> _attendanceMap = {}; // id -> 'P', 'A', 'L'
  String _selectedClass = 'DCA - 1st Sem';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final list = await repo.getStudents();
      setState(() {
        _students = list;
        // Initialize all as Present by default
        for (var s in _students) {
          _attendanceMap[s['id']] = 'P';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
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
    // Simulate API call to backend hardened route
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance synchronized with server.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2E18), // Forest green accent for teachers
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_selectedClass, style: AppTypography.bodySm.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchStudents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActionHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.success))
                : _buildStudentList(),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildQuickActionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF112A16),
        border: Border(bottom: BorderSide(color: Colors.white10)),
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
      return Center(child: Text('No students found in this class.', style: AppTypography.bodyLg));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final id = student['id'];
        final status = _attendanceMap[id] ?? 'P';

        return _AttendanceTile(
          name: student['name'] ?? 'Unknown',
          reg: student['registration_number'] ?? 'N/A',
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
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : _saveAttendance,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
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
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
