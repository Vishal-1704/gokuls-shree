import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _requestSent = false;

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final mobile = _mobileController.text.trim();
    final internalEmail = '$mobile@gokulshree.local';

    final success = await ref
        .read(supabaseAuthNotifierProvider)
        .resetPassword(internalEmail);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _requestSent = success;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to request reset. Please contact administration.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.inkNavy800,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldCta.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 48,
                    color: AppColors.goldCta,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Heading
              Text(
                "Reset Password",
                style: AppTypography.displaySm.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              if (_requestSent) ...[
                // Success State
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Reset Request Sent!",
                        style: AppTypography.headingMd.copyWith(color: AppColors.success),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "We've received your request. The administration will verify your details and issue a new password shortly.",
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldCta,
                      foregroundColor: AppColors.inkNavy900,
                    ),
                    child: const Text('BACK TO LOGIN'),
                  ),
                ),
              ] else ...[
                // Input State
                Text(
                  "Enter your registered mobile number below. We'll alert the administration to verify and reset your access.",
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xxxl),
                
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    style: AppTypography.mono.copyWith(letterSpacing: 1.5),
                    decoration: InputDecoration(
                      labelText: 'Registered Mobile Number',
                      hintText: '9876543210',
                      prefixIcon: const Icon(Icons.phone_android),
                      prefixText: '+91 ',
                      prefixStyle: AppTypography.mono.copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.inkNavy800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Must be at least 10 digits';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldCta,
                      foregroundColor: AppColors.inkNavy900,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.inkNavy900,
                            ),
                          )
                        : const Text('SEND RESET REQUEST'),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:+919876543210');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text('Call Support Directly'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

