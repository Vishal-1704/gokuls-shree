import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(supabaseAuthNotifierProvider)
          .adminLogin(
            loginId: _loginIdController.text,
            password: _passwordController.text,
          );

      final authState = ref.read(supabaseAuthProvider);
      if (authState is AuthAuthenticated) {
        final role = authState.user.userMetadata?['role'];
        if (role == 'admin') {
          if (mounted) context.go('/admin/dashboard');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Access Denied: Not an Admin Account',
                    style: AppTypography.bodyMd.copyWith(color: Colors.white)),
                backgroundColor: AppColors.danger,
              ),
            );
            ref.read(supabaseAuthNotifierProvider).signOut();
          }
        }
      } else if (authState is AuthError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.message,
                  style: AppTypography.bodyMd.copyWith(color: Colors.white)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(supabaseAuthProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shield icon with gold accent
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: AppColors.goldCta,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fraunces italic title
                  Text(
                    'Admin Portal',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMd,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your institute',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd,
                  ),
                  const SizedBox(height: 48),

                  // Login ID Field — dark input
                  TextFormField(
                    controller: _loginIdController,
                    style: AppTypography.bodyLg,
                    decoration: InputDecoration(
                      labelText: 'Admin Login ID',
                      labelStyle: AppTypography.labelMd,
                      hintText: 'Enter your ID',
                      hintStyle: AppTypography.bodyMd.copyWith(
                          color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputFocusBorder, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Login ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field — dark input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: AppTypography.bodyLg,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: AppTypography.labelMd,
                      hintText: 'Enter your password',
                      hintStyle: AppTypography.bodyMd.copyWith(
                          color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.inputFocusBorder, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Gold CTA Login Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldCta,
                        foregroundColor: AppColors.inkNavy900,
                        disabledBackgroundColor:
                            AppColors.goldCta.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.inkNavy900,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Login to Dashboard',
                              style: AppTypography.headingSm.copyWith(
                                color: AppColors.inkNavy900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Back to Student App — gold text
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'Back to Student App',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.goldCta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

