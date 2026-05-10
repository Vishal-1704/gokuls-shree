import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/data/admin_repository.dart';

/// Screen for Super Admin to approve pending marksheets and certificates.
class SuperAdminApprovalsScreen extends ConsumerStatefulWidget {
  const SuperAdminApprovalsScreen({super.key});

  @override
  ConsumerState<SuperAdminApprovalsScreen> createState() => _SuperAdminApprovalsScreenState();
}

class _SuperAdminApprovalsScreenState extends ConsumerState<SuperAdminApprovalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingMarksheets = [];
  List<Map<String, dynamic>> _pendingCertificates = [];

  @override
  void initState() {
    super.initState();
    _loadPendingDocs();
  }

  Future<void> _loadPendingDocs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final docs = await ref.read(adminRepositoryProvider).getPendingDocuments();
      if (!mounted) return;
      setState(() {
        _pendingMarksheets = docs['marksheets']!;
        _pendingCertificates = docs['certificates']!;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading approvals: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approve(String type, int id) async {
    try {
      await ref.read(adminRepositoryProvider).approveDocument(type: type, id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} Approved Successfully!'), 
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPendingDocs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0520), // Deep Purple Theme
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A0A2E),
          elevation: 0,
          title: const Text('Document Approvals', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Marksheets'),
              Tab(text: 'Certificates'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
            : TabBarView(
                children: [
                  _buildList('marksheet', _pendingMarksheets),
                  _buildList('certificate', _pendingCertificates),
                ],
              ),
      ),
    );
  }

  Widget _buildList(String type, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 80, color: AppColors.success.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No pending ${type}s', 
              style: AppTypography.bodyLg.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text('All students are up to date.', style: AppTypography.bodySm.copyWith(color: Colors.white38)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingDocs,
      color: AppColors.goldCta,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final student = item['students'] as Map<String, dynamic>?;
          final course = item['courses'] as Map<String, dynamic>?;

          return Card(
            color: const Color(0xFF1A0A2E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.goldCta.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.goldCta.withOpacity(0.1),
                        child: Text(
                          (student?['name'] ?? 'U')[0], 
                          style: const TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student?['name'] ?? 'Unknown Student',
                              style: AppTypography.headingSm.copyWith(color: Colors.white),
                            ),
                            Text(
                              'Reg: ${student?['reg_no'] ?? 'N/A'}',
                              style: AppTypography.labelMd.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PENDING', 
                          style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  Text(
                    'Course: ${course?['name'] ?? 'N/A'}',
                    style: AppTypography.bodyMd.copyWith(color: Colors.white70),
                  ),
                  if (type == 'marksheet') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Result: ${item['result'] ?? 'PASS'} • Total: ${item['obtained_marks']}/${item['total_marks']}',
                      style: AppTypography.bodySm.copyWith(color: Colors.white54),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          onPressed: () {
                            // Document preview logic
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _approve(type, item['id']),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
