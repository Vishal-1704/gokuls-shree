import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/routing/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final appTheme = ref.watch(appThemeProvider);

    // Global last-back timestamp for double-tap-to-exit at home
    DateTime? lastBack;

    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: appTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
