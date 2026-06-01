import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class StudentAcademicsScreen extends ConsumerStatefulWidget {
  const StudentAcademicsScreen({super.key});

  @override
  ConsumerState<StudentAcademicsScreen> createState() =>
      _StudentAcademicsScreenState();
}

class _StudentAcademicsScreenState extends ConsumerState<StudentAcademicsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryColor = const Color(0xFF135bec);
  final Color _bgLight = const Color(0xFFf6f6f8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(studentAcademicCalendarProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Academics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.goldCta,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.goldCta,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Updates'),
          ],
        ),
      ),
      body: calendarAsync.when(
        data: (items) => TabBarView(
          controller: _tabController,
          children: [
            _buildWorkList(items.where((item) => item['type'] == 'exam').toList(), 'Academic Calendar'),
            _buildWorkList(items.where((item) => item['type'] != 'exam').toList(), 'Updates'),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
        error: (error, _) => Center(
          child: Text('Unable to load academics: $error', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Widget _buildWorkList(List<Map<String, dynamic>> items, String emptyLabel) {
    if (items.isEmpty) {
      return Center(
        child: Text('No $emptyLabel items available', style: const TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final title = (item['text'] ?? item['title'] ?? 'Update').toString();
        final due = (item['date'] ?? 'TBA').toString();
        final color = item['type'] == 'exam' ? Colors.blue : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF112A16),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title.isNotEmpty ? title[0] : '?',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['type'] == 'exam' ? 'Exam' : 'Notice',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(due, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['type'] == 'exam' ? 'Exam' : 'Notice',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
