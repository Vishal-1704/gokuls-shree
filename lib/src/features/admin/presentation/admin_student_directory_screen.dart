import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_fee_collection_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_admit_card_screen.dart';

class AdminStudentDirectoryScreen extends ConsumerStatefulWidget {
  const AdminStudentDirectoryScreen({super.key});

  @override
  ConsumerState<AdminStudentDirectoryScreen> createState() =>
      _AdminStudentDirectoryScreenState();
}

class _AdminStudentDirectoryScreenState
    extends ConsumerState<AdminStudentDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadStudents(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (_isLoadingMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (!_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final rows = await ref
          .read(adminRepositoryProvider)
          .getStudentsPaged(
            page: _page,
            pageSize: _pageSize,
            query: _searchController.text,
            statusFilter: _statusFilter,
          );

      if (!mounted) return;
      setState(() {
        _students = reset ? rows : [..._students, ...rows];
        _hasMore = rows.length == _pageSize;
        if (_hasMore) _page += 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _loadStudents(reset: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadStudents();
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Student Directory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.inkNavy800,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
            color: AppColors.inkNavy800,
            onSelected: (value) {
              setState(() => _statusFilter = value);
              _loadStudents(reset: true);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'all',
                child: Text(
                  'All Students',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'active',
                child: Text(
                  'Active only',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'inactive',
                child: Text(
                  'Inactive only',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by Name or Reg No...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.inkNavy600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.inkNavy600),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.goldCta),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.goldCta),
                  )
                : _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _students.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= _students.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.goldCta,
                            ),
                          ),
                        );
                      }

                      final student = _students[index];
                      // status: 1=Active, 0=Pending, 2=Inactive
                      final isInactive = student['status'] == 2;
                      final isPending = student['status'] == 0;
                      final photoUrl = student['photo_url']?.toString();
                      final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                      final courseName =
                          student['courses']?['short_name'] ??
                          student['courses']?['name'] ??
                          'N/A';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.inkNavy800,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inkNavy600),
                        ),
                        child: ListTile(
                          onTap: () =>
                              _showStudentActionSheet(context, student),
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.inkNavy700,
                            backgroundImage: hasPhoto
                                ? NetworkImage(photoUrl)
                                : null,
                            child: hasPhoto
                                ? null
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondary,
                                  ),
                            onBackgroundImageError: (_, __) =>
                                const Icon(Icons.person),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isInactive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.danger.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${student['reg_no'] ?? '-'} • Course: $courseName',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            onPressed: () => _makeCall(
                              student['phone']?.toString() ??
                                  student['contact']?.toString() ??
                                  '',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showStudentActionSheet(
    BuildContext context,
    Map<String, dynamic> student,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.inkNavy600, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Actions for ${student['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.call, color: AppColors.success),
              ),
              title: const Text(
                'Call Parent',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _makeCall(
                  student['phone']?.toString() ??
                      student['contact']?.toString() ??
                      '',
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldCta.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments, color: AppColors.goldCta),
              ),
              title: const Text(
                'Collect Fee',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminFeeCollectionScreen(student: student),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge, color: AppColors.info),
              ),
              title: const Text(
                'Admit Card',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminAdmitCardScreen(student: student),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.warning),
              ),
              title: const Text(
                'View Full Details',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showStudentDetailsModal(context, student);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetailsModal(
    BuildContext context,
    Map<String, dynamic> student,
  ) {
    final course = student['courses'] as Map<String, dynamic>?;
    final branch = student['branches'] as Map<String, dynamic>?;
    final isPending = student['status'] == 0;
    final isInactive = student['status'] == 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.inkNavy600, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.inkNavy700,
                      backgroundImage: student['photo_url'] != null
                          ? NetworkImage(student['photo_url'])
                          : null,
                      child: student['photo_url'] == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.textSecondary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student['name'] ?? 'Unknown Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student['email'] ?? 'No email associated',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isInactive
                                ? AppColors.danger.withOpacity(0.15)
                                : isPending
                                ? AppColors.warning.withOpacity(0.15)
                                : AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isInactive
                                  ? AppColors.danger.withOpacity(0.3)
                                  : isPending
                                  ? AppColors.warning.withOpacity(0.3)
                                  : AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isInactive
                                ? 'INACTIVE'
                                : isPending
                                ? 'PENDING APPROVAL'
                                : 'ACTIVE STUDENT',
                            style: TextStyle(
                              color: isInactive
                                  ? AppColors.danger
                                  : isPending
                                  ? AppColors.warning
                                  : AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.inkNavy600),
                    _buildDetailRow(
                      'Registration No.',
                      student['reg_no'] ?? 'Not Assigned',
                    ),
                    _buildDetailRow(
                      'Admission No.',
                      student['adm_no'] ?? 'N/A',
                    ),
                    _buildDetailRow('Roll No.', student['roll_no'] ?? 'N/A'),
                    _buildDetailRow('Course Name', course?['name'] ?? 'N/A'),
                    _buildDetailRow('Branch Name', branch?['name'] ?? 'N/A'),
                    _buildDetailRow(
                      'Father\'s Name',
                      student['father_name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Mother\'s Name',
                      student['mother_name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Contact',
                      student['contact'] ?? student['phone'] ?? 'N/A',
                    ),
                    _buildDetailRow('DOB', student['dob'] ?? 'N/A'),
                    _buildDetailRow('Gender', student['gender'] ?? 'N/A'),
                    _buildDetailRow(
                      'Qualification',
                      student['qualification'] ?? 'N/A',
                    ),
                    _buildDetailRow('Address', student['address'] ?? 'N/A'),
                    _buildDetailRow('Date of Joining', student['doj'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
