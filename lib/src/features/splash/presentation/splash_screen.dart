import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

/// The real first screen after the native static splash
/// (android/app/src/main/res/drawable/splash_logo.png) hands off to
/// Flutter. White background matches the native splash exactly so there's
/// no color flash at the handoff. Plays a one-shot bounce-in on the logo,
/// then waits for whichever is later — the animation actually finishing,
/// or supabaseAuthProvider leaving AuthLoading (the same session-restore
/// signal app_router.dart already uses) — before navigating on exactly
/// once. This is also what stops an already-logged-in user from briefly
/// seeing a bare login form while their session is still being restored.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _hasNavigated = false;
  bool _minDurationElapsed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _minDurationElapsed = true);
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (_hasNavigated || !_minDurationElapsed) return;
    final authState = ref.read(supabaseAuthProvider);
    if (authState is AuthLoading) return;

    _hasNavigated = true;
    final session = ref.read(sessionProvider);
    context.go(session?.homeRoute ?? '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Re-checks navigation readiness on every auth-state change, exactly
    // like app_router.dart's own redirect does via refreshListenable.
    ref.listen(supabaseAuthProvider, (previous, next) => _maybeNavigate());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Image.asset(
            'assets/images/splash_logo.png',
            width: 220,
            errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 220),
          ),
        ),
      ),
    );
  }
}
