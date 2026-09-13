import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class AdminAddStudentScreen extends ConsumerStatefulWidget {
  const AdminAddStudentScreen({super.key, this.preselectedCourseId});

  final String? preselectedCourseId;

  @override
  ConsumerState<AdminAddStudentScreen> createState() =>
      _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends ConsumerState<AdminAddStudentScreen> {
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
  final _genderController = TextEditingController(text: 'Male');
  final _categoryController = TextEditingController(text: 'General');
  final _religionController = TextEditingController(text: 'Hindu');
  final _maritalController = TextEditingController();
  final _disabilityController = TextEditingController(text: 'No');
  final _occupationController = TextEditingController();

  // Identification & Address
  final _idTypeController = TextEditingController(text: 'Aadhaar Card');
  final _idNumberController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _passingYearController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _stateController = TextEditingController(text: 'Uttar Pradesh');
  final _districtController = TextEditingController(text: 'Varanasi');
  final _pincodeController = TextEditingController();

  // Course Details
  final _admissionYearController = TextEditingController(text: DateTime.now().year.toString());
  final _admissionDateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  final _discountController = TextEditingController(text: '0');
  final _otherChargeController = TextEditingController(text: '0');
  final _netFeeController = TextEditingController();
  final _batchController = TextEditingController();
  final _enquirySourceController = TextEditingController();

  String? _courseId;
  double _standardCourseFee = 0.0;
  bool _isSubmitting = false;

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  // Static Dropdown Data
  static const List<String> kGenderList = ['Male', 'Female', 'Other'];
  static const List<String> kCategoryList = ['General', 'OBC', 'SC', 'ST', 'EWS'];
  static const List<String> kReligionList = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Other'];
  static const List<String> kIdentityTypeList = ['Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport', 'Driving License', 'Student ID', 'Other'];

  static const List<String> kIndianStates = [
    'Uttar Pradesh',
    'Bihar',
    'Madhya Pradesh',
    'Delhi',
    'Rajasthan',
    'Haryana',
    'Jharkhand',
    'Uttarakhand',
    'West Bengal',
    'Maharashtra',
    'Gujarat',
    'Punjab',
    'Chhattisgarh',
    'Himachal Pradesh',
    'Odisha',
    'Assam',
    'Andhra Pradesh',
    'Telangana',
    'Tamil Nadu',
    'Karnataka',
    'Kerala',
    'Goa',
    'Jammu & Kashmir',
    'Chandigarh',
    'Other',
  ];

  static const Map<String, List<String>> kStateDistricts = {
    'Uttar Pradesh': [
      'Varanasi', 'Lucknow', 'Prayagraj', 'Kanpur', 'Gorakhpur', 'Agra',
      'Meerut', 'Ghaziabad', 'Noida (G.B. Nagar)', 'Ayodhya', 'Bareilly',
      'Aligarh', 'Jhansi', 'Mirzapur', 'Jaunpur', 'Ghazipur', 'Chandauli',
      'Ballia', 'Bhadohi', 'Sonbhadra', 'Azamgarh', 'Mau', 'Deoria',
      'Mathura', 'Moradabad', 'Saharanpur', 'Faizabad', 'Other'
    ],
    'Bihar': [
      'Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga', 'Purnia',
      'Rohtas', 'Bhojpur', 'Buxar', 'Siwan', 'Saran (Chapra)', 'Nalanda',
      'Vaishali', 'Begusarai', 'Samastipur', 'Motihari', 'Katihar', 'Other'
    ],
    'Madhya Pradesh': [
      'Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar',
      'Rewa', 'Satna', 'Singrauli', 'Katni', 'Dewas', 'Other'
    ],
    'Delhi': [
      'Central Delhi', 'East Delhi', 'New Delhi', 'North Delhi',
      'North East Delhi', 'North West Delhi', 'South Delhi',
      'South East Delhi', 'South West Delhi', 'West Delhi', 'Shahdara', 'Other'
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Kota', 'Udaipur', 'Bikaner', 'Ajmer',
      'Alwar', 'Bhilwara', 'Sikar', 'Bharatpur', 'Other'
    ],
    'Haryana': [
      'Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Hisar',
      'Karnal', 'Rohtak', 'Sonipat', 'Panchkula', 'Other'
    ],
    'Jharkhand': [
      'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar',
      'Hazaribagh', 'Giridih', 'Ramgarh', 'Other'
    ],
    'Uttarakhand': [
      'Dehradun', 'Haridwar', 'Nainital', 'Rishikesh', 'Haldwani',
      'Roorkee', 'Udham Singh Nagar', 'Other'
    ],
    'West Bengal': [
      'Kolkata', 'Howrah', 'North 24 Parganas', 'South 24 Parganas',
      'Hooghly', 'Darjeeling', 'Siliguri', 'Asansol', 'Other'
    ],
  };

  // Static Course Fees Decided by Superadmin
  static const Map<String, double> kSuperAdminCourseFees = {
    'dca': 6500.0,
    'adca': 12000.0,
    'o-level': 15000.0,
    'ccc': 3500.0,
    'pgdca': 18000.0,
    'tally': 6000.0,
    'tally prime': 6500.0,
    'dtp': 5000.0,
    'web designing': 14000.0,
    'web development': 16000.0,
    'python': 8000.0,
    'java': 8500.0,
    'c/c++': 5000.0,
    'graphic design': 12000.0,
    'basic computer': 3000.0,
    'hardware & networking': 15000.0,
    'diploma': 8000.0,
    'vocational': 9000.0,
    'yoga': 7500.0,
  };

  static double getSuperAdminFee(String courseName) {
    final lower = courseName.toLowerCase().trim();
    for (final entry in kSuperAdminCourseFees.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 7500.0; // Standard default course fee decided by Superadmin
  }

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCourseId != null) {
      _courseId = widget.preselectedCourseId;
    }
    _discountController.addListener(_calculateNetFee);
    _otherChargeController.addListener(_calculateNetFee);
  }

  @override
  void dispose() {
    _discountController.removeListener(_calculateNetFee);
    _otherChargeController.removeListener(_calculateNetFee);
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

  void _onCourseSelected(Map<String, dynamic> course) {
    final title = (course['title'] ?? course['name'] ?? '').toString();
    final rawFee = course['fee'] ?? course['total_fee'] ?? course['course_fee'];
    double fee = 0.0;
    if (rawFee != null) {
      fee = double.tryParse(rawFee.toString()) ?? getSuperAdminFee(title);
    } else {
      fee = getSuperAdminFee(title);
    }

    setState(() {
      _courseId = course['id'].toString();
      _standardCourseFee = fee;
      _calculateNetFee();
    });
  }

  void _calculateNetFee() {
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final otherCharge = double.tryParse(_otherChargeController.text.trim()) ?? 0.0;
    final net = (_standardCourseFee - discount + otherCharge).clamp(0.0, double.infinity);
    _netFeeController.text = net.toStringAsFixed(0);
  }

  List<String> _getDistricts(String state) {
    if (kStateDistricts.containsKey(state)) {
      return kStateDistricts[state]!;
    }
    return ['Central', 'North', 'South', 'East', 'West', 'Other'];
  }

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

  Future<void> _selectDate({
    required TextEditingController controller,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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

      String? photoUrl;
      if (_imageBytes != null && _selectedImage != null) {
        photoUrl = await repo.uploadProfilePhoto(_selectedImage!.name, _imageBytes!);
      }

      await repo.addStudentAdmission(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        courseId: _courseId,
        guardianName: _fatherNameController.text.trim(),
        address: "${_currentAddressController.text.trim()} ${_districtController.text.trim()} ${_stateController.text.trim()} ${_pincodeController.text.trim()}".trim(),
        dateOfBirth: _dobController.text.trim(),
        photoUrl: photoUrl,
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
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Section
              _buildSectionHeader('Course Details', Icons.school_rounded),
              const SizedBox(height: 12),
              _buildCourseDetailsStep(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Personal Section
              _buildSectionHeader('Personal Details', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildPersonalDetailsStep(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Address & Identification Section
              _buildSectionHeader('Address & Identification', Icons.badge_rounded),
              const SizedBox(height: 12),
              _buildAddressDetailsStep(),

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Registration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.goldCta),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDetailsStep() {
    final coursesAsync = ref.watch(adminCoursesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Admission Year *', _admissionYearController, isRequired: true)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _admissionDateController,
                readOnly: true,
                onTap: () => _selectDate(
                  controller: _admissionDateController,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                ),
                decoration: _fieldInputDecoration(
                  'Date of Admission *',
                  suffixIcon: const Icon(Icons.calendar_month, size: 18, color: AppColors.goldCta),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        coursesAsync.when(
          data: (courses) {
            // Deduplicate items by id to ensure safe render
            final uniqueCourses = <String, Map<String, dynamic>>{};
            for (final c in courses) {
              final id = c['id']?.toString() ?? '';
              if (id.isNotEmpty && !uniqueCourses.containsKey(id)) {
                uniqueCourses[id] = c;
              }
            }
            final courseList = uniqueCourses.values.toList();

            return DropdownButtonFormField<String>(
              isExpanded: true,
              value: uniqueCourses.containsKey(_courseId) ? _courseId : null,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Course *',
                helperText: _standardCourseFee > 0
                    ? 'Official Fee: ₹${_standardCourseFee.toStringAsFixed(0)} (Decided by Superadmin)'
                    : 'Select course to auto-fill official Superadmin fee',
                helperStyle: TextStyle(
                  color: _standardCourseFee > 0 ? AppColors.goldDeep : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              items: courseList.map((course) {
                final id = course['id'].toString();
                final title = (course['title'] ?? course['name'] ?? 'Course').toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final match = courseList.firstWhere(
                  (c) => c['id'].toString() == val,
                  orElse: () => {'id': val, 'name': 'Course'},
                );
                _onCourseSelected(match);
              },
              validator: (v) => v == null ? 'Required' : null,
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(color: AppColors.goldCta),
          )),
          error: (_, __) => const Text('Failed to load courses', style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _netFeeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                decoration: _fieldInputDecoration('Net Fee (₹) *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: _fieldInputDecoration('Discount (₹)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _otherChargeController,
                keyboardType: TextInputType.number,
                decoration: _fieldInputDecoration('Other Charge (₹)'),
              ),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 90,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: AppColors.goldCta, size: 28),
                          SizedBox(height: 4),
                          Text('Upload Photo', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Upload passport photo (.jpg / .jpeg / .png, < 500KB)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Student Name *', _nameController, isRequired: true)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(
                  controller: _dobController,
                  initialDate: DateTime(2005),
                  firstDate: DateTime(1960),
                  lastDate: DateTime.now(),
                ),
                decoration: _fieldInputDecoration(
                  'Date of Birth *',
                  suffixIcon: const Icon(Icons.calendar_month, size: 18, color: AppColors.goldCta),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Father\'s Name *', _fatherNameController, isRequired: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Mother\'s Name', _motherNameController)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Contact No *', _phoneController, isRequired: true, keyboardType: TextInputType.phone)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Email Id *', _emailController, isRequired: true, keyboardType: TextInputType.emailAddress)),
          ],
        ),
        const SizedBox(height: 14),
        // Dropdowns for Gender, Category, Religion
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Gender',
                value: _genderController.text,
                items: kGenderList,
                isRequired: true,
                onChanged: (val) {
                  if (val != null) setState(() => _genderController.text = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdownField(
                label: 'Category',
                value: _categoryController.text,
                items: kCategoryList,
                onChanged: (val) {
                  if (val != null) setState(() => _categoryController.text = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdownField(
                label: 'Religion',
                value: _religionController.text,
                items: kReligionList,
                onChanged: (val) {
                  if (val != null) setState(() => _religionController.text = val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressDetailsStep() {
    final currentDistricts = _getDistricts(_stateController.text);

    return Column(
      children: [
        // Dropdown for Identity Type & Id Number
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDropdownField(
                label: 'Identity Type',
                value: _idTypeController.text,
                items: kIdentityTypeList,
                onChanged: (val) {
                  if (val != null) setState(() => _idTypeController.text = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _buildTextField('Id / Card Number', _idNumberController),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Current Address', _currentAddressController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Permanent Address', _permanentAddressController)),
          ],
        ),
        const SizedBox(height: 14),
        // Dropdowns for State and District
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _buildDropdownField(
                label: 'State',
                value: _stateController.text,
                items: kIndianStates,
                isRequired: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _stateController.text = val;
                      final newDistricts = _getDistricts(val);
                      _districtController.text = newDistricts.first;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _buildDropdownField(
                label: 'District',
                value: currentDistricts.contains(_districtController.text)
                    ? _districtController.text
                    : currentDistricts.first,
                items: currentDistricts,
                isRequired: true,
                onChanged: (val) {
                  if (val != null) setState(() => _districtController.text = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildTextField('Pincode', _pincodeController, keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Highest Qualification', _qualificationController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Passing Year', _passingYearController, keyboardType: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isRequired = false,
  }) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: validValue,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  InputDecoration _fieldInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      isDense: true,
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13.5, color: Colors.black87),
      decoration: _fieldInputDecoration(label),
      validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}
