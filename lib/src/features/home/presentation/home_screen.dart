import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/data/mock_repository.dart';
import 'package:gokul_shree_app/src/core/data/attendance_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/widgets/webview_screen.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAttendanceMeter(String? studentId) {
    if (studentId == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, _) {
        final attendanceAsync = ref.watch(
          studentOverallAttendanceProvider(studentId),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular Progress Indicator
                attendanceAsync.when(
                  data: (percentage) {
                    final color = percentage >= 75
                        ? Colors.green
                        : percentage >= 50
                        ? Colors.orange
                        : Colors.red;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      attendanceAsync.when(
                        data: (percentage) => Text(
                          percentage >= 75
                              ? 'Great job! Keep it up!'
                              : percentage >= 50
                              ? 'Needs improvement'
                              : 'Critical - attend more classes!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        error: (_, __) => const Text(
                          'Unable to load',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => context.push('/dashboard'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // Show search results in a modal or navigate to search results
    _showSearchResults(query.trim());
  }

  void _showSearchResults(String query) {
    final mockRepo = ref.read(mockRepositoryProvider);
    final courses = mockRepo.getCourses();

    // Filter courses by search query
    final matchingCourses = courses
        .where(
          (course) =>
              course.title.toLowerCase().contains(query.toLowerCase()) ||
              course.category.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Results for "$query"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${matchingCourses.length} found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: matchingCourses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No courses found for "$query"',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/courses');
                            },
                            child: const Text('Browse All Courses'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: matchingCourses.length,
                      itemBuilder: (context, index) {
                        final course = matchingCourses[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(course.title),
                          subtitle: Text(
                            '${course.category} • ${course.duration}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/courses');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HomeScreen build started');
    // Check auth state for personalized greeting
    final authState = ref.watch(supabaseAuthProvider);
    final isLoggedIn = authState is AuthAuthenticated;

    if (isLoggedIn) {
      return _buildStudentDashboard(context, authState);
    }

    return _buildPublicHome(context);
  }

  // STUDNET DASHBOARD
  Widget _buildStudentDashboard(
    BuildContext context,
    AuthAuthenticated authState,
  ) {
    // Get user info
    final user = authState.user;
    final studentData = authState.studentData;
    final userName = user.userMetadata?['name'] as String? ?? 'Student';
    final courseName =
        studentData?['course_name'] as String? ??
        'Computer Fundamentals'; // Mock Course

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Student Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Image.asset(
                              'assets/images/school_logo.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Enrolled Course Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          courseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Attendance & Stats
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Attendance",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceMeter(studentData?['id']?.toString() ?? '1'),
                ],
              ),
            ),

            // 3. Quick Actions Grid (Student Focused)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _QuickActionCard(
                    icon: Icons.timer,
                    label: 'Online Exams',
                    color: Colors.blue,
                    onTap: () => context.go('/exams'),
                  ),
                  _QuickActionCard(
                    icon: Icons.book,
                    label: 'Study Material',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InAppWebViewScreen(
                          title: 'Study Material',
                          url: WebUrls
                              .downloads, // Using downloads as mock study material
                        ),
                      ),
                    ),
                  ),
                  _QuickActionCard(
                    icon: Icons.assignment_turned_in,
                    label: 'My Results',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InAppWebViewScreen(
                          title: 'Results',
                          url: WebUrls.results,
                        ),
                      ),
                    ),
                  ),
                  _QuickActionCard(
                    icon: Icons.live_tv,
                    label: 'Live Classes',
                    color: Colors.red,
                    onTap: () {}, // Future feature
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // PUBLIC HOME (Original)
  Widget _buildPublicHome(BuildContext context) {
    final noticesAsync = ref.watch(supabaseNoticesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Banner Area (Mocked for brevity, copying structure)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gokul Shree',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'School of Management',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hello,',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Future Leader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSubmitted: _performSearch,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search courses...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Quick Actions (Public)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _QuickActionCard(
                    icon: Icons.school_outlined,
                    label: 'Courses',
                    color: Colors.blueAccent,
                    onTap: () => context.go('/courses'),
                  ),
                  _QuickActionCard(
                    icon: Icons.person_outline,
                    label: 'Student\nLogin',
                    color: Colors.orange,
                    onTap: () => context.go(
                      '/account',
                    ), // Redirect to Account handling login
                  ),
                  _QuickActionCard(
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InAppWebViewScreen(
                          title: 'Downloads',
                          url: WebUrls.downloads,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Latest Notices Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Notices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllNotices(context, noticesAsync),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Notices list with Supabase fallback
            noticesAsync.when(
              data: (notices) {
                if (notices.isEmpty) {
                  return _buildNoticesListFromMock(ref);
                }
                return _buildNoticesListFromSupabase(notices);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _buildNoticesListFromMock(ref),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAllNotices(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> noticesAsync,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'All Notices',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: noticesAsync.when(
                data: (notices) {
                  if (notices.isEmpty) {
                    // Fallback to mock if empty (or show empty state)
                    final mockRepo = ref.read(mockRepositoryProvider);
                    final mockNotices = mockRepo.getLatestNotices();
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: mockNotices.length,
                      itemBuilder: (context, index) {
                        final notice = mockNotices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.secondaryColor,
                              child: Icon(Icons.campaign, color: Colors.white),
                            ),
                            title: Text(notice.title),
                            subtitle: Text(
                              '${notice.date.day}/${notice.date.month}/${notice.date.year}',
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.secondaryColor,
                            child: Icon(Icons.campaign, color: Colors.white),
                          ),
                          title: Text(
                            notice['title'] as String? ?? 'Notice',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(notice['content'] as String? ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                notice['created_at'].toString().split('T')[0],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesListFromSupabase(List<Map<String, dynamic>> notices) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notices.length > 3 ? 3 : notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.campaign, color: AppTheme.secondaryColor),
            ),
            title: Text(
              notice['title'] as String? ?? 'Notice',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              notice['category'] as String? ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildNoticesListFromMock(WidgetRef ref) {
    final mockRepo = ref.read(mockRepositoryProvider);
    final notices = mockRepo.getLatestNotices();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notices.length > 3 ? 3 : notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.campaign, color: AppTheme.secondaryColor),
            ),
            title: Text(
              notice.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${notice.date.day}/${notice.date.month}/${notice.date.year}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

