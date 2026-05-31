import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
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
    // Fetch from repo (or use mock if table doesn't exist yet)
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
      // Fallback to mock data if API fails (likely table missing)
      if (mounted) {
        setState(() {
          _staffList = _getMockStaff();
          _filteredStaff = _staffList;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockStaff() {
    return [
      {
        'id': '1',
        'name': 'Rajesh Kumar',
        'role': 'Teacher',
        'phone': '9876543210',
        'email': 'rajesh@school.com',
        'photo_url': null,
      },
      {
        'id': '2',
        'name': 'Sunita Sharma',
        'role': 'Admin',
        'phone': '9876543211',
        'email': 'sunita@school.com',
        'photo_url': null,
      },
      {
        'id': '3',
        'name': 'Ramesh Singh',
        'role': 'Driver',
        'phone': '9876543212',
        'email': 'ramesh@school.com',
        'photo_url': null,
      },
      {
        'id': '4',
        'name': 'Priya Patel',
        'role': 'Teacher',
        'phone': '9876543213',
        'email': 'priya@school.com',
        'photo_url': null,
      },
    ];
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Staff Directory',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditStaff(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStaff,
              decoration: InputDecoration(
                hintText: 'Search by Name or Role...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStaff.isEmpty
                ? const Center(child: Text('No staff found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _filteredStaff[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              staff['name'][0],
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            staff['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            staff['role'] ?? 'Staff',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                                onPressed: () => _makeCall(staff['phone']),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToAddEditStaff(staff);
                                  } else if (value == 'delete') {
                                    _deleteStaff(staff['id']);
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
