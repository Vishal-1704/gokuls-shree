import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

/// The real first screen after the native static splash
/// (android/app/src/main/res/drawable/splash_logo.jpeg) hands off to
/// Flutter. The logo art (GSMT.jpeg) is a square emblem with its own dark
/// wood-textured background baked in — _splashBg below is sampled to match
/// it, so the square sits seamlessly on the portrait screen instead of
/// looking boxed-in on a mismatched background, and matches the native
/// splash's own background so there's no color flash at the handoff.
/// Plays a one-shot bounce-in on the logo, then waits for whichever is
/// later — the animation actually finishing, or supabaseAuthProvider
/// leaving AuthLoading (the same session-restore signal app_router.dart
/// already uses) — before navigating on exactly once. This is also what
/// stops an already-logged-in user from briefly seeing a bare login form
/// while their session is still being restored.
const _splashBg = Color(0xFF1C1C1E);

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

    // Square emblem, portrait screen — fill most of the width (not a
    // fixed px size) so it scales sensibly across phone sizes, capped so
    // it never dominates a tall/narrow screen or a wide tablet.
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * 0.62).clamp(200.0, 360.0);

    return Scaffold(
      backgroundColor: _splashBg,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(logoSize * 0.08),
            child: Image.asset(
              'assets/images/GSMT.jpeg',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(width: logoSize, height: logoSize),
            ),
          ),
        ),
      ),
    );
  }
}
