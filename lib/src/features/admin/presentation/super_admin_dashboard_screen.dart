// lib/src/features/admin/presentation/super_admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'super_admin_reset_password_screen.dart'; // New screen

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A2E),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${session?.name ?? 'Super Admin'} 🔐',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Super Admin · Full Access', style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Colors.white70),
            onPressed: () => context.push('/super-admin/approvals'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // System stats — live pending counts
          FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: ref.read(adminRepositoryProvider).getPendingDocuments(),
            builder: (context, docSnap) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(adminRepositoryProvider).getPendingStudents(),
                builder: (context, studentSnap) {
                  final pendingDocs =
                      (docSnap.data?['marksheets']?.length ?? 0) +
                      (docSnap.data?['certificates']?.length ?? 0);
                  final pendingStudents = studentSnap.data?.length ?? 0;
                  final certs = docSnap.data?['certificates']?.length ?? 0;

                  return GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
                    children: [
                      _AdminStat('Pending Students', '$pendingStudents',
                          Icons.pending_actions_rounded, Colors.orange),
                      _AdminStat('Pending Docs', '$pendingDocs',
                          Icons.description_outlined, Colors.deepOrange),
                      const _AdminStat('Total Branches', '5',
                          Icons.account_balance_rounded, Colors.purple),
                      _AdminStat('Certificates', '$certs',
                          Icons.workspace_premium_rounded, Colors.green),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Super Admin Actions',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.verified_rounded,
            title: 'Pending Approvals',
            subtitle: 'Students, marksheets & certificates awaiting your approval',
            badge: '!',
            color: Colors.orange,
            onTap: () => context.push('/super-admin/approvals'),
          ),
          _ActionCard(
            icon: Icons.lock_reset_rounded,
            title: 'Reset User Password',
            subtitle: 'Reset password for any student, teacher, or admin (audit-logged)',
            color: Colors.red,
            onTap: () => context.push('/super-admin/reset-password'),
          ),
          _ActionCard(
            icon: Icons.quiz_rounded,
            title: 'Manage Exam Papers',
            subtitle: 'Create, update, and manage course exam question sets',
            color: Colors.amber,
            onTap: () => context.push('/super-admin/paper-manager'),
          ),
          _ActionCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Generate Certificates',
            subtitle: 'Issue course completion certificates',
            color: Colors.green,
            onTap: () => context.push('/admin/marksheet-generator'),
          ),
          _ActionCard(
            icon: Icons.account_balance_rounded,
            title: 'Manage Branches',
            subtitle: 'View and manage all franchise branches',
            color: Colors.blue,
            onTap: () => context.push('/super-admin/branches'),
          ),
          _ActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Full Reports',
            subtitle: 'Revenue, attendance, results across all branches',
            color: Colors.teal,
            onTap: () => context.push('/super-admin/reports'),
          ),
          _ActionCard(
            icon: Icons.add_circle_rounded,
            title: 'Add Student',
            subtitle: 'Manually enroll a new student (approved immediately)',
            color: Colors.cyan,
            onTap: () => context.push('/admin/add-student'),
          ),
          _ActionCard(
            icon: Icons.person_add_rounded,
            title: 'Register Branch Admin',
            subtitle: 'Onboard a new franchise administrator',
            color: Colors.pinkAccent,
            onTap: () => context.push('/admin/branch-registration'),
          ),
        ]),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat(this.label, this.value, this.icon, this.color);
  final String label, value; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: color, size: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.badge});
  final IconData icon; final String title, subtitle; final Color color;
  final VoidCallback onTap; final String? badge;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1A0A2E),
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: badge != null
          ? CircleAvatar(radius: 13, backgroundColor: Colors.orange,
              child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))
          : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    ),
  );
}
