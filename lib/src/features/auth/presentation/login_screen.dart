import 'dart:ui' as ui;
import 'dart:async' as async_timer;
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
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

/// STU-01 — Student Login with Premium Glassmorphism Design.
/// Frosted glass cards, radial glow blobs, and beautiful custom inputs.
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
  bool _obscurePassword = true;

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
    ref
        .read(supabaseAuthNotifierProvider)
        .signInWithMobile(identifier: identifier, password: _passwordController.text);
  }

  Future<void> _callCentre() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Helper for glassy input decorations
  InputDecoration _buildGlassInputDecoration({
    required String labelText,
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTypography.bodyMd.copyWith(
        color: AppColors.textSecondary.withOpacity(0.8),
      ),
      hintText: hintText,
      hintStyle: AppTypography.bodyMd.copyWith(
        color: AppColors.textSecondary.withOpacity(0.4),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.goldCta,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _openSignupSheet() async {
    final signupFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final fatherNameController = TextEditingController();
    final dobController = TextEditingController();
    final addressController = TextEditingController();

    String? selectedGender;
    int? selectedCourseId;
    int? selectedBranchId;
    var signupObscurePassword = true;
    var signupObscureConfirmPassword = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for custom glass shape
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Form(
                  key: signupFormKey,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Student Self-Registration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provide full details to request access',
                        style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: nameController,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'As per documents',
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: mobileController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: AppTypography.mono.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Mobile Number',
                                  hintText: '10 digit number',
                                  prefixIcon: const Icon(Icons.phone_android_outlined),
                                ),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Mobile required';
                                  if (value.length < 10) return 'Enter 10 digit mobile';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: fatherNameController,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Father\'s Name',
                                  hintText: 'Father\'s full name',
                                  prefixIcon: const Icon(Icons.people_outline),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: dobController,
                                readOnly: true,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Date of Birth (YYYY-MM-DD)',
                                  hintText: 'Select DOB',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime(2005),
                                    firstDate: DateTime(1980),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() {
                                      dobController.text = date.toIso8601String().substring(0, 10);
                                    });
                                  }
                                },
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                dropdownColor: const Color(0xFF0F172A),
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Gender',
                                  hintText: 'Select Gender',
                                  prefixIcon: const Icon(Icons.wc_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(color: Colors.white))),
                                ],
                                onChanged: (v) => setModalState(() => selectedGender = v),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: addressController,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Permanent Address',
                                  hintText: 'Enter full address',
                                  prefixIcon: const Icon(Icons.home_outlined),
                                ),
                                maxLines: 2,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              Consumer(
                                builder: (context, ref, child) {
                                  final coursesAsync = ref.watch(adminCoursesProvider);
                                  return coursesAsync.when(
                                    data: (courses) => DropdownButtonFormField<int>(
                                      value: selectedCourseId,
                                      dropdownColor: const Color(0xFF0F172A),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _buildGlassInputDecoration(
                                        labelText: 'Select Course',
                                        hintText: 'Choose course',
                                        prefixIcon: const Icon(Icons.school_outlined),
                                      ),
                                      items: courses.map((c) => DropdownMenuItem<int>(
                                        value: c['id'] as int,
                                        child: Text(c['name']?.toString() ?? c['title']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                                      )).toList(),
                                      onChanged: (val) => setModalState(() => selectedCourseId = val),
                                      validator: (v) => v == null ? 'Course required' : null,
                                    ),
                                    loading: () => const Center(child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(color: AppColors.goldCta),
                                    )),
                                    error: (e, _) => const Text('Error loading courses', style: TextStyle(color: AppColors.danger)),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Consumer(
                                builder: (context, ref, child) {
                                  final branchesAsync = ref.watch(branchesProvider);
                                  return branchesAsync.when(
                                    data: (branches) => DropdownButtonFormField<int>(
                                      value: selectedBranchId,
                                      dropdownColor: const Color(0xFF0F172A),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _buildGlassInputDecoration(
                                        labelText: 'Select Branch',
                                        hintText: 'Choose branch',
                                        prefixIcon: const Icon(Icons.location_city_outlined),
                                      ),
                                      items: branches.map((b) => DropdownMenuItem<int>(
                                        value: b['id'] as int,
                                        child: Text(b['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                                      )).toList(),
                                      onChanged: (val) => setModalState(() => selectedBranchId = val),
                                      validator: (v) => v == null ? 'Branch required' : null,
                                    ),
                                    loading: () => const Center(child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(color: AppColors.goldCta),
                                    )),
                                    error: (e, _) => const Text('Error loading branches', style: TextStyle(color: AppColors.danger)),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                obscureText: signupObscurePassword,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Create Password',
                                  hintText: 'At least 6 characters',
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
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmPasswordController,
                                obscureText: signupObscureConfirmPassword,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Retype password',
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
                                  if (v != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: AppSpacing.buttonHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.goldCta,
                                    foregroundColor: AppColors.inkNavy900,
                                    elevation: 4,
                                    shadowColor: AppColors.goldCta.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (!signupFormKey.currentState!.validate()) return;

                                    final mobile = mobileController.text.trim();
                                    final email = '$mobile@gokulshree.local';
                                    final password = passwordController.text;
                                    final name = nameController.text.trim();

                                    final success = await ref
                                        .read(supabaseAuthNotifierProvider)
                                        .signUp(
                                          email: email,
                                          password: password,
                                          name: name,
                                          phone: mobile,
                                          fatherName: fatherNameController.text.trim(),
                                          dob: dobController.text.trim(),
                                          address: addressController.text.trim(),
                                          gender: selectedGender,
                                          courseId: selectedCourseId,
                                          branchId: selectedBranchId,
                                        );

                                    if (success && mounted) {
                                      if (Navigator.of(sheetContext).canPop()) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                      context.go('/login');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Registration submitted. Wait for admin approval before logging in.'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'SUBMIT REGISTRATION',
                                    style: AppTypography.labelLg.copyWith(
                                      color: AppColors.inkNavy900,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: Stack(
        children: [
          // ── Radial background glow blobs ──
          Positioned(
            top: -screenSize.height * 0.1,
            left: -screenSize.width * 0.2,
            child: Container(
              width: screenSize.width * 0.8,
              height: screenSize.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.18), // indigo glow
                    const Color(0xFF6366F1).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -screenSize.height * 0.1,
            right: -screenSize.width * 0.2,
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldCta.withOpacity(0.1), // gold glow
                    AppColors.goldCta.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenSize.height * 0.35,
            right: -screenSize.width * 0.3,
            child: Container(
              width: screenSize.width * 0.7,
              height: screenSize.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.08), // pink glow
                    const Color(0xFFEC4899).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Full screen backdrop filter ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Main scrollable content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: 16,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Guest Sliding Carousel ──
                        const GuestCarousel(),
                        const SizedBox(height: 20),

                        // ── Glassmorphic card container ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 40,
                                spreadRadius: -5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Logo with frosted outer border ──
                              Container(
                                height: 84,
                                width: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.03),
                                  border: Border.all(
                                    color: AppColors.goldCta.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldCta.withOpacity(0.08),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/school_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Display Wordmark & Portal title ──
                              Text(
                                'Gokulshree',
                                style: AppTypography.displayLg.copyWith(
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Student Portal',
                                style: AppTypography.headingSm.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),

                              // ── Mobile / Registration No. field ──
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Mobile or Reg No.',
                                  hintText: 'Enter Mobile, Reg No, or Email',
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Mobile or Reg No required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password input field ──
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                style: AppTypography.bodyLg.copyWith(color: Colors.white),
                                decoration: _buildGlassInputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary.withOpacity(0.6),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── Login Button (Gold CTA) ──
                              SizedBox(
                                width: double.infinity,
                                height: AppSpacing.buttonHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.goldCta,
                                    foregroundColor: AppColors.inkNavy900,
                                    elevation: 6,
                                    shadowColor: AppColors.goldCta.withOpacity(0.25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
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
                                      : Text(
                                          'LOGIN',
                                          style: AppTypography.labelLg.copyWith(
                                            color: AppColors.inkNavy900,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Utility text buttons under card ──
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(
                            'Bhool gaye password?',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.goldCta,
                              fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 8),

                        // ── Call Support button ──
                        TextButton.icon(
                          onPressed: _callCentre,
                          icon: const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.white24,
                          ),
                          label: Text(
                            'Centre pe call karo',
                            style: AppTypography.bodySm.copyWith(
                              color: Colors.white30,
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
        ],
      ),
    );
  }
}

// ── Sliding/Fading Guest Carousel Widget ──
class GuestCarousel extends StatefulWidget {
  const GuestCarousel({super.key});

  @override
  State<GuestCarousel> createState() => _GuestCarouselState();
}

class _GuestCarouselState extends State<GuestCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final async_timer.Timer _timer;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to Gokulshree',
      'subtitle': 'An Institution of Academic Excellence & Leadership',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Sleek Digital Portal',
      'subtitle': 'Access your marks, exams, and notices instantly in real-time',
      'icon': Icons.dashboard_customize_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Digital Identity Card',
      'subtitle': 'Verified profile details and smart access management',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = async_timer.Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        slide['color'].withOpacity(0.12),
                        slide['color'].withOpacity(0.01),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: slide['color'].withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slide['icon'], size: 28, color: AppColors.goldCta),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slide['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide['subtitle'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.goldCta : AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
