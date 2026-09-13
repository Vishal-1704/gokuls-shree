import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class ManageDepartmentsScreen extends ConsumerStatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  ConsumerState<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState
    extends ConsumerState<ManageDepartmentsScreen> {
  bool _isLoading = false;

  Future<void> _addOrEditDepartment({Map<String, dynamic>? department}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DepartmentFormDialog(department: department),
    );
    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      if (department != null) {
        await client
            .from('departments')
            .update({'name': result['name'], 'status': result['status']})
            .eq('id', department['id']);
      } else {
        // departments.id is a plain PK, not SERIAL (legacy ids like 4-7 are
        // preserved) — new department rows need an explicit id.
        final maxId = await client
            .from('departments')
            .select('id')
            .order('id', ascending: false)
            .limit(1)
            .maybeSingle();
        final nextId = ((maxId?['id'] as int?) ?? 0) + 1;
        await client.from('departments').insert({
          'id': nextId,
          'name': result['name'],
          'status': result['status'],
        });
      }
      ref.invalidate(departmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              department != null
                  ? 'Department updated successfully'
                  : 'Department created successfully',
            ),
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

  Future<void> _toggleStatus(Map<String, dynamic> department) async {
    final isActive = department['status'] == 1;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('departments')
          .update({'status': isActive ? 0 : 1})
          .eq('id', department['id']);
      ref.invalidate(departmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Department deactivated' : 'Department activated'),
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

  @override
  Widget build(BuildContext context) {
    final departmentsFuture = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: Text(
          'Manage Departments',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(departmentsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.goldCta,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Department', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _addOrEditDepartment(),
      ),
      body: Stack(
        children: [
          departmentsFuture.when(
            data: (departments) {
              if (departments.isEmpty) {
                return const Center(
                  child: Text('No departments found', style: TextStyle(color: AppColors.textMuted)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  final isActive = department['status'] == 1;

                  return Card(
                    color: AppColors.inkNavy800,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isActive ? Colors.green.withOpacity(0.3) : AppColors.divider10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green.withOpacity(0.2) : AppColors.divider10,
                        child: Icon(Icons.badge_outlined, color: isActive ? Colors.green : AppColors.textMuted),
                      ),
                      title: Text(
                        department['name'] ?? 'Unnamed Department',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                        color: AppColors.inkNavy700,
                        onSelected: (val) {
                          if (val == 'edit') _addOrEditDepartment(department: department);
                          if (val == 'toggle') _toggleStatus(department);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.textPrimary))),
                          PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: isActive ? Colors.orange : Colors.green))),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
            error: (e, _) => Center(
              child: Text('Error loading departments: $e', style: const TextStyle(color: AppColors.textSecondary)),
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

class _DepartmentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? department;
  const _DepartmentFormDialog({this.department});

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _status = true;

  @override
  void initState() {
    super.initState();
    final d = widget.department;
    _nameCtrl = TextEditingController(text: d?['name'] ?? '');
    _status = d == null || d['status'] == 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.department != null;

    return AlertDialog(
      backgroundColor: AppColors.inkNavy800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Department' : 'Create Department', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Department Name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.goldCta)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              'status': _status ? 1 : 0,
            });
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
