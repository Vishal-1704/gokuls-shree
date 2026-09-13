import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_button.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_text_field.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class FranchiseSetupScreen extends ConsumerStatefulWidget {
  const FranchiseSetupScreen({super.key});

  @override
  ConsumerState<FranchiseSetupScreen> createState() => _FranchiseSetupScreenState();
}

class _FranchiseSetupScreenState extends ConsumerState<FranchiseSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCodeLocked = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(adminRepositoryProvider);
    final branch = await repo.getMyBranch();

    if (!mounted) return;

    if (branch != null) {
      _nameController.text = branch['name'] ?? '';
      _ownerController.text = branch['owner_name'] ?? '';
      _phoneController.text = branch['contact'] ?? branch['contact_phone'] ?? '';
      _addressController.text = branch['address'] ?? '';

      final existingCode = (branch['code'] ?? '').toString().trim();
      if (existingCode.isNotEmpty) {
        _codeController.text = existingCode;
        setState(() {
          _isCodeLocked = true;
        });
      } else {
        await _autoGenerateCode();
      }
    } else {
      await _autoGenerateCode();
    }
  }

  Future<void> _autoGenerateCode() async {
    setState(() => _isGeneratingCode = true);
    try {
      final code = await ref.read(adminRepositoryProvider).generateNextBranchCode();
      if (mounted) {
        setState(() {
          _codeController.text = code;
          _isCodeLocked = false;
        });
      }
    } catch (_) {
      if (mounted && _codeController.text.trim().isEmpty) {
        final rand = (DateTime.now().millisecondsSinceEpoch % 900) + 100;
        setState(() {
          _codeController.text = 'GS$rand';
          _isCodeLocked = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.setupFranchise(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Refresh cached branches and providers
      ref.invalidate(branchesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Franchise setup saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $err'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: const Text('Franchise Setup', style: TextStyle(color: AppColors.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldCta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_outlined, color: AppColors.goldCta, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Franchise Profile',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isCodeLocked
                                ? 'Your Branch Code is assigned by Super Admin.'
                                : 'Unique Branch Code is automatically generated by the system.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                label: 'Branch/School Name',
                hint: 'e.g. Vishal Institute - City',
                icon: Icons.school_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Branch name is required' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _codeController,
                label: 'Branch Code',
                hint: 'e.g. GS001',
                icon: _isCodeLocked ? Icons.lock_outline : Icons.qr_code_outlined,
                readOnly: _isCodeLocked,
                helperText: _isCodeLocked
                    ? 'Assigned by Super Admin (Locked)'
                    : 'System Auto-Generated Unique Code',
                suffixIcon: _isCodeLocked
                    ? const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.check_circle_outline, color: AppColors.goldCta, size: 20),
                      )
                    : IconButton(
                        icon: _isGeneratingCode
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                              )
                            : const Icon(Icons.refresh_rounded, color: AppColors.goldCta),
                        tooltip: 'Generate new unique code',
                        onPressed: _isGeneratingCode ? null : _autoGenerateCode,
                      ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Branch code is required' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _ownerController,
                label: 'Owner Name',
                hint: 'Franchise Owner Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Contact Phone',
                hint: 'Phone number for this branch',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'Branch Address',
                hint: 'Full physical address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Save Setup',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
