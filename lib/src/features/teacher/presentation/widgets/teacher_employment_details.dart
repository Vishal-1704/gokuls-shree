import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class TeacherEmploymentDetails extends ConsumerWidget {
  final Map<String, dynamic>? emp;

  const TeacherEmploymentDetails({super.key, required this.emp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildEmployeeDetails(context, ref, emp);
  }

// WIDGET: Employee Profile Details
  Widget _buildEmployeeDetails(BuildContext context, WidgetRef ref, Map<String, dynamic>? emp) {
    if (emp == null) {
      return const Center(child: Text('No employee profile record found.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final name = emp['name'] ?? 'Employee';
    final email = emp['email'] ?? 'N/A';
    final contact = emp['contact'] ?? 'N/A';
    final designation = emp['designation'] ?? 'N/A';
    final department = emp['department'] ?? 'N/A';
    final doj = emp['doj'] ?? 'N/A';
    final address = emp['address'] ?? 'N/A';

    // Salary info
    final basic = (emp['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hra = (emp['hra'] as num?)?.toDouble() ?? 0.0;
    final da = (emp['da'] as num?)?.toDouble() ?? 0.0;
    final other = (emp['other_allowance'] as num?)?.toDouble() ?? 0.0;
    final gross = basic + hra + da + other;

    // Accounts
    final pf = emp['pf_account_no'] ?? 'N/A';
    final pan = emp['pan_no'] ?? 'N/A';
    final esi = emp['esi_no'] ?? 'N/A';

    // Leaves
    const totalLeaves = 15;
    const takenLeaves = 3;
    final remainingLeaves = emp['causal_leave'] ?? (totalLeaves - takenLeaves);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.inkNavy700, AppColors.inkNavy800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldCta.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.inkNavy700,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.goldCta, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(designation, style: const TextStyle(color: AppColors.goldCta, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Dept: $department', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Leaves Section (leave tracker)
        const Text('Leave Entitlements', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildLeaveCard('Total Leaves', '$totalLeaves', Colors.blue),
            const SizedBox(width: 10),
            _buildLeaveCard('Leaves Taken', '$takenLeaves', Colors.orange),
            const SizedBox(width: 10),
            _buildLeaveCard('Balance Available', '$remainingLeaves', Colors.green),
          ],
        ),
        const SizedBox(height: 24),

        // Payroll / Payslip Section
        const Text('Payroll Snapshot (Monthly)', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider10, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPayRow('Basic Salary', '₹${basic.toStringAsFixed(2)}'),
              _buildPayRow('House Rent Allowance (HRA)', '₹${hra.toStringAsFixed(2)}'),
              _buildPayRow('Dearness Allowance (DA)', '₹${da.toStringAsFixed(2)}'),
              _buildPayRow('Special Allowances', '₹${other.toStringAsFixed(2)}'),
              const Divider(color: AppColors.textMuted, thickness: 1, height: 20),
              _buildPayRow('Gross Salary', '₹${gross.toStringAsFixed(2)}', isBold: true, valueColor: AppColors.goldCta),
              const SizedBox(height: 16),
              const Text('Statutory Registrations', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPayRow('PF Account No', pf, isSecondary: true),
              _buildPayRow('ESI Registration No', esi, isSecondary: true),
              _buildPayRow('PAN Card', pan, isSecondary: true),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Profile Details List
        const Text('Registry Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoRow('Email Address', email, Icons.email_outlined),
              _buildInfoRow('Contact Number', contact, Icons.phone_outlined),
              _buildInfoRow('Date of Joining', doj, Icons.calendar_today_outlined),
              _buildInfoRow('Office Address', address, Icons.location_on_outlined),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Experience Certificate Request
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _requestExperienceCertificate(context, ref),
            icon: const Icon(Icons.workspace_premium, color: AppColors.textPrimary),
            label: const Text('Request Experience Certificate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _requestExperienceCertificate(BuildContext context, WidgetRef ref) async {
    // Disabled/Mocked
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Experience Certificate requested successfully!'), backgroundColor: AppColors.success),
    );
  }

  Widget _buildLeaveCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inkNavy800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPayRow(String label, String value, {bool isBold = false, bool isSecondary = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSecondary ? 11 : 12,
              color: isSecondary ? AppColors.textMuted : (isBold ? AppColors.textPrimary : AppColors.textSecondary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSecondary ? 11 : 12,
              color: valueColor ?? (isSecondary ? AppColors.textMuted : AppColors.textPrimary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.goldCta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
