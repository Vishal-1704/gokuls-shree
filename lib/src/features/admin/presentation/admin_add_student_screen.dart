import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _emailController = TextEditingController();

  // Additional Info
  final _genderController = TextEditingController();
  final _categoryController = TextEditingController();
  final _religionController = TextEditingController();
  final _maritalController = TextEditingController();
  final _disabilityController = TextEditingController(text: 'No');
  final _occupationController = TextEditingController();

  // Identification & Address
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _passingYearController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Course Details
  final _admissionYearController = TextEditingController(text: DateTime.now().year.toString());
  final _admissionDateController = TextEditingController();
  final _discountController = TextEditingController();
  final _otherChargeController = TextEditingController();
  final _netFeeController = TextEditingController();
  final _batchController = TextEditingController();
  final _enquirySourceController = TextEditingController();

  String? _courseId;
  String? _courseCategory;
  bool _isSubmitting = false;

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _parentContactController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _categoryController.dispose();
    _religionController.dispose();
    _maritalController.dispose();
    _disabilityController.dispose();
    _occupationController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _qualificationController.dispose();
    _passingYearController.dispose();
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _admissionYearController.dispose();
    _admissionDateController.dispose();
    _discountController.dispose();
    _otherChargeController.dispose();
    _netFeeController.dispose();
    _batchController.dispose();
    _enquirySourceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      
      // Upload image logic goes here if needed, but for now we pass photoUrl if we have one.
      // Assuming a generic addStudentAdmission for now.
      await repo.addStudentAdmission(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        courseId: _courseId,
        guardianName: _fatherNameController.text.trim(),
        address: _currentAddressController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        // Note: Legacy fields like disability, occupation, state, etc. can be added to the payload if schema supports them.
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student registered successfully. If you are a Branch Admin, this student is now Pending Approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Course Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFC02A4E))),
              const SizedBox(height: 12),
              _buildCourseDetailsStep(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFC02A4E))),
              const SizedBox(height: 12),
              _buildPersonalDetailsStep(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              const Text('Address & Identification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFC02A4E))),
              const SizedBox(height: 12),
              _buildAddressDetailsStep(),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Registration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailsStep() {
    final coursesAsync = ref.watch(adminCoursesProvider);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Admission Year *', _admissionYearController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Date of Admission *', _admissionDateController, icon: Icons.calendar_month)),
          ],
        ),
        const SizedBox(height: 16),
        coursesAsync.when(
          data: (courses) {
            return DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Course *',
                border: OutlineInputBorder(),
              ),
              value: _courseId,
              items: courses.map((course) {
                return DropdownMenuItem<String>(
                  value: course['id'].toString(),
                  child: Text(course['name'] ?? 'Unknown Course'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _courseId = val),
              validator: (v) => v == null ? 'Required' : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load courses'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Net Fee', _netFeeController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Discount', _discountController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Other Charge', _otherChargeController)),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsStep() {
    return Column(
      children: [
        // Photo picker row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.grey.shade100,
                ),
                child: _imageBytes != null 
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover) 
                  : const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Text('Photo must be in .jpg/.jpeg/.bmp and size less than 500KB', style: TextStyle(color: Colors.red, fontSize: 12))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Student Name *', _nameController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Date of Birth *', _dobController, icon: Icons.calendar_month, isRequired: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Father\'s Name *', _fatherNameController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Mother\'s Name', _motherNameController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Contact No *', _phoneController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Email Id *', _emailController, isRequired: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Gender *', _genderController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Category', _categoryController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Religion', _religionController)),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressDetailsStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Identity Type', _idTypeController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Id Number', _idNumberController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Current Address', _currentAddressController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Permanent Address', _permanentAddressController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('State *', _stateController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('District *', _districtController, isRequired: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Pincode', _pincodeController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Qualification', _qualificationController)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Passing Year', _passingYearController)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }
}
