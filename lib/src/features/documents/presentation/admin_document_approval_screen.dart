import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/data/admin_repository.dart';

class AdminDocumentApprovalScreen extends ConsumerStatefulWidget {
  const AdminDocumentApprovalScreen({super.key});

  @override
  ConsumerState<AdminDocumentApprovalScreen> createState() => _AdminDocumentApprovalScreenState();
}

class _AdminDocumentApprovalScreenState extends ConsumerState<AdminDocumentApprovalScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingMarksheets = [];
  List<Map<String, dynamic>> _pendingCertificates = [];

  @override
  void initState() {
    super.initState();
    _loadPendingDocs();
  }

  Future<void> _loadPendingDocs() async {
    setState(() => _isLoading = true);
    try {
      final docs = await ref.read(adminRepositoryProvider).getPendingDocuments();
      setState(() {
        _pendingMarksheets = docs['marksheets']!;
        _pendingCertificates = docs['certificates']!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approve(String type, int id) async {
    try {
      await ref.read(adminRepositoryProvider).approveDocument(type: type, id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.toUpperCase()} Approved Successfully!'), backgroundColor: Colors.green),
        );
        _loadPendingDocs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.inkNavy900,
        appBar: AppBar(
          backgroundColor: AppColors.inkNavy800,
          title: const Text('Document Approvals'),
          bottom: const TabBar(
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
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
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No pending ${type}s', style: AppTypography.bodyLg),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingDocs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final student = item['students'] as Map<String, dynamic>?;
          final course = item['courses'] as Map<String, dynamic>?;

          return Card(
            color: AppColors.inkNavy800,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          student?['name'] ?? 'Unknown Student',
                          style: AppTypography.headingSm.copyWith(color: AppColors.goldCta),
                        ),
                      ),
                      Text(
                        '#${item['id']}',
                        style: AppTypography.labelMd.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Course: ${course?['name'] ?? 'N/A'}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Reg No: ${student?['reg_no'] ?? 'N/A'}',
                    style: AppTypography.labelMd.copyWith(color: AppColors.textMuted),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Show preview of the document
                        },
                        child: const Text('View Preview'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _approve(type, item['id']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
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
