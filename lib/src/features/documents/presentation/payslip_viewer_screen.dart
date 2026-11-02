import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/widgets/document_a4_frame.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _numberToWords(int number) {
  if (number <= 0) return 'Zero';
  final units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  String convertChunk(int n) {
    if (n >= 100) {
      final rem = n % 100;
      return '${units[n ~/ 100]} Hundred ${rem > 0 ? convertChunk(rem) : ''}'.trim();
    }
    if (n >= 20) {
      final rem = n % 10;
      return '${tens[n ~/ 10]} ${rem > 0 ? units[rem] : ''}'.trim();
    }
    return units[n];
  }

  String res = '';
  if (number >= 10000000) {
    res += '${convertChunk(number ~/ 10000000)} Crore ';
    number %= 10000000;
  }
  if (number >= 100000) {
    res += '${convertChunk(number ~/ 100000)} Lakh ';
    number %= 100000;
  }
  if (number >= 1000) {
    res += '${convertChunk(number ~/ 1000)} Thousand ';
    number %= 1000;
  }
  if (number > 0) {
    res += convertChunk(number);
  }
  return res.trim();
}

class PayslipViewerScreen extends StatelessWidget {
  const PayslipViewerScreen({super.key, required this.payslip});

  final Map<String, dynamic> payslip;

  @override
  Widget build(BuildContext context) {
    final employee = payslip['employees'] as Map<String, dynamic>? ?? {};
    final branch = employee['branches'] as Map<String, dynamic>? ?? {};

    final month = (payslip['month'] as int?) ?? 1;
    final year = payslip['year']?.toString() ?? DateTime.now().year.toString();
    final monthName = (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Unknown';

    final basic = (payslip['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hra = (payslip['hra'] as num?)?.toDouble() ?? 0.0;
    final da = (payslip['da'] as num?)?.toDouble() ?? 0.0;
    final other = (payslip['other_allowance'] as num?)?.toDouble() ?? 0.0;
    final gross = (payslip['gross_pay'] as num?)?.toDouble() ?? (basic + hra + da + other);
    final net = (payslip['net_pay'] as num?)?.toDouble() ?? gross;
    final deductions = (gross - net) > 0 ? (gross - net) : 0.0;

    final payslipId = payslip['id']?.toString() ?? 'N/A';
    final empCode = employee['employee_code'] ?? employee['id']?.toString() ?? 'EMP-$payslipId';
    final isSigned = payslip['signature_hash'] != null;

    final netWords = _numberToWords(net.round());

    return DocumentA4Frame(
      appBarTitle: 'Salary Payslip',
      subtitleLine: 'SALARY PAYSLIP — ${monthName.toUpperCase()} $year',
      verifyType: 'payslip',
      verifyId: payslipId,
      isSigned: isSigned,
      pdfFilenamePrefix: 'Payslip_${monthName}_$year',
      signatoryTitle: 'Head of Accounts & Finance',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 2-Column Employee Information Card ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      _infoRow('Employee Name', (employee['name'] ?? 'N/A').toString().toUpperCase()),
                      _infoRow('Employee ID', empCode.toString()),
                      _infoRow('Designation', employee['designation']?.toString() ?? 'Staff Member'),
                      _infoRow('Department', employee['department']?.toString() ?? 'General'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      _infoRow('Pay Period', '$monthName $year'),
                      _infoRow('Branch', branch['name']?.toString() ?? 'Main Branch'),
                      _infoRow('Payment Mode', 'Bank Direct Credit / IMPS'),
                      _infoRow('Status', 'PAID & CREDITED', isStatus: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Earnings & Deductions Breakdown Table ───
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4.5),
              1: FlexColumnWidth(2.5),
            },
            border: TableBorder.all(color: DocumentColors.navy, width: 1.2),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: DocumentColors.navy),
                children: [
                  _Cell('SALARY COMPONENT / EARNINGS', isHeader: true),
                  _Cell('AMOUNT (INR)', isHeader: true),
                ],
              ),
              _row('Basic Salary', basic),
              _row('House Rent Allowance (HRA)', hra),
              _row('Dearness Allowance (DA)', da),
              _row('Special / Other Allowances', other),
              _row('Gross Salary', gross, isBold: true),
              if (deductions > 0)
                _row('Total Statutory Deductions (PF / TDS / PT)', deductions, isDeduction: true),
            ],
          ),

          // ─── Net Pay Highlight Banner ───
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: DocumentColors.goldSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DocumentColors.gold, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL NET PAYABLE SALARY',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: DocumentColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'INR $netWords Only',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹ ${net.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: DocumentColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Expanded(
            child: isStatus
                ? Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  TableRow _row(String label, double amount, {bool isBold = false, bool isDeduction = false}) {
    return TableRow(
      decoration: isBold ? const BoxDecoration(color: Color(0xFFF8FAFC)) : null,
      children: [
        _Cell(label, isBold: isBold, isDeduction: isDeduction),
        _Cell(
          '₹ ${amount.toStringAsFixed(2)}',
          isBold: isBold,
          isDeduction: isDeduction,
          alignRight: true,
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.isHeader = false,
    this.isBold = false,
    this.isDeduction = false,
    this.alignRight = false,
  });

  final String text;
  final bool isHeader;
  final bool isBold;
  final bool isDeduction;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Text(
        text,
        textAlign: isHeader
            ? TextAlign.center
            : (alignRight ? TextAlign.right : TextAlign.left),
        style: TextStyle(
          fontSize: isHeader ? 12.5 : 13.5,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: isHeader ? 0.8 : 0.0,
          color: isHeader
              ? DocumentColors.gold
              : (isDeduction
                  ? const Color(0xFFDC2626)
                  : (isBold ? DocumentColors.navy : DocumentColors.text)),
        ),
      ),
    );
  }
}
