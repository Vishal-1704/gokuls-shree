// lib/src/features/teacher/presentation/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/session_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A2010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2E18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${session?.name ?? 'Teacher'} 👋',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Teacher Portal', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_rounded, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            Row(children: [
              _StatCard('Students',  '42',  Icons.people_alt_rounded,    Colors.blue),
              const SizedBox(width: 12),
              _StatCard('Present Today', '38', Icons.check_circle_rounded, Colors.green),
              const SizedBox(width: 12),
              _StatCard('Absent',   '4',   Icons.cancel_rounded,        Colors.red),
            ]),
            const SizedBox(height: 24),
            const Text('Quick Actions',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.how_to_reg_rounded,
              title: 'Mark Attendance',
              subtitle: 'Mark today\'s student attendance',
              color: Colors.green,
              onTap: () => context.go('/teacher/attendance'),
            ),
            _ActionTile(
              icon: Icons.people_alt_rounded,
              title: 'View Students',
              subtitle: 'Browse students in your branch',
              color: Colors.blue,
              onTap: () => context.go('/teacher/students'),
            ),
            _ActionTile(
              icon: Icons.assignment_rounded,
              title: 'Upload Results',
              subtitle: 'Enter exam marks for students',
              color: Colors.orange,
              onTap: () => context.push('/admin/results-entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);
  final String label, value; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF112A16),
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
      onTap: onTap,
    ),
  );
}
