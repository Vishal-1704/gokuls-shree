import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_add_student_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_course_detail_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_course_form_screen.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';

/// Admin Panel screen for managing courses, notices, students, and downloads
/// Only accessible by admin users
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final adminRepo = ref.read(adminRepositoryProvider);

    try {
      final results = await Future.wait([
        adminRepo.getCourses(),
        adminRepo.getNotices(),
        adminRepo.getStudents(),
        adminRepo.getDownloads(),
      ]);

      setState(() {
        _courses = results[0];
        _notices = results[1];
        _students = results[2];
        _downloads = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      data: (isAdminUser) {
        if (!isAdminUser) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Admin access required', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Contact administrator for access'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.inkNavy900,
          appBar: AppBar(
            backgroundColor: AppColors.inkNavy800,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text('Admin Panel'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.goldCta,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.goldCta,
              tabs: [
                Tab(text: 'Courses (${_courses.length})'),
                Tab(text: 'Notices (${_notices.length})'),
                Tab(text: 'Students (${_students.length})'),
                Tab(text: 'Downloads (${_downloads.length})'),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.goldCta),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    scaffoldBackgroundColor: AppColors.inkNavy900,
                    canvasColor: AppColors.inkNavy900,
                    cardColor: AppColors.inkNavy800,
                    dividerColor: AppColors.divider,
                    listTileTheme: const ListTileThemeData(
                      iconColor: AppColors.textSecondary,
                      textColor: AppColors.textPrimary,
                    ),
                    textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: AppColors.textPrimary,
                      displayColor: AppColors.textPrimary,
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCoursesTab(),
                      _buildNoticesTab(),
                      _buildStudentsTab(),
                      _buildDownloadsTab(),
                    ],
                  ),
                ),
          floatingActionButton: _tabController.index == 0
              ? null
              : FloatingActionButton(
                  backgroundColor: AppColors.goldCta,
                  foregroundColor: AppColors.inkNavy900,
                  onPressed: () => _showAddDialog(),
                  child: const Icon(Icons.add),
                ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.inkNavy900,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.goldCta),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.inkNavy900,
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  // ===========================================
  // COURSES TAB
  // ===========================================
  Widget _buildCoursesTab() {
    if (_courses.isEmpty) {
      return const Center(child: Text('No courses found'));
    }

    final role = ref.watch(currentRoleProvider);
    final isSuperAdmin = role == UserRole.superAdmin;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          final courseTitle = (course['name'] ?? course['title'] ?? 'Untitled Course').toString();
          final courseCategory = (course['category'] ?? 'Computer & Vocational').toString();
          final courseDuration = (course['duration'] ?? '12 Months').toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => AdminCourseDetailScreen(course: course),
                  ),
                ).then((_) => _loadData());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldCta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppColors.goldCta, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  courseCategory,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•  $courseDuration',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSuperAdmin)
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Specs')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        onSelected: (value) => _handleCourseAction(value, course),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // NOTICES TAB
  // ===========================================
  Widget _buildNoticesTab() {
    if (_notices.isEmpty) {
      return const Center(child: Text('No notices found'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign, color: Colors.orange),
              ),
              title: Text(notice['title'] ?? 'Untitled'),
              subtitle: Text(notice['category'] ?? ''),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (value) => _handleNoticeAction(value, notice),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // STUDENTS TAB
  // ===========================================
  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    final role = ref.watch(currentRoleProvider);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Builder(
                builder: (context) {
                  final avatar = resolveAvatarProvider(student['photo_url']);
                  return CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: avatar,
                    onBackgroundImageError: avatar != null ? (_, __) {} : null,
                    child: avatar == null
                        ? Text(
                            (student['name'] as String? ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryColor),
                          )
                        : null,
                  );
                },
              ),
              title: Text(student['name'] ?? 'Unknown'),
              subtitle: Text(
                student['reg_no'] ?? student['registration_number'] ?? student['email'] ?? '',
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (role == UserRole.superAdmin) ...[
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Text('Send Password Reset'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
                onSelected: (value) => _handleStudentAction(value, student),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // DOWNLOADS TAB
  // ===========================================
  Widget _buildDownloadsTab() {
    if (_downloads.isEmpty) {
      return const Center(child: Text('No downloads found'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _downloads.length,
        itemBuilder: (context, index) {
          final download = _downloads[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download, color: Colors.blue),
              ),
              title: Text(download['title'] ?? 'Untitled'),
              subtitle: Text(download['category'] ?? ''),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (value) => _handleDownloadAction(value, download),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================
  // ACTION HANDLERS
  // ===========================================
  void _handleCourseAction(String action, Map<String, dynamic> course) async {
    if (action == 'delete') {
      final confirmed = await _confirmDelete('course');
      if (confirmed == true) {
        await ref
            .read(adminRepositoryProvider)
            .deleteCourse(course['id'].toString());
        _loadData();
      }
    } else if (action == 'edit') {
      _showEditCourseDialog(course);
    }
  }

  void _handleNoticeAction(String action, Map<String, dynamic> notice) async {
    if (action == 'delete') {
      final confirmed = await _confirmDelete('notice');
      if (confirmed == true) {
        await ref
            .read(adminRepositoryProvider)
            .deleteNotice(notice['id'].toString());
        _loadData();
      }
    } else if (action == 'edit') {
      _showEditNoticeDialog(notice);
    }
  }

  void _handleStudentAction(String action, Map<String, dynamic> student) async {
    if (action == 'delete') {
      final confirmed = await _confirmDelete('student');
      if (confirmed == true) {
        await ref
            .read(adminRepositoryProvider)
            .deleteStudent(student['id'].toString());
        _loadData();
      }
    } else if (action == 'view') {
      _showStudentDetails(student);
    } else if (action == 'edit') {
      _showEditStudentDialog(student);
    } else if (action == 'reset_password') {
      final email = student['email'] as String?;
      if (email != null && email.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Reset'),
            content: Text('Send password reset email to $email?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(supabaseAuthNotifierProvider)
                      .resetPassword(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student has no email address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDownloadAction(
    String action,
    Map<String, dynamic> download,
  ) async {
    if (action == 'delete') {
      final confirmed = await _confirmDelete('download');
      if (confirmed == true) {
        await ref
            .read(adminRepositoryProvider)
            .deleteDownload(download['id'].toString());
        _loadData();
      }
    }
  }

  Future<bool?> _confirmDelete(String itemType) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $itemType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // ADD DIALOGS
  // ===========================================
  void _showAddDialog() {
    final currentTab = _tabController.index;
    final role = ref.read(currentRoleProvider);
    final isSuperAdmin = role == UserRole.superAdmin;

    switch (currentTab) {
      case 0:
        if (!isSuperAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Courses are managed by Super Admin.')),
          );
          return;
        }
        _showAddCourseDialog();
        break;
      case 1:
        _showAddNoticeDialog();
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAddStudentScreen()),
        ).then((_) => _loadData());
        break;
      case 3:
        _showAddDownloadDialog();
        break;
    }
  }

  void _showAddCourseDialog() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const AdminCourseFormScreen()),
    ).then((_) => _loadData());
  }

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');
    final contentController = TextEditingController();
    bool showAuthor = false; // Default to hiding author

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 24,
            right: 24,
          ),
          // FIX: Added SingleChildScrollView to prevent overflow when keyboard is open
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Post New Notice',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notice Headline',
                    prefixIcon: Icon(Icons.campaign_outlined),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.tag),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Notice Content',
                    prefixIcon: Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                // Show Author Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Show Author Name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Users will see who posted this notice',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: showAuthor,
                  onChanged: (val) {
                    setState(() => showAuthor = val);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Save as Draft Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty) {
                            await ref
                                .read(adminRepositoryProvider)
                                .addNotice(
                                  title: titleController.text,
                                  category: categoryController.text,
                                  content: contentController.text,
                                  status: 'draft',
                                  showAuthor: showAuthor,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved as Draft')),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'Save as Draft',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Publish Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty) {
                            await ref
                                .read(adminRepositoryProvider)
                                .addNotice(
                                  title: titleController.text,
                                  category: categoryController.text,
                                  content: contentController.text,
                                  status: 'published',
                                  showAuthor: showAuthor,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notice Published'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Publish Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDownloadDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Forms');
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Download',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'File Title',
                prefixIcon: Icon(Icons.insert_drive_file_outlined),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.folder_open_outlined),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Download URL',
                prefixIcon: Icon(Icons.link),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      urlController.text.isNotEmpty) {
                    await ref
                        .read(adminRepositoryProvider)
                        .addDownload(
                          title: titleController.text,
                          category: categoryController.text,
                          url: urlController.text,
                        );
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Download',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // EDIT DIALOGS
  // ===========================================

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name']);
    final emailController = TextEditingController(text: student['email']);
    final phoneController = TextEditingController(text: student['phone']);
    final regNoController = TextEditingController(
      text: student['registration_number'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Student',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                filled: true,
                fillColor: Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regNoController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                prefixIcon: Icon(Icons.badge_outlined),
                filled: true,
                fillColor: Color(0xFFEEEEEE),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              enabled: false,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .updateStudent(
                            id: student['id'].toString(),
                            name: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                          );
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating student: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Student',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // EDIT DIALOGS
  // ===========================================
  void _showEditCourseDialog(Map<String, dynamic> course) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => AdminCourseFormScreen(course: course)),
    ).then((_) => _loadData());
  }

  void _showEditNoticeDialog(Map<String, dynamic> notice) {
    final titleController = TextEditingController(text: notice['title']);
    final categoryController = TextEditingController(text: notice['category']);
    final contentController = TextEditingController(text: notice['content']);
    // Load initial values, defaulting if null
    bool showAuthor = notice['show_author'] == true;
    String status = notice['status'] ?? 'published';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Notice',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.campaign_outlined),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.tag),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    prefixIcon: Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                    filled: true,
                    fillColor: Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: ['published', 'draft']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => status = v);
                  },
                ),
                const SizedBox(height: 12),
                // Show Author Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Show Author Name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  value: showAuthor,
                  onChanged: (val) {
                    setState(() => showAuthor = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(adminRepositoryProvider)
                          .updateNotice(
                            id: notice['id'].toString(),
                            title: titleController.text,
                            category: categoryController.text,
                            content: contentController.text,
                            status: status,
                            showAuthor: showAuthor,
                          );
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.person_outline, 'Name', student['name']),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email_outlined, 'Email', student['email']),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.badge_outlined,
              'Reg No',
              student['registration_number'] ?? student['reg_no'],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.phone_outlined, 'Phone', student['phone'] ?? student['contact']),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.school_outlined,
              'Course ID',
              student['course_id'] ?? 'Not enrolled',
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    final displayValue = (value == null || value.toString().trim().isEmpty)
        ? 'N/A'
        : value.toString().trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
