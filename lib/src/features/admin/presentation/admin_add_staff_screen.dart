import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class AdminAddStaffScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? staff;
  const AdminAddStaffScreen({super.key, this.staff});

  @override
  ConsumerState<AdminAddStaffScreen> createState() =>
      _AdminAddStaffScreenState();
}

class _AdminAddStaffScreenState extends ConsumerState<AdminAddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  int? _selectedDepartmentId;
  final _dojController = TextEditingController();
  final _basicSalaryController = TextEditingController();
  final _hraController = TextEditingController();
  final _daController = TextEditingController();
  final _otherAllowanceController = TextEditingController();
  final _pfController = TextEditingController();
  final _esiController = TextEditingController();
  final _panController = TextEditingController();
  final _leaveController = TextEditingController(text: '15');

  String _selectedRole = 'Teacher';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _nameController.text = widget.staff!['name'] ?? '';
      _emailController.text = widget.staff!['email'] ?? '';
      _phoneController.text = widget.staff!['phone'] ?? '';
      _selectedRole = widget.staff!['role'] ?? 'Teacher';

      _selectedDepartmentId = widget.staff!['department_id'] as int?;
      _dojController.text = widget.staff!['doj'] ?? '';
      _basicSalaryController.text = widget.staff!['basic_salary']?.toString() ?? '';
      _hraController.text = widget.staff!['hra']?.toString() ?? '';
      _daController.text = widget.staff!['da']?.toString() ?? '';
      _otherAllowanceController.text = widget.staff!['other_allowance']?.toString() ?? '';
      _pfController.text = widget.staff!['pf_account_no'] ?? '';
      _esiController.text = widget.staff!['esi_no'] ?? '';
      _panController.text = widget.staff!['pan_no'] ?? '';
      _leaveController.text = widget.staff!['causal_leave']?.toString() ?? '15';

    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();

    _dojController.dispose();
    _basicSalaryController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _otherAllowanceController.dispose();
    _pfController.dispose();
    _esiController.dispose();
    _panController.dispose();
    _leaveController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);

final hrDetails = {
        'department_id': _selectedDepartmentId,
        'doj': _dojController.text.trim(),
        'basic_salary': double.tryParse(_basicSalaryController.text.trim()) ?? 0.0,
        'hra': double.tryParse(_hraController.text.trim()) ?? 0.0,
        'da': double.tryParse(_daController.text.trim()) ?? 0.0,
        'other_allowance': double.tryParse(_otherAllowanceController.text.trim()) ?? 0.0,
        'pf_account_no': _pfController.text.trim(),
        'esi_no': _esiController.text.trim(),
        'pan_no': _panController.text.trim(),
        'causal_leave': int.tryParse(_leaveController.text.trim()) ?? 15,
      };

      if (widget.staff != null) {
        await repo.updateStaff(
          id: widget.staff!['id'].toString(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          hrDetails: hrDetails,
        );
      } else {
        if (_selectedRole == 'Teacher') {
          // We don't have hrDetails in registerTeacher signature in repo, so we might need to update it separately,
          // OR we can just pass hrDetails if we update the signature. We will update the signature.
          await repo.registerTeacher(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            // hrDetails: hrDetails,
          );
        } else {
          await repo.addStaff(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
            hrDetails: hrDetails,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedRole saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _payrollInputDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: AppColors.goldCta, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      floatingLabelStyle: const TextStyle(color: AppColors.goldCta, fontSize: 11.5, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Text(widget.staff != null ? 'Edit Staff' : 'Add New Staff',
            style: const TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: AppColors.textMuted),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, color: AppColors.textMuted),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (widget.staff == null && _selectedRole == 'Teacher') {
                    if (v == null || v.trim().isEmpty || !v.contains('@')) {
                      return 'Valid email is required for teacher login';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: AppColors.textMuted),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: AppColors.inkNavy800,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge, color: AppColors.textMuted),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: {
                  'Teacher', 'Admin', 'Driver', 'Cleaner', 'Security',
                  _selectedRole
                }
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary))))
                    .toList(),
                onChanged: widget.staff != null
                    ? null // disable role change on edit for simplicity
                    : (v) => setState(() => _selectedRole = v!),
              ),
              if (widget.staff == null && _selectedRole == 'Teacher') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Password (For Teacher Login)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: AppColors.textMuted),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Payroll Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Consumer(
                  builder: (context, ref, _) {
                    final departmentsAsync = ref.watch(departmentsProvider);
                    return departmentsAsync.when(
                      data: (departments) {
                        final active = departments.where((d) => d['status'] == 1).toList();
                        final ids = active.map((d) => d['id'] as int).toSet();
                        return DropdownButtonFormField<int>(
                          value: ids.contains(_selectedDepartmentId) ? _selectedDepartmentId : null,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                          decoration: _payrollInputDecoration('Department'),
                          items: active
                              .map((d) => DropdownMenuItem(
                                    value: d['id'] as int,
                                    child: Text(d['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedDepartmentId = v),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (e, _) => Text('Failed to load departments: $e', style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                    );
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _dojController,
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_dojController.text) ?? now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _dojController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  decoration: _payrollInputDecoration(
                    'Date of Joining',
                    hint: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: AppColors.goldCta),
                  ),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _basicSalaryController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  keyboardType: TextInputType.number,
                  decoration: _payrollInputDecoration('Basic Salary'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _hraController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  keyboardType: TextInputType.number,
                  decoration: _payrollInputDecoration('HRA'),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _daController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  keyboardType: TextInputType.number,
                  decoration: _payrollInputDecoration('DA'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _otherAllowanceController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  keyboardType: TextInputType.number,
                  decoration: _payrollInputDecoration('Other Allowances'),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _pfController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  decoration: _payrollInputDecoration('PF Account No'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _esiController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  decoration: _payrollInputDecoration('ESI No'),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _panController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  decoration: _payrollInputDecoration('PAN No'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _leaveController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  keyboardType: TextInputType.number,
                  decoration: _payrollInputDecoration('Casual Leaves (Yr)'),
                )),
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveStaff,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
