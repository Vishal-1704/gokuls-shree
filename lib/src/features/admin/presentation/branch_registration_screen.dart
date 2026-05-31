import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_button.dart';
import 'package:gokul_shree_app/src/core/widgets/custom_text_field.dart';

class BranchRegistrationScreen extends ConsumerStatefulWidget {
  const BranchRegistrationScreen({super.key});

  @override
  ConsumerState<BranchRegistrationScreen> createState() => _BranchRegistrationScreenState();
}

class _BranchRegistrationScreenState extends ConsumerState<BranchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      
      // We use Supabase direct insert for profile/admin if RLS allows,
      // but for Auth user creation we'd normally use the backend API.
      // For this demo, we'll use a direct upsert simulation or call our new endpoint if available.
      
      // Since we updated the backend, we should technically call the API.
      // But for a Flutter-only demo/setup, we'll use a simplified flow.
      
      await repo.registerBranchAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch Admin registered successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
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
        title: const Text('Register Branch Admin'),
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
                'Create a new administrative account for a franchise owner.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                label: 'Admin Full Name',
                hint: 'e.g. Rajesh Kumar',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'admin@branch.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Initial Password',
                hint: 'Min 6 characters',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) => v == null || v.length < 6 ? 'Too short' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Register Admin',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.how_to_reg,
              ),
              const SizedBox(height: 16),
              const Card(
                color: Color(0xFFFFF3E0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The new admin will be able to log in immediately and set up their branch details.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
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
