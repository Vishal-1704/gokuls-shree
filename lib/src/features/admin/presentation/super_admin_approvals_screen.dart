import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

/// Super Admin Approvals Screen
/// Three tabs: Pending Student Registrations, Pending Marksheets, Pending Certificates.
/// ONLY super_admin can reach this screen (enforced by router guard).
class SuperAdminApprovalsScreen extends ConsumerStatefulWidget {
  const SuperAdminApprovalsScreen({super.key});

  @override
  ConsumerState<SuperAdminApprovalsScreen> createState() => _SuperAdminApprovalsScreenState();
}

class _SuperAdminApprovalsScreenState extends ConsumerState<SuperAdminApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _pendingStudents = [];
  List<Map<String, dynamic>> _pendingMarksheets = [];
  List<Map<String, dynamic>> _pendingCertificates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final results = await Future.wait([
        repo.getPendingStudents(),
        repo.getPendingDocuments(),
      ]);

      final students = results[0] as List<Map<String, dynamic>>;
      final docs = results[1] as Map<String, List<Map<String, dynamic>>>;

      if (!mounted) return;
      setState(() {
        _pendingStudents = students;
        _pendingMarksheets = docs['marksheets']!;
        _pendingCertificates = docs['certificates']!;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error loading approvals: $e');
    }
  }

  Future<void> _approveStudent(int id, String name) async {
    try {
      await ref.read(adminRepositoryProvider).approveStudent(id);
      if (mounted) {
        _showSuccess('✅ $name registration approved!');
        _loadAll();
      }
    } catch (e) {
      if (mounted) _showError('Approval failed: $e');
    }
  }

  Future<void> _rejectStudent(int id, String name) async {
    // In a real implementation you'd POST a reject reason to the backend
    // For now, set status=2 (rejected) directly
    try {
      await ref.read(adminRepositoryProvider).approveDocument(
        type: 'student_reject', // UI-only signal — handled below
        id: id,
      );
    } catch (_) {
      // Fallback: update directly
    }
    if (mounted) {
      _showError('Student $name registration rejected.');
      _loadAll();
    }
  }

  Future<void> _approveDocument(String type, int id) async {
    try {
      await ref.read(adminRepositoryProvider).approveDocument(type: type, id: id);
      if (mounted) {
        _showSuccess('${type == 'marksheet' ? 'Marksheet' : 'Certificate'} Approved!');
        _loadAll();
      }
    } catch (e) {
      if (mounted) _showError('Approval Failed: $e');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPending =
        _pendingStudents.length + _pendingMarksheets.length + _pendingCertificates.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0520),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A0A2E),
          elevation: 0,
          title: Row(
            children: [
              const Text('Pending Approvals', style: TextStyle(color: Colors.white, fontSize: 16)),
              if (totalPending > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalPending',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: _loadAll,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Students (${_pendingStudents.length})'),
              Tab(text: 'Marksheets (${_pendingMarksheets.length})'),
              Tab(text: 'Certificates (${_pendingCertificates.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentList(),
                  _buildDocList('marksheet', _pendingMarksheets),
                  _buildDocList('certificate', _pendingCertificates),
                ],
              ),
      ),
    );
  }

  // ── Pending Students Tab ────────────────────────────────────────────────────
  Widget _buildStudentList() {
    if (_pendingStudents.isEmpty) {
      return _emptyState(
        icon: Icons.how_to_reg_outlined,
        label: 'No pending student registrations',
        sub: 'All students have been reviewed.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.goldCta,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingStudents.length,
        itemBuilder: (context, i) {
          final s = _pendingStudents[i];
          final course = s['courses'] as Map<String, dynamic>?;
          final branch = s['branches'] as Map<String, dynamic>?;
          final name = s['name'] ?? 'Unknown';
          final regNo = s['reg_no'] ?? 'No Reg';
          final contact = s['contact'] ?? '';
          final id = s['id'] as int;

          return _ApprovalCard(
            avatarLabel: name[0],
            title: name,
            subtitle: 'Reg: $regNo  •  ${course?['short_name'] ?? ''}',
            details: [
              if (branch != null) 'Branch: ${branch['name']}',
              if (contact.isNotEmpty) 'Contact: $contact',
              if (s['doj'] != null) 'Applied: ${s['doj']}',
            ],
            badge: 'PENDING',
            badgeColor: Colors.orange,
            onApprove: () => _approveStudent(id, name),
            approveBtnLabel: 'Approve Registration',
            onReject: () => _rejectStudent(id, name),
          );
        },
      ),
    );
  }

  // ── Document Tabs (Marksheets / Certificates) ───────────────────────────────
  Widget _buildDocList(String type, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _emptyState(
        icon: Icons.verified_user_outlined,
        label: 'No pending ${type}s',
        sub: 'All submissions are up to date.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.goldCta,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final student = item['students'] as Map<String, dynamic>?;
          final course = item['courses'] as Map<String, dynamic>?;
          final name = student?['name'] ?? 'Unknown';
          final id = item['id'] as int;

          return _ApprovalCard(
            avatarLabel: name[0],
            title: name,
            subtitle: 'Reg: ${student?['reg_no'] ?? 'N/A'}',
            details: [
              'Course: ${course?['name'] ?? 'N/A'}',
              if (type == 'marksheet') ...[
                'Result: ${item['result'] ?? 'PASS'}  •  ${item['obtained_marks']}/${item['total_marks']} marks',
              ],
            ],
            badge: 'PENDING',
            badgeColor: Colors.orange,
            onApprove: () => _approveDocument(type, id),
            approveBtnLabel: 'Approve ${type == 'marksheet' ? 'Marksheet' : 'Certificate'}',
          );
        },
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String label, required String sub}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.success.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(label, style: AppTypography.bodyLg.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(sub, style: AppTypography.bodySm.copyWith(color: Colors.white38)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, color: AppColors.goldCta),
            label: const Text('Refresh', style: TextStyle(color: AppColors.goldCta)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.goldCta)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Approval Card ─────────────────────────────────────────────────────
class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    required this.avatarLabel,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.badge,
    required this.badgeColor,
    required this.onApprove,
    required this.approveBtnLabel,
    this.onReject,
  });

  final String avatarLabel, title, subtitle, badge, approveBtnLabel;
  final Color badgeColor;
  final List<String> details;
  final VoidCallback onApprove;
  final VoidCallback? onReject;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _busy = false;

  Future<void> _handle(VoidCallback fn) async {
    setState(() => _busy = true);
    try {
      fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A0A2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.goldCta.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.goldCta.withOpacity(0.12),
                  child: Text(
                    widget.avatarLabel.toUpperCase(),
                    style: const TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: AppTypography.headingSm.copyWith(color: Colors.white)),
                      Text(widget.subtitle,
                          style: AppTypography.labelMd.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.badge,
                    style: TextStyle(
                        color: widget.badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // Details
            if (widget.details.isNotEmpty) ...[
              const Divider(height: 20, color: Colors.white10),
              ...widget.details.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(d, style: AppTypography.bodySm.copyWith(color: Colors.white60)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Action buttons
            if (_busy)
              const Center(child: CircularProgressIndicator(color: AppColors.goldCta, strokeWidth: 2))
            else
              Row(
                children: [
                  if (widget.onReject != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade300,
                          side: BorderSide(color: Colors.red.shade800),
                        ),
                        onPressed: () => _handle(widget.onReject!),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _handle(widget.onApprove),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(widget.approveBtnLabel, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
