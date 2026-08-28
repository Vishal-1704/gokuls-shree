import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/certificate_viewer_screen.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: ref.read(adminRepositoryProvider).getMyBranch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
          }

          final branch = snapshot.data ?? {};
          final code = branch['code'] ?? 'N/A';
          final name = branch['name'] ?? 'N/A';
          final address = branch['address'] ?? 'N/A';
          final director = branch['owner_name'] ?? 'N/A';
          final mobile = branch['contact_phone'] ?? 'N/A';
          final email = ref.read(supabaseServiceProvider).currentUser?.email ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Text(
                          'Centre & Personal Information',
                          style: AppTypography.bodyLg.copyWith(color: Colors.black54),
                        ),
                      ),
                      _buildRow('Centre Code', code),
                      _buildRow('Centre Name', name),
                      _buildRow('Centre Address', address),
                      _buildRow('Director\'s Name', director),
                      _buildRow('Mob. NO', mobile),
                      _buildRow('E-MAIL', email, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white),
                    label: const Text(
                      'Authorisation Certificate View / Download',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateViewerScreen(
                            certificate: {
                              'students': {'name': director != 'N/A' ? director : name},
                              'courses': {'name': 'AUTHORISED STUDY CENTRE ($name)'},
                              'session': '2024-2027',
                              'grade': 'A+',
                              'certificate_no': 'AUTH-$code',
                              'issue_date': DateTime.now().toString().split(' ')[0],
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(supabaseServiceProvider).signOut();
                    if (context.mounted) {
                      context.go('/admin/login');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
