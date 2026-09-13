import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

class AdminFeeCollectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? student; // Optional pre-filled student

  const AdminFeeCollectionScreen({super.key, this.student});

  @override
  ConsumerState<AdminFeeCollectionScreen> createState() =>
      _AdminFeeCollectionScreenState();
}

class _AdminFeeCollectionScreenState
    extends ConsumerState<AdminFeeCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _selectedStudent;
  String _paymentMode = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'dues', 'paid'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _selectStudent(widget.student!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedStudent = student;
      final due = (student['due_amount'] as num?)?.toDouble() ?? 0.0;
      if (due > 0) {
        _amountController.text = due.toStringAsFixed(0);
      } else {
        _amountController.text = '';
      }
    });
  }

  void _clearSelectedStudent() {
    setState(() {
      _selectedStudent = null;
      _amountController.clear();
      _remarksController.clear();
    });
  }

  Future<void> _submitFee() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text.trim());
        final studentId = _selectedStudent!['id']?.toString() ??
            _selectedStudent!['student_id']?.toString() ??
            _selectedStudent!['reg_no']?.toString() ??
            '';

        await ref.read(adminRepositoryProvider).collectFee(
              studentId: studentId,
              amount: amount,
              date: _selectedDate.toIso8601String(),
              paymentMode: _paymentMode,
              remarks: _remarksController.text.trim(),
            );

        // Refresh providers so reports & dues are immediately updated
        ref.invalidate(adminStudentsWithFeeStatusProvider);
        ref.invalidate(adminDuesReportProvider);
        ref.invalidate(adminStudentsProvider);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Fee Collected!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)} received from ${_selectedStudent!['name'] ?? 'Student'} via $_paymentMode.',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reg No: ${_selectedStudent!['reg_no'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (widget.student != null) {
                      Navigator.pop(context);
                    } else {
                      _clearSelectedStudent();
                    }
                  },
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error collecting fee: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedStudent == null ? 'Collect Student Fee' : 'Payment Collection',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _selectedStudent != null
          ? _buildPaymentForm()
          : _buildStudentSelector(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. STUDENT SELECTOR (Auto-fetches branch students + fee dues status)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStudentSelector() {
    final studentsAsync = ref.watch(adminStudentsWithFeeStatusProvider);

    return Column(
      children: [
        // ── Header Controls & Search ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Branch Enrolled Students',
                style: AppTypography.headingSm.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a student with pending balance to collect fees.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by student name, reg no, or phone...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              studentsAsync.maybeWhen(
                data: (list) {
                  final totalDuesCount = list.where((s) => (s['due_amount'] as num? ?? 0) > 0).length;
                  final totalPaidCount = list.where((s) => s['is_fully_paid'] == true).length;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All (${list.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('dues', 'Pending Dues ($totalDuesCount)', isAlert: totalDuesCount > 0),
                        const SizedBox(width: 8),
                        _buildFilterChip('paid', 'Fully Paid ($totalPaidCount)'),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Student List ──
        Expanded(
          child: studentsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text('Failed to load branch students:\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminStudentsWithFeeStatusProvider),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            data: (students) {
              var filtered = students.where((s) {
                if (_filter == 'dues') {
                  if ((s['due_amount'] as num? ?? 0) <= 0) return false;
                } else if (_filter == 'paid') {
                  if (s['is_fully_paid'] != true) return false;
                }

                if (_searchQuery.isNotEmpty) {
                  final name = (s['name'] ?? '').toString().toLowerCase();
                  final reg = (s['reg_no'] ?? '').toString().toLowerCase();
                  final phone = (s['contact'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      reg.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No students match the criteria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing your search query or selecting a different filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStudentsWithFeeStatusProvider),
                color: const Color(0xFF0284C7),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final dueAmount = (student['due_amount'] as num?)?.toDouble() ?? 0.0;
                    final totalFee = (student['total_fee'] as num?)?.toDouble() ?? 0.0;
                    final paidAmount = (student['paid_amount'] as num?)?.toDouble() ?? 0.0;
                    final hasDues = dueAmount > 0;

                    final avatar = resolveAvatarProvider(student['photo_url']);

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _selectStudent(student),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasDues
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFE2E8F0),
                              width: hasDues ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFE0F2FE),
                                    backgroundImage: avatar,
                                    child: avatar == null
                                        ? const Icon(Icons.person, color: Color(0xFF0284C7), size: 24)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Reg: ${student['reg_no'] ?? '-'} • ${student['course_name'] ?? 'General'}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: hasDues
                                          ? const Color(0xFFFFFBEB)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: hasDues
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF22C55E),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      hasDues
                                          ? '₹${dueAmount.toStringAsFixed(0)} Due'
                                          : '✓ Fully Paid',
                                      style: TextStyle(
                                        color: hasDues
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: Colors.grey.shade100),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Paid: ₹${paidAmount.toStringAsFixed(0)} / Total: ₹${totalFee.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        hasDues ? 'Collect Fee' : 'View Record',
                                        style: TextStyle(
                                          color: hasDues ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: hasDues ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isAlert = false}) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : (isAlert ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isAlert ? const Color(0xFFF59E0B) : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isAlert ? const Color(0xFF92400E) : const Color(0xFF475569)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 2. PAYMENT COLLECTION FORM (Selected student)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentForm() {
    final student = _selectedStudent!;
    final dueAmount = (student['due_amount'] as num?)?.toDouble() ?? 0.0;
    final totalFee = (student['total_fee'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (student['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final avatar = resolveAvatarProvider(student['photo_url']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Student Summary Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE0F2FE),
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 28, color: Color(0xFF0284C7))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'] ?? 'Student',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reg: ${student['reg_no'] ?? '-'}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            Text(
                              'Course: ${student['course_name'] ?? 'General'}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (widget.student == null)
                        TextButton.icon(
                          onPressed: _clearSelectedStudent,
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeeMetric('Total Fee', '₹${totalFee.toStringAsFixed(0)}', const Color(0xFF0F172A)),
                        Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                        _buildFeeMetric('Already Paid', '₹${paidAmount.toStringAsFixed(0)}', const Color(0xFF15803D)),
                        Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                        _buildFeeMetric(
                          'Pending Due',
                          '₹${dueAmount.toStringAsFixed(0)}',
                          dueAmount > 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Fee Amount Input ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Amount to Collect',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 26),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter fee amount';
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) return 'Please enter a valid positive amount';
                      return null;
                    },
                  ),
                  if (dueAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pre-filled with student’s remaining due balance (₹${dueAmount.toStringAsFixed(0)})',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Payment Details ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Payment',
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0284C7), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMode,
                    decoration: InputDecoration(
                      labelText: 'Payment Mode',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF0284C7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: ['Cash', 'UPI', 'Online Transfer', 'Cheque']
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode, style: const TextStyle(color: Color(0xFF0F172A))),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _paymentMode = val!),
                  ),
                  const SizedBox(height: 16),

                  // Remarks
                  TextFormField(
                    controller: _remarksController,
                    decoration: InputDecoration(
                      labelText: 'Remarks / Transaction Ref (Optional)',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintText: 'e.g. UTR / Receipt reference or cash note',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF0284C7), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit Button ──
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFee,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Collect Fee & Issue Receipt',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeMetric(String label, String value, Color valueColor, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }
}
