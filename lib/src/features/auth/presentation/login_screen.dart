import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';

/// STU-01 — Student Login (brand guide compliant)
/// Ink Navy background, Fraunces logo wordmark, Gold CTA.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupMobileController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isOtpMode = false;
  bool _otpSent = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _signupNameController.dispose();
    _signupMobileController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _mobileController.text.trim();
    if (_isOtpMode) {
      if (!_otpSent) {
        // Send OTP
        final email = identifier.contains('@') ? identifier : '$identifier@gokulshree.local';
        ref.read(supabaseAuthNotifierProvider).sendEmailOtp(email: email);
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $email')),
        );
      } else {
        // Verify OTP
        final otp = _otpController.text.trim();
        final email = identifier.contains('@') ? identifier : '$identifier@gokulshree.local';
        ref.read(supabaseAuthNotifierProvider).verifyEmailOtp(email: email, token: otp);
      }
    } else {
      // Password Login
      ref
          .read(supabaseAuthNotifierProvider)
          .signInWithMobile(identifier: identifier, password: _passwordController.text);
    }
  }

  Future<void> _callCentre() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openSignupSheet() async {
    final signupFormKey = GlobalKey<FormState>();
    var signupObscurePassword = true;
    var signupObscureConfirmPassword = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.inkNavy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Form(
                key: signupFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create Account', style: AppTypography.headingMd),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _signupNameController,
                      style: AppTypography.bodyLg,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _signupMobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: AppTypography.mono,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '9876543210',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Mobile number required';
                        if (value.length < 10) return 'Enter 10 digit mobile';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _signupPasswordController,
                      obscureText: signupObscurePassword,
                      style: AppTypography.bodyLg,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              signupObscurePassword = !signupObscurePassword;
                            });
                          },
                          icon: Icon(
                            signupObscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _signupConfirmPasswordController,
                      obscureText: signupObscureConfirmPassword,
                      style: AppTypography.bodyLg,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setModalState(() {
                              signupObscureConfirmPassword =
                                  !signupObscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            signupObscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v != _signupPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!signupFormKey.currentState!.validate()) return;

                          final mobile = _signupMobileController.text.trim();
                          final email = '$mobile@gokulshree.local';
                          final password = _signupPasswordController.text;
                          final name = _signupNameController.text.trim();

                          await ref
                              .read(supabaseAuthNotifierProvider)
                              .signUp(
                                email: email,
                                password: password,
                                name: name,
                                phone: mobile,
                              );

                          if (!mounted) return;

                          _mobileController.text = mobile;
                          _passwordController.text = password;

                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: const Text('CREATE ACCOUNT'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _routeAfterLogin(AuthAuthenticated next) async {
    final roleStr = next.profile?['role']?.toString();
    final role = UserRoleExt.fromString(roleStr);

    final homeRoute = UserSession(
      profileId: next.profile?['id']?.toString() ?? '',
      authUid: next.user.id,
      role: role,
      name: next.profile?['full_name']?.toString() ?? '',
      email: next.user.email ?? '',
      permissions: List<String>.from(next.profile?['permissions'] ?? []),
    ).homeRoute;

    debugPrint('Login redirect: role=$role, routing to $homeRoute');
    if (mounted) {
      context.go(homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(supabaseAuthProvider);
    final isLoading = authState is AuthLoading;

    // Listen for auth state changes
    ref.listen<SupabaseAuthState>(supabaseAuthProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _routeAfterLogin(next);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 1. Logo ──
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldCta.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldCta.withOpacity(0.1),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/school_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── 2. Title (Fraunces italic) ──
                    Text(
                      'Gokulshree',
                      style: AppTypography.displayLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Student Portal',
                      style: AppTypography.headingMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter Email or Mobile',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // ── 3. Mobile Number Field ──
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyLg,
                      decoration: const InputDecoration(
                        labelText: 'Email or Mobile',
                        hintText: 'admin@school.com or 9876...',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email or Mobile daalo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Toggle Password / OTP ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Password'),
                          selected: !_isOtpMode,
                          onSelected: (val) {
                            setState(() {
                              _isOtpMode = false;
                              _otpSent = false;
                            });
                          },
                          selectedColor: AppColors.goldCta.withOpacity(0.2),
                          labelStyle: TextStyle(
                              color: !_isOtpMode ? AppColors.goldCta : AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('OTP'),
                          selected: _isOtpMode,
                          onSelected: (val) {
                            setState(() {
                              _isOtpMode = true;
                              _otpSent = false;
                            });
                          },
                          selectedColor: AppColors.goldCta.withOpacity(0.2),
                          labelStyle: TextStyle(
                              color: _isOtpMode ? AppColors.goldCta : AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 4. Password / OTP Field ──
                    if (!_isOtpMode)
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: AppTypography.bodyLg,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password daalo';
                          }
                          return null;
                        },
                      )
                    else if (_otpSent)
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: AppTypography.mono.copyWith(letterSpacing: 2.0),
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Enter 6-digit OTP';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── 5. Login Button (Gold CTA) ──
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.inkNavy900,
                                ),
                              )
                            : Text(_isOtpMode && !_otpSent ? 'SEND OTP' : 'LOGIN'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── 6. Forgot Password ──
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        'Bhool gaye password?',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.goldCta,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _openSignupSheet,
                      child: Text(
                        'Create new account',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── 7. Help Link ──
                    TextButton.icon(
                      onPressed: _callCentre,
                      icon: const Icon(Icons.phone_outlined, size: 16),
                      label: Text(
                        'Centre pe call karo',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
