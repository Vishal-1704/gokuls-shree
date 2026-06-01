import 'package:flutter_test/flutter_test.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

void main() {
  test('EnvConfig loads real .env file and exposes values correctly', () async {
    // Call the actual configuration loader
    await EnvConfig.load();

    // Verify properties match the local .env configuration values
    expect(EnvConfig.supabaseUrl, 'https://azxgjuzohwdemwbtxnxl.supabase.co');
    expect(
      EnvConfig.supabaseAnonKey,
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6eGdqdXpvaHdkZW13YnR4bnhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMjkwNzksImV4cCI6MjA5NTgwNTA3OX0.y_h2AnsDPHjStWQMwOkMyDJvCNzWdSjldcxG8INxYUU',
    );
    expect(EnvConfig.apiBaseUrl, 'https://gokuls-shree-api.onrender.com/api/v1');
    expect(EnvConfig.apiTimeoutSeconds, 30);
    expect(EnvConfig.appName, 'Gokulshree School Of Management And Technology Pvt Ltd');
    expect(EnvConfig.appVersion, '1.0.0');
    expect(EnvConfig.debugMode, false);
    expect(EnvConfig.isSupabaseConfigured, true);
    expect(EnvConfig.isApiConfigured, true);
  });
}
