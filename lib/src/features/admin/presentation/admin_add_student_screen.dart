import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class AdminAddStudentScreen extends ConsumerStatefulWidget {
  const AdminAddStudentScreen({super.key});

  @override
  ConsumerState<AdminAddStudentScreen> createState() =>
      _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends ConsumerState<AdminAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();

  String? _courseId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regController.dispose();
    _phoneController.dispose();
    _guardianController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .addStudentAdmission(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            registrationNumber: _regController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            courseId: _courseId,
            guardianName: _guardianController.text.trim().isEmpty
                ? null
                : _guardianController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            dateOfBirth: _dobController.text.trim().isEmpty
                ? null
                : _dobController.text.trim(),
          );

      ref.invalidate(adminStudentsProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to add student: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesFuture = ref.watch(adminCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'Add Student',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _regController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Registration number is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              coursesFuture.when(
                data: (courses) => DropdownButtonFormField<String>(
                  value: _courseId,
                  decoration: const InputDecoration(
                    labelText: 'Course (optional)',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: courses
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['title']?.toString() ?? 'Untitled'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _courseId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'Could not load courses. You can continue without selecting one.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _guardianController,
                decoration: const InputDecoration(
                  labelText: 'Guardian Name (optional)',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth YYYY-MM-DD (optional)',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _saveStudent,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
