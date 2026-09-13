import 'dart:ui' as ui;
import 'dart:async' as async_timer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum LoginStep { phone, password, legacyVerify, register }

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  LoginStep _currentStep = LoginStep.phone;
  PhoneLookupResult? _lookupResult;
  bool _isLoading = false;
  bool _isSlowNetwork = false;
  async_timer.Timer? _latencyTimer;
  
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _legacyPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _keepOldPassword = false;
  bool _isVerifyingLegacy = false;

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
    
    // Clear any stuck auth states if they have been loading for too long
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
         final state = ref.read(supabaseAuthProvider);
         if (state is AuthLoading) {
           // We might be stuck, we should stop local loading at least
           setState(() => _isLoading = false);
         }
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _legacyPasswordController.dispose();
    _signupEmailController.dispose();
    _signupNameController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _fadeController.dispose();
    _latencyTimer?.cancel();
    super.dispose();
  }

  void _startLatencyTimer() {
    _latencyTimer?.cancel();
    _latencyTimer = async_timer.Timer(const Duration(seconds: 2), () {
      if (mounted && (_isLoading || ref.read(supabaseAuthProvider) is AuthLoading)) {
        setState(() => _isSlowNetwork = true);
      }
    });
  }

  void _cancelLatencyTimer() {
    _latencyTimer?.cancel();
    if (_isSlowNetwork && mounted) {
      setState(() => _isSlowNetwork = false);
    }
  }

  void _handleNext() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _mobileController.text.trim();
    if (phone.isEmpty) return;
    
    _startLatencyTimer();
    setState(() => _isLoading = true);
    
    try {
      final result = await ref.read(supabaseAuthNotifierProvider).checkPhoneNumber(phone);
      
      if (!mounted) return;
      _cancelLatencyTimer();
      setState(() => _isLoading = false);

      if (result.isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate phone number found. Please contact branch admin.')));
        return;
      }
      // Removed the block that returns if (!result.isFound) so they can proceed to signup

      setState(() {
        _lookupResult = result;
        // A found-but-unclaimed record must prove ownership via its old
        // legacy password before it can set up a new login — previously
        // this jumped straight to "create your account," which let anyone
        // who knew the phone number claim it as their own.
        _currentStep = result.hasAuthAccount ? LoginStep.password : LoginStep.legacyVerify;
      });
    } catch (e) {
      if (!mounted) return;
      _cancelLatencyTimer();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleLegacyVerify() async {
    final legacyPassword = _legacyPasswordController.text;
    if (legacyPassword.isEmpty) return;

    setState(() => _isVerifyingLegacy = true);
    try {
      final verified = await ref.read(supabaseAuthNotifierProvider).verifyLegacyPassword(
            phone: _mobileController.text.trim(),
            legacyPassword: legacyPassword,
          );
      if (!mounted) return;
      setState(() => _isVerifyingLegacy = false);

      if (verified) {
        setState(() => _currentStep = LoginStep.register);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That password doesn\'t match our records. Please try again or contact your branch admin.'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifyingLegacy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    if (_lookupResult == null || _lookupResult!.email == null) return;
    
    ref.read(supabaseAuthNotifierProvider).signIn(
      email: _lookupResult!.email!,
      password: _passwordController.text,
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_keepOldPassword && _signupPasswordController.text != _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    // Skipping "create a new password" keeps the legacy password they just
    // verified with as their login going forward, per the checkbox.
    final finalPassword = _keepOldPassword ? _legacyPasswordController.text : _signupPasswordController.text;
    await ref.read(supabaseAuthNotifierProvider).registerWithPhone(
      phone: _mobileController.text.trim(),
      email: _signupEmailController.text.trim(),
      password: finalPassword,
      name: _signupNameController.text.trim(),
      legacyPassword: _legacyPasswordController.text,
    );
    if (mounted && ref.read(supabaseAuthProvider) is! AuthError) {
      setState(() { _currentStep = LoginStep.password; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration successful. Please log in.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _callCentre() async {
    final uri = Uri.parse('tel:+919670052700');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  InputDecoration _buildGlassInputDecoration({
    required String labelText,
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary.withOpacity(0.8)),
      hintText: hintText,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary.withOpacity(0.4)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.textPrimary.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: AppColors.textPrimary.withOpacity(0.08), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.goldCta, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
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
    final isGlobalLoading = authState is AuthLoading;
    final isBusy = _isLoading || isGlobalLoading;

    ref.listen<SupabaseAuthState>(supabaseAuthProvider, (previous, next) {
      if (next is AuthLoading) {
        _startLatencyTimer();
      } else {
        _cancelLatencyTimer();
      }

      if (next is AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        _routeAfterLogin(next);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.inkNavy900, AppColors.inkNavy800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Glow Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldCta.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GuestCarousel(),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.textPrimary.withOpacity(0.08), width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 16),
                              Text(EnvConfig.shortName, style: AppTypography.headingLg.copyWith(color: AppColors.goldCta)),
                              const SizedBox(height: 4),
                              Text('Student Portal', style: AppTypography.bodyLg.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 32),

                              if (_currentStep == LoginStep.phone) _buildPhoneStep(isBusy),
                              if (_currentStep == LoginStep.password) _buildPasswordStep(isBusy),
                              if (_currentStep == LoginStep.legacyVerify) _buildLegacyVerifyStep(),
                              if (_currentStep == LoginStep.register) _buildRegisterStep(isBusy),

                              if (_isSlowNetwork)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.wifi_find, color: AppColors.warning, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Slow internet detected. Login may take longer than usual.',
                                            style: AppTypography.bodySm.copyWith(color: AppColors.warning),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (_currentStep != LoginStep.phone)
                              TextButton(
                                onPressed: () => setState(() {
                                  _currentStep = LoginStep.phone;
                                  _passwordController.clear();
                                }),
                                child: Text('Back', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                              ),

                          ],
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

  Widget _buildLogo() {
    return Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textPrimary.withOpacity(0.03),
        border: Border.all(color: AppColors.goldCta.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.goldCta.withOpacity(0.08), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 40, color: AppColors.goldCta)),
      ),
    );
  }

  Widget _buildPhoneStep(bool isBusy) {
    return Column(
      children: [
        TextFormField(
          controller: _mobileController,
          style: AppTypography.bodyMd,
          keyboardType: TextInputType.phone,
          decoration: _buildGlassInputDecoration(
            labelText: 'Mobile Number',
            hintText: 'Enter your registered mobile',
            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isBusy ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              foregroundColor: AppColors.inkNavy900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isBusy
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900))
                : Text('CONTINUE', style: AppTypography.labelLg.copyWith(color: AppColors.inkNavy900, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(bool isBusy) {
    return Column(
      children: [
        Text(
          'Welcome back!\nPlease enter your password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.success),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AppTypography.bodyMd,
          decoration: _buildGlassInputDecoration(
            labelText: 'Password',
            hintText: 'Enter your secure password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isBusy ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              foregroundColor: AppColors.inkNavy900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isBusy
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900))
                : Text('LOGIN', style: AppTypography.labelLg.copyWith(color: AppColors.inkNavy900, fontSize: 16)),
          ),
        ),
        TextButton(
          onPressed: () => context.push('/forgot-password'),
          child: Text('Forgot password?', style: AppTypography.bodyMd.copyWith(color: AppColors.goldCta, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildLegacyVerifyStep() {
    return Column(
      children: [
        Text(
          'We found your record!\nEnter your previous password to confirm it\'s you.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.success),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _legacyPasswordController,
          obscureText: _obscurePassword,
          style: AppTypography.bodyMd,
          decoration: _buildGlassInputDecoration(
            labelText: 'Previous Password',
            hintText: 'The password you used before',
            prefixIcon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isVerifyingLegacy ? null : _handleLegacyVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              foregroundColor: AppColors.inkNavy900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isVerifyingLegacy
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900))
                : Text('VERIFY', style: AppTypography.labelLg.copyWith(color: AppColors.inkNavy900, fontSize: 16)),
          ),
        ),
        TextButton(
          onPressed: _callCentre,
          child: Text('Don\'t remember it? Call your branch', style: AppTypography.bodyMd.copyWith(color: AppColors.goldCta, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildRegisterStep(bool isBusy) {
    return Column(
      children: [
        Text(
          'Complete your registration\nWe found your record!',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.success),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _signupNameController,
          style: AppTypography.bodyMd,
          decoration: _buildGlassInputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _signupEmailController,
          style: AppTypography.bodyMd,
          decoration: _buildGlassInputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _keepOldPassword,
          onChanged: (v) => setState(() => _keepOldPassword = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.goldCta,
          title: Text('Keep using my previous password', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
        ),
        if (!_keepOldPassword) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _signupPasswordController,
            obscureText: _obscurePassword,
            style: AppTypography.bodyMd,
            decoration: _buildGlassInputDecoration(
              labelText: 'Create Password',
              hintText: 'Minimum 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (_keepOldPassword || (v != null && v.length >= 6)) ? null : 'Min 6 characters',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupConfirmPasswordController,
            obscureText: _obscurePassword,
            style: AppTypography.bodyMd,
            decoration: _buildGlassInputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
            ),
            validator: (v) => (_keepOldPassword || (v != null && v.isNotEmpty)) ? null : 'Required',
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isBusy ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldCta,
              foregroundColor: AppColors.inkNavy900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isBusy
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkNavy900))
                : Text('REGISTER', style: AppTypography.labelLg.copyWith(color: AppColors.inkNavy900, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class GuestCarousel extends StatefulWidget {
  const GuestCarousel({super.key});

  @override
  State<GuestCarousel> createState() => _GuestCarouselState();
}

class _GuestCarouselState extends State<GuestCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  async_timer.Timer? _timer;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to Gokulshree',
      'subtitle': 'An Institution of Academic Excellence & Leadership',
      'icon': Icons.school_rounded,
    },
    {
      'title': 'Track Progress',
      'subtitle': 'Real-time attendance, results, and notices',
      'icon': Icons.trending_up_rounded,
    },
    {
      'title': 'Stay Connected',
      'subtitle': 'Direct communication with faculty and branch admins',
      'icon': Icons.forum_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = async_timer.Timer.periodic(const Duration(seconds: 4), (Timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textPrimary.withOpacity(0.08)),
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldCta.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slide['icon'], color: AppColors.goldCta, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slide['title'], style: AppTypography.bodyLg.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(slide['subtitle'], style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.goldCta : AppColors.textPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
