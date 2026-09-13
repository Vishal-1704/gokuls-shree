import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class AdminPayslipGeneratorScreen extends ConsumerStatefulWidget {
  const AdminPayslipGeneratorScreen({super.key});

  @override
  ConsumerState<AdminPayslipGeneratorScreen> createState() =>
      _AdminPayslipGeneratorScreenState();
}

class _AdminPayslipGeneratorScreenState
    extends ConsumerState<AdminPayslipGeneratorScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  int? _selectedEmployeeId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await ref.read(adminRepositoryProvider).getStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _selectedEmployeeId = staff.isNotEmpty ? staff.first['id'] as int? : null;
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

  Future<void> _generate() async {
    if (_selectedEmployeeId == null) return;
    setState(() => _isGenerating = true);
    try {
      final result = await ref.read(supabaseServiceProvider).generatePayslip(
            employeeId: _selectedEmployeeId!,
            month: _selectedMonth,
            year: _selectedYear,
          );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payslip generated and signed.'), backgroundColor: AppColors.success),
        );
      } else {
        final reason = result['reason'] ?? 'unknown_error';
        final message = reason == 'already_generated'
            ? 'A payslip for this employee/month already exists.'
            : 'Could not generate payslip: $reason';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate payslip: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Generate Payslip', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Employee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedEmployeeId,
                    isExpanded: true,
                    dropdownColor: AppColors.inkNavy800,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
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
                    onChanged: (v) => setState(() => _selectedEmployeeId = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              isExpanded: true,
                              dropdownColor: AppColors.inkNavy800,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: List.generate(
                                12,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(_monthNames[i], style: const TextStyle(color: AppColors.textPrimary)),
                                ),
                              ),
                              onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Year', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              dropdownColor: AppColors.inkNavy800,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: List.generate(
                                5,
                                (i) {
                                  final year = DateTime.now().year - 2 + i;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text('$year', style: const TextStyle(color: AppColors.textPrimary)),
                                  );
                                },
                              ),
                              onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
                            ),
                          ],
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
                      onPressed: (_isGenerating || _selectedEmployeeId == null) ? null : _generate,
                      child: _isGenerating
                          ? const CircularProgressIndicator(color: AppColors.inkNavy900)
                          : const Text(
                              'Generate & Sign Payslip',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.inkNavy900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
