import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/payslip_viewer_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "My Salary" — current approved CTC, any pending (not-yet-super-admin-
/// approved) revision, and the list of generated payslips.
class EmployeeSalaryScreen extends ConsumerStatefulWidget {
  const EmployeeSalaryScreen({super.key, required this.emp});

  final Map<String, dynamic>? emp;

  @override
  ConsumerState<EmployeeSalaryScreen> createState() => _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends ConsumerState<EmployeeSalaryScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _pendingRevision;
  List<Map<String, dynamic>> _payslips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employeeId = widget.emp?['id'] as int?;
    if (employeeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final client = ref.read(supabaseClientProvider);
    try {
      final revisions = await client
          .from('employee_salary_revisions')
          .select()
          .eq('employee_id', employeeId)
          .eq('status', 0)
          .order('created_at', ascending: false)
          .limit(1);
      final payslips = await client
          .from('payslips')
          .select()
          .eq('employee_id', employeeId)
          .order('year', ascending: false)
          .order('month', ascending: false);

      if (!mounted) return;
      setState(() {
        _pendingRevision = revisions.isNotEmpty ? Map<String, dynamic>.from(revisions.first) : null;
        _payslips = List<Map<String, dynamic>>.from(payslips);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load salary details: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.emp;
    final basic = (emp?['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hra = (emp?['hra'] as num?)?.toDouble() ?? 0.0;
    final da = (emp?['da'] as num?)?.toDouble() ?? 0.0;
    final other = (emp?['other_allowance'] as num?)?.toDouble() ?? 0.0;
    final gross = basic + hra + da + other;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('My Salary', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Current CTC (Approved)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _payRow('Basic Salary', basic),
                        _payRow('HRA', hra),
                        _payRow('DA', da),
                        _payRow('Other Allowance', other),
                        const Divider(color: AppColors.divider10),
                        _payRow('Monthly Gross', gross, isBold: true),
                        _payRow('Annual CTC', gross * 12, isBold: true),
                      ],
                    ),
                  ),
                  if (_pendingRevision != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⏳ Pending Revision (awaiting Super Admin approval)',
                              style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            'Proposed Gross: Rs. ${(((_pendingRevision!['basic_salary'] as num?) ?? 0) + ((_pendingRevision!['hra'] as num?) ?? 0) + ((_pendingRevision!['da'] as num?) ?? 0) + ((_pendingRevision!['other_allowance'] as num?) ?? 0)).toStringAsFixed(2)}/mo',
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Monthly Payslips', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_payslips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No payslips generated yet.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ..._payslips.map((p) {
                      final month = (p['month'] as int?) ?? 1;
                      final monthName = (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Unknown';
                      final net = (p['net_pay'] as num?)?.toDouble() ?? 0.0;
                      return Card(
                        color: AppColors.inkNavy800,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined, color: AppColors.goldCta),
                          title: Text('$monthName ${p['year']}', style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text('Rs. ${net.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textMuted)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PayslipViewerScreen(payslip: p)),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _payRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
          Text(
            'Rs. ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isBold ? AppColors.goldCta : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
