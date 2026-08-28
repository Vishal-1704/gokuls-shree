import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/teacher/presentation/widgets/teacher_employment_details.dart';

class TeacherEmploymentDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic>? emp;

  const TeacherEmploymentDetailsScreen({super.key, required this.emp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.inkNavy900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: TeacherEmploymentDetails(emp: emp),
      ),
    );
  }
}
