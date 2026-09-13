import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/widgets/document_a4_frame.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class PayslipViewerScreen extends StatelessWidget {
  const PayslipViewerScreen({super.key, required this.payslip});

  final Map<String, dynamic> payslip;

  @override
  Widget build(BuildContext context) {
    final employee = payslip['employees'] as Map<String, dynamic>? ?? {};
    final branch = employee['branches'] as Map<String, dynamic>? ?? {};

    final month = (payslip['month'] as int?) ?? 1;
    final year = payslip['year']?.toString() ?? '';
    final monthName = (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Unknown';

    final basic = (payslip['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hra = (payslip['hra'] as num?)?.toDouble() ?? 0.0;
    final da = (payslip['da'] as num?)?.toDouble() ?? 0.0;
    final other = (payslip['other_allowance'] as num?)?.toDouble() ?? 0.0;
    final gross = (payslip['gross_pay'] as num?)?.toDouble() ?? 0.0;
    final net = (payslip['net_pay'] as num?)?.toDouble() ?? 0.0;
    final payslipId = payslip['id']?.toString() ?? 'N/A';
    final isSigned = payslip['signature_hash'] != null;

    return DocumentA4Frame(
      appBarTitle: 'Payslip',
      subtitleLine: 'PAYSLIP — ${monthName.toUpperCase()} $year',
      verifyType: 'payslip',
      verifyId: payslipId,
      isSigned: isSigned,
      pdfFilenamePrefix: 'Payslip',
      body: Column(
        children: [
          documentInfoRow('Employee Name', (employee['name'] ?? 'N/A').toString().toUpperCase()),
          documentInfoRow('Designation', employee['designation']?.toString() ?? 'N/A'),
          documentInfoRow('Department', employee['department']?.toString() ?? 'N/A'),
          documentInfoRow('Branch', branch['name']?.toString() ?? 'N/A'),
          const SizedBox(height: 12),
          _buildEarningsTable(basic, hra, da, other, gross, net),
        ],
      ),
    );
  }

  Widget _buildEarningsTable(double basic, double hra, double da, double other, double gross, double net) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(2)},
      border: TableBorder.all(color: DocumentColors.navy, width: 1.4),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: DocumentColors.navy),
          children: [
            _Cell('EARNINGS', isHeader: true),
            _Cell('AMOUNT', isHeader: true),
          ],
        ),
        _row('Basic Salary', basic),
        _row('House Rent Allowance', hra),
        _row('Dearness Allowance', da),
        _row('Other Allowance', other),
        _row('Gross Pay', gross, isBold: true),
        _row('Net Pay', net, isBold: true, highlight: true),
      ],
    );
  }

  TableRow _row(String label, double amount, {bool isBold = false, bool highlight = false}) {
    return TableRow(
      children: [
        _Cell(label, isBold: isBold),
        _Cell('Rs. ${amount.toStringAsFixed(2)}', isBold: isBold, highlight: highlight),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.isHeader = false, this.isBold = false, this.highlight = false});
  final String text;
  final bool isHeader;
  final bool isBold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Text(
        text,
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: isHeader
              ? DocumentColors.gold
              : (highlight ? DocumentColors.navy : DocumentColors.text),
        ),
      ),
    );
  }
}
