import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_button.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(adminRepositoryProvider);
    final branch = await repo.getMyBranch();
    if (branch != null) {
      _nameController.text = branch['name'] ?? '';
      _codeController.text = branch['code'] ?? '';
      _ownerController.text = branch['owner_name'] ?? '';
      _phoneController.text = branch['contact_phone'] ?? '';
      _addressController.text = branch['address'] ?? '';
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Franchise setup saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Franchise Setup'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete your branch details to start managing students and staff.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                label: 'Branch/School Name',
                hint: 'e.g. Gokul Shree - Madhepura',
                icon: Icons.school_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _codeController,
                label: 'Branch Code',
                hint: 'e.g. GS001',
                icon: Icons.qr_code_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                icon: Icons.location_on_outline,
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
