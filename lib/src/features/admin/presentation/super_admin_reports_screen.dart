import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

/// Super Admin's cross-branch Reports tab.
/// Unlike Branch Admin's AdminReportsHubScreen (scoped to one branch),
/// this aggregates revenue and student/dues counts across ALL branches.
/// Attendance and an aggregate "results" metric are intentionally omitted —
/// no branch-scoped data source exists for either in the codebase.
class SuperAdminReportsScreen extends ConsumerWidget {
  const SuperAdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final studentsAsync = ref.watch(adminStudentsProvider);
    final duesAsync = ref.watch(adminDuesReportProvider);
    final revenueAsync = ref.watch(adminRevenueByBranchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ref.invalidate(branchesProvider);
              ref.invalidate(adminStudentsProvider);
              ref.invalidate(adminDuesReportProvider);
              ref.invalidate(adminRevenueByBranchProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(branchesProvider);
          ref.invalidate(adminStudentsProvider);
          ref.invalidate(adminDuesReportProvider);
          ref.invalidate(adminRevenueByBranchProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryBanner(revenueAsync, duesAsync, branchesAsync),
              const SizedBox(height: 20),
              _sectionHeader('Revenue by Branch', 'All-time fee collections per branch'),
              const SizedBox(height: 10),
              _buildRevenueSection(revenueAsync),
              const SizedBox(height: 20),
              _sectionHeader('Branch Comparison', 'Students and pending dues per branch'),
              const SizedBox(height: 10),
              _buildComparisonTable(branchesAsync, studentsAsync, duesAsync, revenueAsync),
              const SizedBox(height: 20),
              _sectionHeader('Academic & Examination', 'Marksheets, results entry, and exam records'),
              const SizedBox(height: 10),
              _buildQuickLinks(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryBanner(
    AsyncValue<List<Map<String, dynamic>>> revenueAsync,
    AsyncValue<List<Map<String, dynamic>>> duesAsync,
    AsyncValue<List<Map<String, dynamic>>> branchesAsync,
  ) {
    final totalRevenue = revenueAsync.maybeWhen(
      data: (rows) => rows.fold<double>(0, (sum, r) => sum + (r['total_revenue'] as num? ?? 0)),
      orElse: () => null,
    );
    final pendingCount = duesAsync.maybeWhen(data: (rows) => rows.length, orElse: () => null);
    final branchCount = branchesAsync.maybeWhen(data: (rows) => rows.length, orElse: () => null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _bannerStat(
              'Total Revenue',
              totalRevenue == null ? '…' : '₹${totalRevenue.toStringAsFixed(0)}',
            ),
          ),
          Expanded(child: _bannerStat('Branches', branchCount?.toString() ?? '…')),
          Expanded(child: _bannerStat('Pending Dues', pendingCount?.toString() ?? '…')),
        ],
      ),
    );
  }

  Widget _bannerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
      ],
    );
  }

  Widget _cardContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildRevenueSection(AsyncValue<List<Map<String, dynamic>>> revenueAsync) {
    return _cardContainer(
      revenueAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Failed to load revenue: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Padding(padding: EdgeInsets.all(16), child: Text('No fee payments recorded yet.'));
          }
          final maxRevenue = rows.map((r) => (r['total_revenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
          return Column(
            children: [
              for (int i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rows[i]['branch_name'].toString(),
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          Text(
                            '₹${(rows[i]['total_revenue'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxRevenue == 0 ? 0 : (rows[i]['total_revenue'] as num) / maxRevenue,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable(
    AsyncValue<List<Map<String, dynamic>>> branchesAsync,
    AsyncValue<List<Map<String, dynamic>>> studentsAsync,
    AsyncValue<List<Map<String, dynamic>>> duesAsync,
    AsyncValue<List<Map<String, dynamic>>> revenueAsync,
  ) {
    if (branchesAsync.isLoading || studentsAsync.isLoading || duesAsync.isLoading || revenueAsync.isLoading) {
      return _cardContainer(const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
    }
    final branches = branchesAsync.maybeWhen(data: (v) => v, orElse: () => <Map<String, dynamic>>[]);
    final students = studentsAsync.maybeWhen(data: (v) => v, orElse: () => <Map<String, dynamic>>[]);
    final dues = duesAsync.maybeWhen(data: (v) => v, orElse: () => <Map<String, dynamic>>[]);
    final revenue = revenueAsync.maybeWhen(data: (v) => v, orElse: () => <Map<String, dynamic>>[]);

    if (branches.isEmpty) {
      return _cardContainer(const Padding(padding: EdgeInsets.all(16), child: Text('No branches found.')));
    }

    final revenueByBranch = {for (final r in revenue) r['branch_id']: (r['total_revenue'] as num).toDouble()};

    return _cardContainer(
      Column(
        children: [
          for (int i = 0; i < branches.length; i++)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (branches[i]['name'] ?? branches[i]['code'] ?? 'Branch').toString(),
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _comparisonMetric(
                            Icons.people_alt_rounded,
                            students.where((s) => s['branch_id'] == branches[i]['id']).length.toString(),
                          ),
                          const SizedBox(width: 16),
                          _comparisonMetric(
                            Icons.request_quote_rounded,
                            dues.where((d) => d['branch_id'] == branches[i]['id']).length.toString(),
                          ),
                          const Spacer(),
                          Text(
                            '₹${(revenueByBranch[branches[i]['id']] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i != branches.length - 1) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _comparisonMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      (
        'Marksheet Generator',
        'Generate and export official student marksheets',
        Icons.description_rounded,
        const Color(0xFF0284C7),
        const Color(0xFFE0F2FE),
        '/admin/marksheet-generator',
      ),
      (
        'Results Entry',
        'Record subject marks and evaluation notes',
        Icons.edit_document,
        const Color(0xFF7C3AED),
        const Color(0xFFEDE9FE),
        '/super-admin/results-entry',
      ),
      (
        'Schedule Results & Rosters',
        'Inspect rosters for online exams & publish scores',
        Icons.fact_check_rounded,
        const Color(0xFF059669),
        const Color(0xFFD1FAE5),
        '/super-admin/schedule-results',
      ),
      (
        'Exam & Test Scheduler',
        'Schedule upcoming tests or semester exams',
        Icons.event_note_rounded,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
        '/super-admin/exam-scheduler',
      ),
      (
        'Fee Dues Report',
        'Outstanding student balances across all branches',
        Icons.request_quote_rounded,
        const Color(0xFFE11D48),
        const Color(0xFFFFE4E6),
        '/admin/dues-report',
      ),
      (
        'Collect Student Fee',
        'Collect fees and record payments',
        Icons.payments_rounded,
        const Color(0xFF0891B2),
        const Color(0xFFCFFAFE),
        '/admin/fee-collection',
      ),
    ];

    return _cardContainer(
      Column(
        children: [
          for (int i = 0; i < links.length; i++)
            InkWell(
              onTap: () => context.push(links[i].$6),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(14) : Radius.zero,
                bottom: i == links.length - 1 ? const Radius.circular(14) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: links[i].$5, borderRadius: BorderRadius.circular(10)),
                      child: Icon(links[i].$3, color: links[i].$4, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(links[i].$1, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            links[i].$2,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
