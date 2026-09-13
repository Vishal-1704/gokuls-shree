import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/branch_dashboard_screen.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class SuperAdminBranchesScreen extends ConsumerStatefulWidget {
  const SuperAdminBranchesScreen({super.key});

  @override
  ConsumerState<SuperAdminBranchesScreen> createState() =>
      _SuperAdminBranchesScreenState();
}

class _SuperAdminBranchesScreenState extends ConsumerState<SuperAdminBranchesScreen> {
  bool _isLoading = false;

  Future<void> _addOrEditBranch({Map<String, dynamic>? branch}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _BranchFormDialog(branch: branch),
    );
    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      if (branch != null) {
        // Update
        await client
            .from('branches')
            .update({
              'name': result['name'],
              'code': result['code'],
              'owner_name': result['owner_name'],
              'contact_phone': result['contact_phone'],
              'address': result['address'],
              'status': result['status'],
            })
            .eq('id', branch['id']);
      } else {
        // Insert
        await client.from('branches').insert({
          'name': result['name'],
          'code': result['code'],
          'owner_name': result['owner_name'],
          'contact_phone': result['contact_phone'],
          'address': result['address'],
          'status': result['status'],
        });
      }
      ref.invalidate(branchesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(branch != null ? 'Branch updated successfully' : 'Branch created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> branch) async {
    final currentStatus = branch['status'] as bool? ?? false;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('branches')
          .update({'status': !currentStatus})
          .eq('id', branch['id']);
      ref.invalidate(branchesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Branch activated' : 'Branch deactivated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBranchDetails(Map<String, dynamic> branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchDashboardScreen(branch: branch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchesFuture = ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Text(
          'Manage Branches',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(branchesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.goldCta,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Branch', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _addOrEditBranch(),
      ),
      body: Stack(
        children: [
          branchesFuture.when(
            data: (branches) {
              if (branches.isEmpty) {
                return const Center(
                  child: Text('No branches found', style: TextStyle(color: AppColors.textMuted)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final isActive = branch['status'] == true;

                  return Card(
                    color: AppColors.inkNavy800,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isActive ? Colors.green.withOpacity(0.3) : AppColors.divider10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isActive ? Colors.green.withOpacity(0.2) : AppColors.divider10,
                                child: Icon(Icons.school, color: isActive ? Colors.green : AppColors.textMuted),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch['name'] ?? 'Unnamed Branch',
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Code: ${branch['code'] ?? 'N/A'}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                color: AppColors.inkNavy700,
                                onSelected: (val) {
                                  if (val == 'edit') _addOrEditBranch(branch: branch);
                                  if (val == 'toggle') _toggleStatus(branch);
                                  if (val == 'delete') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Feature coming soon'), backgroundColor: Colors.orange),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.textPrimary))),
                                  PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: isActive ? Colors.orange : Colors.green))),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (branch['owner_name'] != null && branch['owner_name'].toString().isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Owner: ${branch['owner_name']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (branch['contact_phone'] != null && branch['contact_phone'].toString().isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Phone: ${branch['contact_phone']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (branch['address'] != null && branch['address'].toString().isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Address: ${branch['address']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.divider10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.goldCta,
                                side: const BorderSide(color: AppColors.goldCta),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _showBranchDetails(branch),
                              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
            error: (e, _) => Center(
              child: Text('Error loading branches: $e', style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
            ),
        ],
      ),
    );
  }
}

class _BranchFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? branch;
  const _BranchFormDialog({this.branch});

  @override
  ConsumerState<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends ConsumerState<_BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _status = true;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameCtrl = TextEditingController(text: b?['name'] ?? '');
    _codeCtrl = TextEditingController(text: b?['code'] ?? '');
    _ownerCtrl = TextEditingController(text: b?['owner_name'] ?? '');
    _phoneCtrl = TextEditingController(text: b?['contact_phone'] ?? b?['contact'] ?? '');
    _addressCtrl = TextEditingController(text: b?['address'] ?? '');
    _status = b?['status'] == true || b == null;

    if (b == null || (b['code'] == null || b['code'].toString().trim().isEmpty)) {
      Future.microtask(() async {
        await _autoGenerate();
      });
    }
  }

  Future<void> _autoGenerate() async {
    if (!mounted) return;
    setState(() => _isGeneratingCode = true);
    try {
      final code = await ref.read(adminRepositoryProvider).generateNextBranchCode();
      if (mounted && (_codeCtrl.text.trim().isEmpty || widget.branch == null)) {
        setState(() => _codeCtrl.text = code);
      }
    } catch (_) {}
    if (mounted) setState(() => _isGeneratingCode = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;

    return AlertDialog(
      backgroundColor: AppColors.inkNavy800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Branch' : 'Create Branch', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Branch Code',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: _isGeneratingCode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                          )
                        : const Icon(Icons.auto_awesome, color: AppColors.goldCta, size: 20),
                    tooltip: 'Auto-generate Code',
                    onPressed: _isGeneratingCode ? null : _autoGenerate,
                  ),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Owner Name (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status (Active)', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                value: _status,
                activeColor: AppColors.goldCta,
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldCta,
            foregroundColor: AppColors.textPrimary,
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'name': _nameCtrl.text.trim(),
              'code': _codeCtrl.text.trim(),
              'owner_name': _ownerCtrl.text.trim(),
              'contact_phone': _phoneCtrl.text.trim(),
              'address': _addressCtrl.text.trim(),
              'status': _status,
            });
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
