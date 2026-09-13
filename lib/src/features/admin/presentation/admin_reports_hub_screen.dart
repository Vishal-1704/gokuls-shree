import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

class AdminReportsHubScreen extends ConsumerStatefulWidget {
  const AdminReportsHubScreen({super.key});

  @override
  ConsumerState<AdminReportsHubScreen> createState() =>
      _AdminReportsHubScreenState();
}

class _AdminReportsHubScreenState extends ConsumerState<AdminReportsHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duesAsync = ref.watch(adminDuesReportProvider);
    final studentsAsync = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reports & Fees',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Search Bar ───
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search marksheets, results, dues, exams...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 19),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ─── Quick Summary Banner ───
            if (_searchQuery.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administrative Records',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          duesAsync.when(
                            data: (dues) {
                              final totalPending = dues.where((d) => (d['due_amount'] as num? ?? 0) > 0).length;
                              return Text(
                                '$totalPending students with pending dues • Unified Hub',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              );
                            },
                            loading: () => const Text(
                              'Loading financial metrics...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            error: (_, __) => studentsAsync.when(
                              data: (students) => Text(
                                '${students.length} Total Enrolled Students',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ─── SECTION 1: Academic & Examination Records ───
            _buildSection(
              title: 'Academic & Examination Reports',
              subtitle: 'Marksheet generation, scores entry, and test rosters',
              items: [
                _HubItem(
                  title: 'Marksheet Generator',
                  subtitle: 'Generate and export official student marksheets with grades & QR codes',
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFE0F2FE),
                  route: '/admin/marksheet-generator',
                  badge: 'PDF Export',
                ),
                _HubItem(
                  title: 'Results Entry',
                  subtitle: 'Record subject marks, theory/practical scores, and evaluation notes',
                  icon: Icons.edit_document,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFEDE9FE),
                  route: '/admin/results-entry',
                ),
                _HubItem(
                  title: 'Schedule Results & Rosters',
                  subtitle: 'Inspect submitted vs absent rosters for online exams & publish scores',
                  icon: Icons.fact_check_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFD1FAE5),
                  route: '/admin/schedule-results',
                  badge: 'MCQ Exams',
                ),
                _HubItem(
                  title: 'Exam & Test Scheduler',
                  subtitle: 'Schedule upcoming tests or semester exams for courses and batches',
                  icon: Icons.event_note_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  route: '/admin/exam-scheduler',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─── SECTION 2: Financial & Fee Management ───
            _buildSection(
              title: 'Financial & Fee Management',
              subtitle: 'Track dues, overdue student balances, and payment collections',
              items: [
                _HubItem(
                  title: 'Fee Dues Report',
                  subtitle: 'View outstanding student balances, payment history, and due dates',
                  icon: Icons.request_quote_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBg: const Color(0xFFFFE4E6),
                  route: '/admin/dues-report',
                  badge: 'Dues Tracker',
                ),
                _HubItem(
                  title: 'Collect Student Fee',
                  subtitle: 'Collect fees, issue receipts, and record cash/UPI/online payments',
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF0891B2),
                  iconBg: const Color(0xFFCFFAFE),
                  route: '/admin/fee-collection',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<_HubItem> items,
  }) {
    final filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery) ||
          item.subtitle.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 62,
              endIndent: 14,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return InkWell(
                onTap: () => context.push(item.route),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: index == filtered.length - 1
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (item.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.iconColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: TextStyle(
                                        color: item.iconColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String route;
  final String? badge;

  _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.route,
    this.badge,
  });
}
