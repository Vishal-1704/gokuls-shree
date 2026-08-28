import 'dart:io' as dart_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/app.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/navigation/back_handler.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 App starting...');

  // Register the global back-button handler ONCE — it never gets disposed.
  WidgetsBinding.instance.addObserver(BackHandler.instance);
  debugPrint('🔵 BackHandler registered globally');

  // Load environment configuration
  try {
    debugPrint('📂 Loading .env...');
    await EnvConfig.load();
    debugPrint('✅ Environment config loaded');
  } catch (e) {
    debugPrint('⚠️ Failed to load .env file: $e');
  }

  // --- NETWORK DIAGNOSTIC ---
  try {
    debugPrint('🔍 Running Network Diagnostic...');
    final uri = Uri.parse(EnvConfig.supabaseUrl);
    debugPrint('🔍 Testing connection to: ${uri.host} on port ${uri.port}');
    
    // Test DNS
    final lookup = await dart_io.InternetAddress.lookup(uri.host);
    debugPrint('🔍 DNS Lookup success: ${lookup.map((e) => e.address).toList()}');
    
    // Test Socket
    final socket = await dart_io.Socket.connect(uri.host, 443, timeout: const Duration(seconds: 5));
    debugPrint('✅ Raw Socket connected successfully! Remote: ${socket.remoteAddress.address}');
    socket.destroy();
  } catch (e, stacktrace) {
    debugPrint('❌ NETWORK DIAGNOSTIC FAILED!');
    debugPrint('Exception: $e');
    debugPrint('Stacktrace: $stacktrace');
  }
  // --- END DIAGNOSTIC ---

  // Initialize Supabase with credentials from env
  try {
    debugPrint('🗄️ Initializing Supabase...');
    await initializeSupabase();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization failed: $e');
    debugPrint('🔄 App will work in offline mode with mock data');
  }

  debugPrint('🎨 Calling runApp...');
  runApp(const ProviderScope(child: MyApp()));
}
