import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

/// Super Admin Approvals Screen
/// Three tabs: Pending Student Registrations, Pending Marksheets, Pending Certificates.
/// ONLY super_admin can reach this screen (enforced by router guard).
class SuperAdminApprovalsScreen extends ConsumerStatefulWidget {
  final int? branchId;

  const SuperAdminApprovalsScreen({super.key, this.branchId});

  @override
  ConsumerState<SuperAdminApprovalsScreen> createState() =>
      _SuperAdminApprovalsScreenState();
}

class _SuperAdminApprovalsScreenState
    extends ConsumerState<SuperAdminApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _pendingStudents = [];
  List<Map<String, dynamic>> _pendingMarksheets = [];
  List<Map<String, dynamic>> _pendingCertificates = [];
  List<Map<String, dynamic>> _pendingExperienceCerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        repo.getPendingStudents(branchId: widget.branchId),
        repo.getPendingDocuments(branchId: widget.branchId),
        repo.getPendingExperienceCerts(branchId: widget.branchId),
      ]);

      final students = results[0] as List<Map<String, dynamic>>;
      final docs = results[1] as Map<String, List<Map<String, dynamic>>>;
      final expCerts = results[2] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _pendingStudents = students;
        _pendingMarksheets = docs['marksheets']!;
        _pendingCertificates = docs['certificates']!;
        _pendingExperienceCerts = expCerts;
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
    try {
      await ref.read(adminRepositoryProvider).rejectStudent(id);
      if (mounted) {
        _showSuccess('Student $name registration rejected and removed.');
        _loadAll();
      }
    } catch (e) {
      if (mounted) _showError('Rejection failed: $e');
    }
  }

  Future<void> _approveExperienceCert(int id) async {
    try {
      await ref.read(adminRepositoryProvider).approveExperienceCert(id);
      if (mounted) {
        _showSuccess('Experience Certificate Approved & Issued!');
        _loadAll();
      }
    } catch (e) {
      if (mounted) _showError('Approval Failed: $e');
    }
  }

  Future<void> _approveDocument(String type, int id) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveDocument(type: type, id: id);
      if (mounted) {
        _showSuccess(
          '${type == 'marksheet' ? 'Marksheet' : 'Certificate'} Approved!',
        );
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

  void _showDetailsModal({
    required String type, // 'student' | 'marksheet' | 'certificate'
    required Map<String, dynamic> item,
    required VoidCallback onApprove,
    required VoidCallback? onReject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double modalHeight = type == 'student' ? 0.75 : 0.55;

        return Container(
          height: MediaQuery.of(context).size.height * modalHeight,
          decoration: const BoxDecoration(
            color: AppColors.inkNavy700,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.goldCta, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type == 'student'
                        ? 'Student Registration Request'
                        : type == 'marksheet'
                        ? 'Marksheet Approval Request'
                        : 'Certificate Approval Request',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider10),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (type == 'student') ...[
                        _buildDetailItem('Full Name', item['name'] ?? 'N/A'),
                        _buildDetailItem(
                          'Email Address',
                          item['email'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Mobile Number',
                          item['contact'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Father\'s Name',
                          item['father_name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Mother\'s Name',
                          item['mother_name'] ?? 'N/A',
                        ),
                        _buildDetailItem('Date of Birth', item['dob'] ?? 'N/A'),
                        _buildDetailItem('Gender', item['gender'] ?? 'N/A'),
                        _buildDetailItem('Address', item['address'] ?? 'N/A'),
                        _buildDetailItem(
                          'Course Name',
                          item['courses']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Branch',
                          item['branches']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem('Date Applied', item['doj'] ?? 'N/A'),
                      ] else if (type == 'marksheet') ...[
                        _buildDetailItem(
                          'Student Name',
                          item['students']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Registration No.',
                          item['students']?['reg_no'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Course Enrolled',
                          item['courses']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Result Status',
                          item['result'] ?? 'PASS',
                        ),
                        _buildDetailItem(
                          'Marks Obtained',
                          '${item['obtained_marks'] ?? 0} / ${item['total_marks'] ?? 0}',
                        ),
                        _buildDetailItem(
                          'Percentage',
                          '${item['percentage'] ?? 0}%',
                        ),
                      ] else if (type == 'certificate') ...[
                        _buildDetailItem(
                          'Student Name',
                          item['students']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Registration No.',
                          item['students']?['reg_no'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Course Enrolled',
                          item['courses']?['name'] ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Certificate Type',
                          item['doc_type'] ?? 'Course Completion',
                        ),
                        _buildDetailItem(
                          'Generated At',
                          item['created_at'] ?? 'N/A',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onReject != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade300,
                          side: BorderSide(color: Colors.red.shade800),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onReject();
                        },
                        child: const Text(
                          'Reject & Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onApprove();
                      },
                      child: const Text(
                        'Approve',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPending =
        _pendingStudents.length +
        _pendingMarksheets.length +
        _pendingCertificates.length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.inkNavy900,
        appBar: AppBar(
          backgroundColor: AppColors.inkNavy800,
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'Pending Approvals',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              if (totalPending > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalPending',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              onPressed: _loadAll,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.goldCta,
            labelColor: AppColors.goldCta,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Students (${_pendingStudents.length})'),
              Tab(text: 'Marksheets (${_pendingMarksheets.length})'),
              Tab(text: 'Certificates (${_pendingCertificates.length})'),
              Tab(text: 'Exp. Certs (${_pendingExperienceCerts.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.goldCta),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentList(),
                  _buildDocList('marksheet', _pendingMarksheets),
                  _buildDocList('certificate', _pendingCertificates),
                  _buildExpCertList(),
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
            approveBtnLabel: 'Approve',
            onReject: () => _rejectStudent(id, name),
            onViewDetails: () => _showDetailsModal(
              type: 'student',
              item: s,
              onApprove: () => _approveStudent(id, name),
              onReject: () => _rejectStudent(id, name),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpCertList() {
    if (_pendingExperienceCerts.isEmpty) {
      return _emptyState(
        icon: Icons.workspace_premium_outlined,
        label: 'No pending experience certificates',
        sub: 'All requests have been reviewed.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.goldCta,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingExperienceCerts.length,
        itemBuilder: (context, i) {
          final cert = _pendingExperienceCerts[i];
          final emp = cert['employees'] as Map<String, dynamic>?;
          final name = emp?['name'] ?? 'Unknown';
          final reqDate = cert['request_date'] ?? '';
          final id = cert['id'] as int;

          return _ApprovalCard(
            avatarLabel: name[0],
            title: name,
            subtitle: 'Req Date: ${reqDate.length > 10 ? reqDate.substring(0,10) : reqDate}',
            details: [
              'Designation: ${emp?['designation'] ?? 'N/A'}',
              'Dept: ${emp?['department'] ?? 'N/A'}',
              'Joined: ${emp?['doj'] ?? 'N/A'}',
            ],
            badge: 'PENDING',
            badgeColor: Colors.orange,
            onApprove: () => _approveExperienceCert(id),
            approveBtnLabel: 'Approve & Issue',
            onViewDetails: () {},
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
            approveBtnLabel: 'Approve',
            onViewDetails: () => _showDetailsModal(
              type: type,
              item: item,
              onApprove: () => _approveDocument(type, id),
              onReject: null,
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String label,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.success.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTypography.bodyLg.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, color: AppColors.goldCta),
            label: const Text(
              'Refresh',
              style: TextStyle(color: AppColors.goldCta),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldCta),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
    required this.onViewDetails,
    this.onReject,
  });

  final String avatarLabel, title, subtitle, badge, approveBtnLabel;
  final Color badgeColor;
  final List<String> details;
  final VoidCallback onApprove;
  final VoidCallback onViewDetails;
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
      color: AppColors.inkNavy800,
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
                    style: const TextStyle(
                      color: AppColors.goldCta,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.badge,
                    style: TextStyle(
                      color: widget.badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  color: AppColors.inkNavy700,
                  onSelected: (val) {
                    if (val == 'details') {
                      widget.onViewDetails();
                    } else if (val == 'reject' && widget.onReject != null) {
                      _handle(widget.onReject!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('View Details', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    if (widget.onReject != null)
                      const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject Request', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
            // Details
            if (widget.details.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider10),
              ...widget.details.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    d,
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Action buttons
            if (_busy)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.goldCta,
                  strokeWidth: 2,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handle(widget.onApprove),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(widget.approveBtnLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
