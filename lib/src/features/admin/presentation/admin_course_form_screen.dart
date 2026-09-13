import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

class AdminCourseFormScreen extends ConsumerStatefulWidget {
  const AdminCourseFormScreen({
    super.key,
    this.course,
  });

  /// Null for creating a new course, non-null for editing.
  final Map<String, dynamic>? course;

  @override
  ConsumerState<AdminCourseFormScreen> createState() => _AdminCourseFormScreenState();
}

class _AdminCourseFormScreenState extends ConsumerState<AdminCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _durationController;
  late final TextEditingController _feeController;
  late final TextEditingController _eligibilityController;
  late final TextEditingController _totalClassesController;
  late final TextEditingController _totalMarksController;
  late final TextEditingController _passMarksController;
  late final TextEditingController _theoryMarksController;
  late final TextEditingController _practicalMarksController;
  late final TextEditingController _internalMarksController;
  late final TextEditingController _descriptionController;
  final TextEditingController _newRoleController = TextEditingController();

  final List<Map<String, TextEditingController>> _moduleControllers = [];
  final List<String> _careerRoles = [];

  bool _isLoading = false;

  final List<String> _categoryOptions = [
    'Diploma in Computer Applications',
    'Advanced Computer Diploma',
    'Financial Accounting & Tally',
    'Information Technology & Programming',
    'Vocational & Technical Training',
    'Yoga & Health Sciences',
    'Industrial & Fire Safety',
    'Management & Commerce',
    'Short-term Certification',
  ];

  final List<String> _commonRolesSuggestions = [
    'Computer Operator',
    'Data Entry Specialist',
    'Office Automation Executive',
    'Accounts Assistant',
    'Tally Executive',
    'Junior Web Designer',
    'Lab Technical Assistant',
    'IT Support Associate',
    'Yoga Instructor',
    'Safety Officer Assistant',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.course;

    final initialTitle = (c?['name'] ?? c?['title'] ?? '').toString();
    _titleController = TextEditingController(text: initialTitle);
    _shortNameController = TextEditingController(
      text: (c?['short_name'] ?? c?['code'] ?? '').toString(),
    );

    final currentCat = (c?['category'] ?? 'Diploma in Computer Applications').toString();
    _categoryController = TextEditingController(text: currentCat);

    _durationController = TextEditingController(
      text: (c?['duration'] ?? '12 Months').toString(),
    );

    final rawFee = c?['fee'];
    _feeController = TextEditingController(
      text: rawFee != null && rawFee.toString() != '0' && rawFee.toString() != '0.0'
          ? rawFee.toString().replaceAll(RegExp(r'\.0+$'), '')
          : '',
    );

    _eligibilityController = TextEditingController(
      text: (c?['eligibility'] ?? '10th / 12th Pass from recognized board').toString(),
    );

    _totalClassesController = TextEditingController(
      text: (c?['total_classes'] ?? 120).toString(),
    );

    final rawTotal = (c?['total_marks'] as num?)?.toInt() ?? 0;
    final totalMarks = rawTotal > 0 ? rawTotal : 100;
    _totalMarksController = TextEditingController(text: totalMarks.toString());

    final rawPass = (c?['pass_marks'] as num?)?.toInt() ?? 0;
    final passMarks = rawPass > 0 ? rawPass : (totalMarks * 0.4).round();
    _passMarksController = TextEditingController(text: passMarks.toString());

    final rawTheory = (c?['theory_marks'] as num?)?.toInt() ?? 0;
    final theoryMarks = rawTheory > 0 ? rawTheory : (totalMarks * 0.6).round();
    _theoryMarksController = TextEditingController(text: theoryMarks.toString());

    final rawPractical = (c?['practical_marks'] as num?)?.toInt() ?? 0;
    final practicalMarks = rawPractical > 0 ? rawPractical : (totalMarks * 0.3).round();
    _practicalMarksController = TextEditingController(text: practicalMarks.toString());

    final rawInternal = (c?['internal_marks'] as num?)?.toInt() ?? 0;
    final internalMarks = rawInternal > 0 ? rawInternal : (totalMarks - theoryMarks - practicalMarks);
    _internalMarksController = TextEditingController(text: internalMarks.toString());

    _descriptionController = TextEditingController(
      text: (c?['description'] ?? '').toString(),
    );

    // Parse existing syllabus or populate standard modules
    _initModules(c);

    // Parse career opportunities
    _initCareerRoles(c);
  }

  void _initModules(Map<String, dynamic>? c) {
    List<dynamic> rawModules = [];
    if (c != null) {
      if (c['syllabus'] is List) {
        rawModules = c['syllabus'] as List;
      } else if (c['syllabus'] is String && (c['syllabus'] as String).trim().startsWith('[')) {
        try {
          rawModules = jsonDecode(c['syllabus'] as String) as List;
        } catch (_) {}
      }
    }

    if (rawModules.isNotEmpty) {
      for (final mod in rawModules) {
        if (mod is Map) {
          _addModule(
            title: mod['title']?.toString() ?? '',
            topics: mod['topics']?.toString() ?? '',
          );
        }
      }
    } else {
      // Default 3 sample module outlines to help admin start quickly
      _addModule(
        title: 'Module 1: Computer Fundamentals & OS',
        topics: 'Hardware concepts, Windows OS, File Management, System Tools & Utilities',
      );
      _addModule(
        title: 'Module 2: Office Automation & Productivity',
        topics: 'Word Processing, Spreadsheets (Excel Formulas, VLOOKUP), PowerPoint Presentations',
      );
      _addModule(
        title: 'Module 3: Internet, Cyber Awareness & Project',
        topics: 'Web Browsing, Email Protocols, Cyber Security Hygiene, Practical Lab Capstone',
      );
    }
  }

  void _initCareerRoles(Map<String, dynamic>? c) {
    if (c != null) {
      if (c['career_opportunities'] is List) {
        for (final r in c['career_opportunities'] as List) {
          if (r != null && r.toString().trim().isNotEmpty) {
            _careerRoles.add(r.toString().trim());
          }
        }
      } else if (c['career_opportunities'] is String) {
        final str = c['career_opportunities'] as String;
        if (str.trim().startsWith('[')) {
          try {
            final list = jsonDecode(str) as List;
            for (final r in list) {
              if (r != null && r.toString().trim().isNotEmpty) {
                _careerRoles.add(r.toString().trim());
              }
            }
          } catch (_) {}
        } else {
          for (final r in str.split(',')) {
            if (r.trim().isNotEmpty) _careerRoles.add(r.trim());
          }
        }
      }
    }

    if (_careerRoles.isEmpty) {
      _careerRoles.addAll([
        'Computer Operator',
        'Data Entry Specialist',
        'Office Automation Executive',
      ]);
    }
  }

  void _addModule({String title = '', String topics = ''}) {
    setState(() {
      _moduleControllers.add({
        'title': TextEditingController(text: title),
        'topics': TextEditingController(text: topics),
      });
    });
  }

  void _removeModule(int index) {
    setState(() {
      final removed = _moduleControllers.removeAt(index);
      removed['title']?.dispose();
      removed['topics']?.dispose();
    });
  }

  void _addCareerRole(String role) {
    final trimmed = role.trim();
    if (trimmed.isEmpty || _careerRoles.contains(trimmed)) return;
    setState(() {
      _careerRoles.add(trimmed);
      _newRoleController.clear();
    });
  }

  void _removeCareerRole(String role) {
    setState(() {
      _careerRoles.remove(role);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortNameController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    _eligibilityController.dispose();
    _totalClassesController.dispose();
    _totalMarksController.dispose();
    _passMarksController.dispose();
    _theoryMarksController.dispose();
    _practicalMarksController.dispose();
    _internalMarksController.dispose();
    _descriptionController.dispose();
    _newRoleController.dispose();

    for (final c in _moduleControllers) {
      c['title']?.dispose();
      c['topics']?.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final shortName = _shortNameController.text.trim();
    final category = _categoryController.text.trim();
    final duration = _durationController.text.trim();
    final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;
    final eligibility = _eligibilityController.text.trim();
    final totalClasses = int.tryParse(_totalClassesController.text.trim()) ?? 120;
    final totalMarks = int.tryParse(_totalMarksController.text.trim()) ?? 100;
    final passMarks = int.tryParse(_passMarksController.text.trim()) ?? 40;
    final theoryMarks = int.tryParse(_theoryMarksController.text.trim()) ?? (totalMarks * 0.6).round();
    final practicalMarks = int.tryParse(_practicalMarksController.text.trim()) ?? (totalMarks * 0.3).round();
    final internalMarks = int.tryParse(_internalMarksController.text.trim()) ?? (totalMarks - theoryMarks - practicalMarks);
    final description = _descriptionController.text.trim();

    final syllabusList = _moduleControllers.map((m) {
      return {
        'title': m['title']!.text.trim(),
        'topics': m['topics']!.text.trim(),
      };
    }).where((m) => m['title']!.isNotEmpty).toList();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      Map<String, dynamic> result;

      if (widget.course != null) {
        final courseId = widget.course!['id'].toString();
        result = await repo.updateCourse(
          id: courseId,
          title: title,
          shortName: shortName,
          category: category,
          duration: duration,
          fee: fee,
          eligibility: eligibility,
          description: description.isNotEmpty ? description : null,
          totalClasses: totalClasses,
          totalMarks: totalMarks,
          passMarks: passMarks,
          theoryMarks: theoryMarks,
          practicalMarks: practicalMarks,
          internalMarks: internalMarks,
          syllabus: syllabusList,
          careerOpportunities: _careerRoles,
        );
      } else {
        result = await repo.addCourse(
          title: title,
          shortName: shortName,
          category: category,
          duration: duration,
          fee: fee,
          eligibility: eligibility,
          description: description.isNotEmpty ? description : null,
          totalClasses: totalClasses,
          totalMarks: totalMarks,
          passMarks: passMarks,
          theoryMarks: theoryMarks,
          practicalMarks: practicalMarks,
          internalMarks: internalMarks,
          syllabus: syllabusList,
          careerOpportunities: _careerRoles,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.course != null ? 'Course updated successfully!' : 'Course published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save course: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Course Specifications' : 'Create New Course',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveCourse,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                  )
                : const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.goldCta),
            label: Text(
              isEditing ? 'Update' : 'Publish',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldCta, fontSize: 15),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCourse,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Publish Program',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Banner ──
              _buildHeaderBanner(isEditing),
              const SizedBox(height: 16),

              // ── 1. Basic Identification ──
              _buildSectionCard(
                title: '1. Course Identification',
                subtitle: 'Official course title, acronym, classification, and length',
                icon: Icons.school_rounded,
                iconColor: AppColors.primaryIndigo,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                      label: 'Course Full Title *',
                      hint: 'e.g., Advanced Diploma in Computer Applications',
                      icon: Icons.title_rounded,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter course title' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _shortNameController,
                          decoration: _inputDecoration(
                            label: 'Short Code / Acronym',
                            hint: 'e.g., ADCA, DCA',
                            icon: Icons.badge_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: _inputDecoration(
                            label: 'Duration *',
                            hint: 'e.g., 12 Months',
                            icon: Icons.timer_outlined,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter duration' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryOptions.contains(_categoryController.text)
                        ? _categoryController.text
                        : _categoryOptions.first,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: _inputDecoration(
                      label: 'Program Category',
                      icon: Icons.category_rounded,
                    ),
                    items: _categoryOptions.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _categoryController.text = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _totalClassesController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: 'Total Sessions / Lectures',
                      hint: 'e.g., 120 Sessions',
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 2. Fees & Eligibility ──
              _buildSectionCard(
                title: '2. Fee & Admission Criteria',
                subtitle: 'Commercial benchmark and student educational prerequisites',
                icon: Icons.currency_rupee_rounded,
                iconColor: AppColors.emeraldMint,
                children: [
                  TextFormField(
                    controller: _feeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      label: 'Program Benchmark Fee (₹) *',
                      hint: 'e.g., 12000',
                      icon: Icons.currency_rupee_rounded,
                      prefixText: '₹ ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please set course fee';
                      if (double.tryParse(val.trim()) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eligibilityController,
                    decoration: _inputDecoration(
                      label: 'Eligibility Prerequisite *',
                      hint: 'e.g., 10th / 12th Pass from recognized board',
                      icon: Icons.verified_user_outlined,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter eligibility' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 3. Examination & Marks Weightage ──
              _buildSectionCard(
                title: '3. Examination & Marks Distribution',
                subtitle: 'Passing threshold and assessment component breakdown',
                icon: Icons.assignment_turned_in_outlined,
                iconColor: AppColors.goldCta,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalMarksController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Total Marks',
                            hint: '100',
                            icon: Icons.score_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _passMarksController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Pass Threshold',
                            hint: '40',
                            icon: Icons.rule_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weightage Breakdown (Total 100%):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _theoryMarksController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(label: 'Theory', hint: '60'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _practicalMarksController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(label: 'Practical', hint: '30'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _internalMarksController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(label: 'Internal', hint: '10'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 4. Program Overview & Description ──
              _buildSectionCard(
                title: '4. Program Overview & Description',
                subtitle: 'Summary of what students will achieve upon completion',
                icon: Icons.description_outlined,
                iconColor: Colors.deepPurple,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      label: 'Course Description / Objectives',
                      hint: 'Provide a brief summary of pedagogical objectives and outcomes...',
                      icon: Icons.notes_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 5. Curriculum & Modules ──
              _buildSectionCard(
                title: '5. Curriculum & Syllabus Breakdown',
                subtitle: 'Add sequential modules and key topic bullet points',
                icon: Icons.menu_book_rounded,
                iconColor: Colors.blue.shade700,
                headerTrailing: TextButton.icon(
                  onPressed: () => _addModule(title: 'Module ${_moduleControllers.length + 1}: '),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.goldCta),
                  label: const Text('Add Module', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldCta)),
                ),
                children: [
                  if (_moduleControllers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'No modules added yet. Tap "Add Module" to specify syllabus items.',
                          style: TextStyle(fontSize: 12.5, color: Colors.brown),
                        ),
                      ),
                    )
                  else
                    ..._moduleControllers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final controllers = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${idx + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: AppColors.primaryIndigo,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: controllers['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Module Title (e.g., MS Office Suite)',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Delete Module',
                                  onPressed: () => _removeModule(idx),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            TextFormField(
                              controller: controllers['topics'],
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Key topics covered (comma separated or brief description)...',
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 16),

              // ── 6. Career Roles ──
              _buildSectionCard(
                title: '6. Career & Job Opportunities',
                subtitle: 'Industry roles graduates can apply for',
                icon: Icons.work_outline_rounded,
                iconColor: AppColors.goldDeep,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _newRoleController,
                          decoration: _inputDecoration(
                            label: 'Add Career Role',
                            hint: 'e.g., Accounts Executive',
                            icon: Icons.add_task_rounded,
                          ),
                          onFieldSubmitted: (val) => _addCareerRole(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addCareerRole(_newRoleController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldCta,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_careerRoles.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _careerRoles.map((role) {
                        return Chip(
                          label: Text(role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
                          onDeleted: () => _removeCareerRole(role),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Suggestions:',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _commonRolesSuggestions
                        .where((r) => !_careerRoles.contains(r))
                        .map((r) {
                      return ActionChip(
                        label: Text('+ $r', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        onPressed: () => _addCareerRole(r),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldCta.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: AppColors.goldCta, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Superadmin Curriculum Manager' : 'Master Program Creator',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing
                      ? 'Update benchmark fees, syllabus modules, and qualification criteria.'
                      : 'Define complete program specs displayed across branch portals.',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? headerTrailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey.shade600) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.goldCta, width: 1.5),
      ),
    );
  }
}
