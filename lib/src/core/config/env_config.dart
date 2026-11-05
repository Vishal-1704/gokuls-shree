import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file with resilient defaults.
class EnvConfig {
  EnvConfig._();

  /// Load environment variables from .env file safely
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  /// Safe helper that returns null instead of throwing NotInitializedError
  /// when .env is uninitialized or missing.
  static String? _get(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet(key);
      }
    } catch (_) {}
    return null;
  }

  // ===========================================
  // SUPABASE CONFIGURATION
  // ===========================================

  static String get supabaseUrl => _get('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY') ?? '';

  // ===========================================
  // BACKEND API CONFIGURATION
  // ===========================================

  static String get apiBaseUrl =>
      _get('API_BASE_URL') ?? 'https://gokulshree-backend-860363218365.asia-south1.run.app/api/v1';

  static int get apiTimeoutSeconds =>
      int.tryParse(_get('API_TIMEOUT_SECONDS') ?? '30') ?? 30;

  // ===========================================
  // APP CONFIGURATION
  // ===========================================

  static String get appName => _get('APP_NAME') ?? 'Gokul Shree School';

  static String get appVersion => _get('APP_VERSION') ?? '1.0.0';

  static bool get debugMode =>
      _get('DEBUG_MODE')?.toLowerCase() == 'true';

  // ===========================================
  // WEBSITE URLS
  // ===========================================

  static String get websiteBaseUrl =>
      _get('WEBSITE_BASE_URL') ?? 'https://gokulshreeschool.com';

  /// Base URL used to build "verify this document" QR codes/links.
  static String get verifyBaseUrl =>
      _get('VERIFY_BASE_URL') ?? '$websiteBaseUrl/verify';

  // ===========================================
  // BRANDING
  // ===========================================

  /// Short brand name for compact UI (nav labels, ID cards, stylized headers).
  static String get shortName => _get('APP_SHORT_NAME') ?? 'Gokulshree';

  /// Full registered legal entity name — used on official documents.
  static String get legalName =>
      _get('LEGAL_NAME') ??
      'Gokulshree School Of Management And Technology Private Limited';

  /// Public-facing support/contact email.
  static String get supportEmail =>
      _get('SUPPORT_EMAIL') ?? 'info@gokulshreeschool.com';

  /// Registered office / contact address shown on the Contact screen
  static String get addressLine1 =>
      _get('INSTITUTE_ADDRESS_LINE1') ?? 'Gokul Shree School of Management';

  static String get addressLine2 =>
      _get('INSTITUTE_ADDRESS_LINE2') ?? 'Varanasi, Uttar Pradesh, India';

  /// Asset path to the primary logo, used across screens.
  static String get logoAssetPath =>
      _get('LOGO_ASSET_PATH') ?? 'assets/images/school_logo.png';

  /// Synthetic email domain used when a user logs in with a phone/reg-no
  static String get authEmailDomain =>
      _get('AUTH_EMAIL_DOMAIN') ?? 'gokulshree.local';

  // ===========================================
  // VALIDATION
  // ===========================================

  /// Check if Supabase is configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Check if API is configured
  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
