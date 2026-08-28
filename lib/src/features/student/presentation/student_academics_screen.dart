import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import '../../exams/presentation/exam_list_screen.dart';
import 'student_test_list_screen.dart';
import 'student_exam_report_screen.dart';
import '../../documents/presentation/my_documents_screen.dart';

class StudentAcademicsScreen extends ConsumerStatefulWidget {
  const StudentAcademicsScreen({super.key});

  @override
  ConsumerState<StudentAcademicsScreen> createState() => _StudentAcademicsScreenState();
}

class _StudentAcademicsScreenState extends ConsumerState<StudentAcademicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text(
          'Academics Hub',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.inkNavy800,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.goldCta,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.goldCta,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Online Tests'),
            Tab(text: 'Exams'),
            Tab(text: 'Exam Report'),
            Tab(text: 'Study Material'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OnlineTestsTab(),
          const _ExamsTab(),
          const _ExamReportTab(),
          const _StudyMaterialTab(),
          const _DocumentsTab(),
        ],
      ),
    );
  }
}

class _OnlineTestsTab extends StatelessWidget {
  const _OnlineTestsTab();
  @override
  Widget build(BuildContext context) {
    // Uses the new separated tests screen (to be created)
    return const StudentTestListGrid(assessmentType: 'test');
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab();
  @override
  Widget build(BuildContext context) {
    // Uses the new separated exams screen (to be created)
    return const StudentTestListGrid(assessmentType: 'exam');
  }
}

class _ExamReportTab extends StatelessWidget {
  const _ExamReportTab();
  @override
  Widget build(BuildContext context) {
    return const StudentExamReportGrid();
  }
}

// Removed _AssessmentsTab since it is replaced by Tests and Exams

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();
  
  @override
  Widget build(BuildContext context) {
    // We use the exact body from MyDocumentsScreen
    return const MyDocumentsBody();
  }
}

class _StudyMaterialTab extends StatelessWidget {
  const _StudyMaterialTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.inkNavy800,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Study Material',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Course materials will appear here\nonce uploaded by your teachers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
