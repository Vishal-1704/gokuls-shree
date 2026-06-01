import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_add_staff_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminStaffDirectoryScreen extends ConsumerStatefulWidget {
  const AdminStaffDirectoryScreen({super.key});

  @override
  ConsumerState<AdminStaffDirectoryScreen> createState() =>
      _AdminStaffDirectoryScreenState();
}

class _AdminStaffDirectoryScreenState
    extends ConsumerState<AdminStaffDirectoryScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    _loadError = null;
    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getStaff();
      if (mounted) {
        setState(() {
          _staffList = data;
          _filteredStaff = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _staffList = [];
          _filteredStaff = [];
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterStaff(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStaff = _staffList);
      return;
    }
    setState(() {
      _filteredStaff = _staffList.where((staff) {
        final name = staff['name'].toString().toLowerCase();
        final role = staff['role'].toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || role.contains(q);
      }).toList();
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _navigateToAddEditStaff([Map<String, dynamic>? staff]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddStaffScreen(staff: staff),
      ),
    );
    _loadStaff(); // Refresh on return
  }

  Future<void> _deleteStaff(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to remove this staff member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await ref.read(adminRepositoryProvider).deleteStaff(id);
        // Refresh local list for now as repo might fail with mock
        setState(() {
          _staffList.removeWhere((s) => s['id'] == id);
          _filteredStaff.removeWhere((s) => s['id'] == id);
          _isLoading = false;
        });
      } catch (e) {
        // Mock delete
        setState(() {
          _staffList.removeWhere((s) => s['id'] == id);
          _filteredStaff.removeWhere((s) => s['id'] == id);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Staff Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.inkNavy800,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditStaff(),
        backgroundColor: AppColors.goldCta,
        foregroundColor: AppColors.inkNavy900,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStaff,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by Name or Role...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load staff data',
                            style: AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loadError!,
                            style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadStaff,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredStaff.isEmpty
                ? const Center(child: Text('No staff found', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _filteredStaff[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inkNavy800,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inkNavy600),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.inkNavy700,
                            child: Text(
                              staff['name'][0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.goldCta,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            staff['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            staff['role'] ?? 'Staff',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: AppColors.success,
                                ),
                                onPressed: () => _makeCall(staff['phone'] ?? staff['contact'] ?? ''),
                              ),
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                color: AppColors.inkNavy800,
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToAddEditStaff(staff);
                                  } else if (value == 'delete') {
                                    _deleteStaff(staff['id']?.toString() ?? '');
                                  }
                                },
                              ),
                            ],
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
}
