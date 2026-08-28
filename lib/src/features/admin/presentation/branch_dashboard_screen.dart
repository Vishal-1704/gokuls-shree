import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_student_directory_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_staff_directory_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/super_admin_approvals_screen.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class BranchDashboardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> branch;

  const BranchDashboardScreen({super.key, required this.branch});

  @override
  ConsumerState<BranchDashboardScreen> createState() => _BranchDashboardScreenState();
}

class _BranchDashboardScreenState extends ConsumerState<BranchDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchBranchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranchStats() async {
    final client = ref.read(supabaseClientProvider);
    final branchId = widget.branch['id'] as int;

    try {
      // Revenue
      final feeRes = await client.from('fee_payments').select('amount').eq('branch_id', branchId);
      double totalRevenue = 0;
      for (final row in feeRes) {
        totalRevenue += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Students
      final studentRes = await client.from('students').select('id').eq('branch_id', branchId).eq('status', 1);
      final studentCount = studentRes.length;

      // Teachers
      final teacherRes = await client.from('employees').select('id').eq('branch_id', branchId).eq('status', 1);
      final teacherCount = teacherRes.length;

      // Pending Approvals
      final pendingRes = await client.from('students').select('id').eq('branch_id', branchId).eq('status', 0);
      final pendingCount = pendingRes.length;

      if (mounted) {
        setState(() {
          _stats = {
            'revenue': totalRevenue,
            'students': studentCount,
            'teachers': teacherCount,
            'pending': pendingCount,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = widget.branch['id'] as int;
    final branchName = widget.branch['name'] ?? 'Branch Dashboard';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Text(branchName, style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.goldCta,
          labelColor: AppColors.goldCta,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
            Tab(text: 'Approvals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          AdminStudentDirectoryScreen(branchId: branchId),
          AdminStaffDirectoryScreen(branchId: branchId),
          SuperAdminApprovalsScreen(branchId: branchId),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
    }

    if (_stats == null) {
      return const Center(child: Text('Failed to load branch statistics.', style: TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Branch Live Statistics',
            style: TextStyle(color: AppColors.goldCta, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildStatRow(Icons.currency_rupee, 'Total Revenue Collected', '₹${_stats!['revenue'].toStringAsFixed(0)}'),
          _buildStatRow(Icons.school_outlined, 'Students Enrolled', '${_stats!['students']} Active'),
          _buildStatRow(Icons.co_present_outlined, 'Teachers Enrolled', '${_stats!['teachers']} Active'),
          _buildStatRow(Icons.pending_actions_outlined, 'Pending Approvals', '${_stats!['pending']} Students'),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldCta.withOpacity(0.2)),
            ),
            child: Icon(icon, color: AppColors.goldCta, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
