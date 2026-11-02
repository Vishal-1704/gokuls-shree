import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/payslip_viewer_screen.dart';

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
    extends ConsumerState<AdminPayslipGeneratorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _payslips = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  // Filters for All Payslips
  String _searchQuery = '';
  int? _filterMonth;
  int? _filterYear;
  String? _filterBranch;

  // New Payslip Form state
  int? _selectedEmployeeId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staff = await ref.read(adminRepositoryProvider).getStaff();
      final payslips = await ref.read(supabaseServiceProvider).getAllPayslips();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _payslips = payslips;
        if (_selectedEmployeeId == null && staff.isNotEmpty) {
          _selectedEmployeeId = staff.first['id'] as int?;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load payslips: $e'), backgroundColor: AppColors.danger),
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
          const SnackBar(content: Text('✅ Payslip generated & digitally signed!'), backgroundColor: AppColors.success),
        );
        await _loadData();
        _tabController.animateTo(0);
      } else {
        final reason = result['reason'] ?? 'unknown_error';
        final message = reason == 'already_generated'
            ? 'A payslip for this employee and month already exists. You can edit it from the "All Payslips" list.'
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

  Future<void> _openEditPayslipDialog(Map<String, dynamic> payslip) async {
    final employee = payslip['employees'] as Map<String, dynamic>? ?? {};
    final employeeName = employee['name']?.toString() ?? 'Employee';

    int editMonth = (payslip['month'] as int?) ?? DateTime.now().month;
    int editYear = (payslip['year'] as int?) ?? DateTime.now().year;

    final basicCtrl = TextEditingController(text: (payslip['basic_salary'] ?? '0').toString());
    final hraCtrl = TextEditingController(text: (payslip['hra'] ?? '0').toString());
    final daCtrl = TextEditingController(text: (payslip['da'] ?? '0').toString());
    final otherCtrl = TextEditingController(text: (payslip['other_allowance'] ?? '0').toString());

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final basic = double.tryParse(basicCtrl.text.trim()) ?? 0.0;
            final hra = double.tryParse(hraCtrl.text.trim()) ?? 0.0;
            final da = double.tryParse(daCtrl.text.trim()) ?? 0.0;
            final other = double.tryParse(otherCtrl.text.trim()) ?? 0.0;
            final totalGross = basic + hra + da + other;

            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.goldCta, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Payslip', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(employeeName, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inkNavy900,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Net / Gross Pay', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFormat.format(totalGross),
                                  style: const TextStyle(color: AppColors.goldCta, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Auto-Re-signed', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Salary Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: editMonth,
                                  isExpanded: true,
                                  dropdownColor: AppColors.inkNavy800,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.inkNavy900,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(_monthNames[i], style: const TextStyle(color: AppColors.textPrimary)),
                                    ),
                                  ),
                                  onChanged: (v) => setDialogState(() => editMonth = v ?? editMonth),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Salary Year', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: editYear,
                                  isExpanded: true,
                                  dropdownColor: AppColors.inkNavy800,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.inkNavy900,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: List.generate(
                                    6,
                                    (i) {
                                      final y = DateTime.now().year - 3 + i;
                                      return DropdownMenuItem(
                                        value: y,
                                        child: Text('$y', style: const TextStyle(color: AppColors.textPrimary)),
                                      );
                                    },
                                  ),
                                  onChanged: (v) => setDialogState(() => editYear = v ?? editYear),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                      const Text('Salary Breakdown (₹)', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMoneyField('Basic Salary', basicCtrl, () => setDialogState(() {})),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMoneyField('HRA', hraCtrl, () => setDialogState(() {})),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMoneyField('DA', daCtrl, () => setDialogState(() {})),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMoneyField('Other Allowance', otherCtrl, () => setDialogState(() {})),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.goldCta),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await ref.read(supabaseServiceProvider).updatePayslip(
                                  payslipId: payslip['id'] as int,
                                  basicSalary: basic,
                                  hra: hra,
                                  da: da,
                                  otherAllowance: other,
                                  month: editMonth,
                                  year: editYear,
                                );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Payslip updated & re-signed successfully!'), backgroundColor: AppColors.success),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.check_rounded, color: Colors.black, size: 18),
                  label: const Text('Save & Re-sign', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoneyField(String label, TextEditingController ctrl, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: AppColors.goldCta),
            filled: true,
            fillColor: AppColors.inkNavy900,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  Future<void> _deletePayslip(Map<String, dynamic> payslip) async {
    final employee = payslip['employees'] as Map<String, dynamic>? ?? {};
    final employeeName = employee['name']?.toString() ?? 'Staff';
    final month = (payslip['month'] as int?) ?? 1;
    final year = payslip['year']?.toString() ?? '';
    final monthName = (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Month';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Delete Payslip?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete the $monthName $year payslip for $employeeName? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(supabaseServiceProvider).deletePayslip(payslip['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payslip deleted.'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete payslip: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('Payslips Management', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldCta,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
              label: const Text('Issue Payslip', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldCta,
          labelColor: AppColors.goldCta,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              text: 'All Payslips (${_payslips.length})',
            ),
            const Tab(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              text: 'Generate Payslip',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllPayslipsTab(),
                _buildGenerateFormTab(),
              ],
            ),
    );
  }

  Widget _buildAllPayslipsTab() {
    final branches = <String>{};
    for (final p in _payslips) {
      final emp = p['employees'] as Map<String, dynamic>?;
      final b = emp?['branches'] as Map<String, dynamic>?;
      final bName = b?['name']?.toString();
      if (bName != null && bName.isNotEmpty) branches.add(bName);
    }

    final filtered = _payslips.where((p) {
      if (_filterMonth != null && p['month'] != _filterMonth) return false;
      if (_filterYear != null && p['year'] != _filterYear) return false;
      if (_filterBranch != null) {
        final emp = p['employees'] as Map<String, dynamic>?;
        final b = emp?['branches'] as Map<String, dynamic>?;
        if (b?['name']?.toString() != _filterBranch) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final emp = p['employees'] as Map<String, dynamic>?;
        final name = (emp?['name'] ?? '').toString().toLowerCase();
        final desig = (emp?['designation'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery) && !desig.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    final totalDisbursed = filtered.fold<double>(
      0,
      (sum, p) => sum + ((p['net_pay'] ?? p['gross_pay'] as num?)?.toDouble() ?? 0.0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2B48), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Disbursed', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(totalDisbursed),
                        style: const TextStyle(color: AppColors.goldCta, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payslips Count', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${filtered.length} of ${_payslips.length}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search & Filter Controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search staff name or designation…',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.inkNavy900,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Month filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterMonth,
                        isExpanded: true,
                        dropdownColor: AppColors.inkNavy800,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inkNavy900,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Months')),
                          ...List.generate(
                            12,
                            (i) => DropdownMenuItem(value: i + 1, child: Text(_monthNames[i])),
                          ),
                        ],
                        onChanged: (v) => setState(() => _filterMonth = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Year filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterYear,
                        isExpanded: true,
                        dropdownColor: AppColors.inkNavy800,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inkNavy900,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Years')),
                          ...List.generate(
                            5,
                            (i) {
                              final y = DateTime.now().year - 2 + i;
                              return DropdownMenuItem(value: y, child: Text('$y'));
                            },
                          ),
                        ],
                        onChanged: (v) => setState(() => _filterYear = v),
                      ),
                    ),
                    if (branches.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // Branch filter
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterBranch,
                          isExpanded: true,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inkNavy900,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Branches')),
                            ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) => setState(() => _filterBranch = v),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payslips List
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No payslips found matching your filters.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.goldCta),
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
                    label: const Text('Generate First Payslip', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = filtered[index];
                final emp = p['employees'] as Map<String, dynamic>? ?? {};
                final branch = emp['branches'] as Map<String, dynamic>? ?? {};
                final month = (p['month'] as int?) ?? 1;
                final year = p['year']?.toString() ?? '';
                final monthName = (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Month';

                final netPay = (p['net_pay'] as num?)?.toDouble() ?? 0.0;
                final basic = (p['basic_salary'] as num?)?.toDouble() ?? 0.0;
                final hra = (p['hra'] as num?)?.toDouble() ?? 0.0;
                final da = (p['da'] as num?)?.toDouble() ?? 0.0;
                final other = (p['other_allowance'] as num?)?.toDouble() ?? 0.0;
                final hasSignature = p['signature_hash'] != null;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.goldCta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_rounded, color: AppColors.goldCta, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          emp['name']?.toString() ?? 'Unnamed Staff',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$monthName $year',
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        emp['designation']?.toString() ?? 'Staff',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                      ),
                                      if (branch['name'] != null) ...[
                                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                        Text(
                                          branch['name'].toString(),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _breakdownChip('Basic: ₹${basic.toStringAsFixed(0)}'),
                                  if (hra > 0) _breakdownChip('HRA: ₹${hra.toStringAsFixed(0)}'),
                                  if (da > 0) _breakdownChip('DA: ₹${da.toStringAsFixed(0)}'),
                                  if (other > 0) _breakdownChip('Other: ₹${other.toStringAsFixed(0)}'),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Net Payable', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                Text(
                                  _currencyFormat.format(netPay),
                                  style: const TextStyle(
                                    color: AppColors.goldCta,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (hasSignature ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasSignature ? Icons.verified_rounded : Icons.pending_outlined,
                                    color: hasSignature ? AppColors.success : AppColors.warning,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasSignature ? 'Digitally Signed' : 'Draft',
                                    style: TextStyle(
                                      color: hasSignature ? AppColors.success : AppColors.warning,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Action: View / PDF
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.divider),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PayslipViewerScreen(payslip: p)),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF38BDF8)),
                              label: const Text('View PDF', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                            ),
                            const SizedBox(width: 8),
                            // Action: Edit
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.goldCta,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => _openEditPayslipDialog(p),
                              icon: const Icon(Icons.edit_rounded, size: 15, color: Colors.black),
                              label: const Text('Edit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ),
                            const SizedBox(width: 4),
                            // Action: Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                              tooltip: 'Delete Payslip',
                              onPressed: () => _deletePayslip(p),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _breakdownChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.inkNavy900,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
    );
  }

  Widget _buildGenerateFormTab() {
    final selectedStaff = _staff.where((s) => s['id'] == _selectedEmployeeId).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.goldCta, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate New Payslip', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Calculate and digitally sign monthly staff salary', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Select Staff Member', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedEmployeeId,
                isExpanded: true,
                dropdownColor: AppColors.inkNavy800,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inkNavy900,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _staff
                    .map((s) => DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(
                            '${s['name'] ?? 'Unnamed'} — ${s['designation'] ?? 'Staff'}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
              if (selectedStaff != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy900,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current CTC / Basic:', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      Text(
                        _currencyFormat.format((selectedStaff['basic_salary'] as num?)?.toDouble() ?? 0.0),
                        style: const TextStyle(color: AppColors.goldCta, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inkNavy900,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                        const Text('Year', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          dropdownColor: AppColors.inkNavy800,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inkNavy900,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.goldCta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_isGenerating || _selectedEmployeeId == null) ? null : _generate,
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Generate & Digitally Sign Payslip',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
