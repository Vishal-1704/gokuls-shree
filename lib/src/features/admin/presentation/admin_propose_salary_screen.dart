import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// branch_admin/super_admin propose a CTC change here — it only takes
/// effect once a super_admin approves it in the Salary Revisions tab,
/// never a direct write to employees.basic_salary/hra/da/other_allowance.
class AdminProposeSalaryScreen extends ConsumerStatefulWidget {
  const AdminProposeSalaryScreen({super.key});

  @override
  ConsumerState<AdminProposeSalaryScreen> createState() =>
      _AdminProposeSalaryScreenState();
}

class _AdminProposeSalaryScreenState extends ConsumerState<AdminProposeSalaryScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _selectedEmployeeId;
  int _effectiveMonth = DateTime.now().month;
  int _effectiveYear = DateTime.now().year;

  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _daController = TextEditingController();
  final _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _basicController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await ref.read(adminRepositoryProvider).getStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _selectedEmployeeId = staff.isNotEmpty ? staff.first['id'] as int? : null;
        _prefillFromSelected();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _prefillFromSelected() {
    final emp = _staff.firstWhere(
      (s) => s['id'] == _selectedEmployeeId,
      orElse: () => const {},
    );
    _basicController.text = (emp['basic_salary'] ?? 0).toString();
    _hraController.text = (emp['hra'] ?? 0).toString();
    _daController.text = (emp['da'] ?? 0).toString();
    _otherController.text = (emp['other_allowance'] ?? 0).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEmployeeId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).proposeSalaryRevision(
            employeeId: _selectedEmployeeId!,
            basicSalary: double.tryParse(_basicController.text.trim()) ?? 0,
            hra: double.tryParse(_hraController.text.trim()) ?? 0,
            da: double.tryParse(_daController.text.trim()) ?? 0,
            otherAllowance: double.tryParse(_otherController.text.trim()) ?? 0,
            effectiveMonth: _effectiveMonth,
            effectiveYear: _effectiveYear,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision submitted for Super Admin approval.'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider10)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Propose Salary Revision', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Employee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedEmployeeId,
                    isExpanded: true,
                    dropdownColor: AppColors.inkNavy800,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration(''),
                    items: _staff
                        .map((s) => DropdownMenuItem(
                              value: s['id'] as int,
                              child: Text(
                                s['name']?.toString() ?? 'Unnamed',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedEmployeeId = v;
                      _prefillFromSelected();
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _basicController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('Basic Salary'),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _hraController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('HRA'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _daController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('DA'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otherController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('Other Allowance'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _effectiveMonth,
                          isExpanded: true,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _decoration('Effective Month'),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(value: i + 1, child: Text(_monthNames[i], style: const TextStyle(color: AppColors.textPrimary))),
                          ),
                          onChanged: (v) => setState(() => _effectiveMonth = v ?? _effectiveMonth),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _effectiveYear,
                          isExpanded: true,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _decoration('Year'),
                          items: List.generate(
                            5,
                            (i) {
                              final year = DateTime.now().year + i;
                              return DropdownMenuItem(value: year, child: Text('$year', style: const TextStyle(color: AppColors.textPrimary)));
                            },
                          ),
                          onChanged: (v) => setState(() => _effectiveYear = v ?? _effectiveYear),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldCta,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: AppColors.inkNavy900)
                          : const Text('Submit for Approval', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.inkNavy900)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
