import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/widgets/app_image.dart';
import 'package:gokul_shree_app/src/features/courses/domain/course_entity.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Our Programmes'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.secondaryColor,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              _buildTab('Diploma', Icons.computer),
              _buildTab('Vocational', Icons.build_outlined),
              _buildTab('University', Icons.school_outlined),
              _buildTab('Yoga', Icons.self_improvement),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SupabaseCourseList(category: 'Diploma', ref: ref),
            _SupabaseCourseList(category: 'Vocational', ref: ref),
            _SupabaseCourseList(category: 'University', ref: ref),
            _SupabaseCourseList(category: 'Yoga', ref: ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _SupabaseCourseList extends StatelessWidget {
  final String category;
  final WidgetRef ref;

  const _SupabaseCourseList({required this.category, required this.ref});

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(supabaseCoursesProvider(category));

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return _buildEmptyState();
        }

        // Convert Supabase data to Course objects
        final courseList = courses
            .map(
              (json) => Course(
                id: json['id'].toString(),
                title: json['title'] as String? ?? 'Untitled',
                category: json['category'] as String? ?? category,
                duration: json['duration'] as String? ?? 'N/A',
                eligibility: json['eligibility'] as String?,
                imagePath: json['image_url'] as String? ?? '',
              ),
            )
            .toList();

        return _CourseListView(courses: courseList, category: category);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Supabase courses error: $error');
        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CourseImageHelper.getCategoryIcon(category),
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No $category courses available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _CourseListView extends StatelessWidget {
  final List<Course> courses;
  final String category;

  const _CourseListView({required this.courses, required this.category});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _CourseCard(course: course, category: category);
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final String category;

  const _CourseCard({required this.course, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with category gradient fallback
          CourseImage(
            imageUrl: course.imagePath.isNotEmpty ? course.imagePath : null,
            category: category,
            height: 140,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Title
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Duration and Eligibility Row
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time,
                      course.duration,
                      CourseImageHelper.getCategoryColor(category),
                    ),
                    const SizedBox(width: 12),
                    if (course.eligibility != null)
                      Expanded(
                        child: _buildInfoChip(
                          Icons.school_outlined,
                          course.eligibility!,
                          Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to course details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourseImageHelper.getCategoryColor(
                        category,
                      ),
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
