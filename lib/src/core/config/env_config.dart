import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
class EnvConfig {
  // Private constructor
  EnvConfig._();

  /// Load environment variables from .env file
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ===========================================
  // SUPABASE CONFIGURATION
  // ===========================================

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ===========================================
  // BACKEND API CONFIGURATION
  // ===========================================

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;

  // ===========================================
  // APP CONFIGURATION
  // ===========================================

  static String get appName => dotenv.env['APP_NAME'] ?? 'Gokul Shree School';

  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  // ===========================================
  // WEBSITE URLS
  // ===========================================

  static String get websiteBaseUrl =>
      dotenv.env['WEBSITE_BASE_URL'] ?? 'https://gokulshreeschool.com';

  /// Base URL used to build "verify this document" QR codes/links.
  static String get verifyBaseUrl =>
      dotenv.env['VERIFY_BASE_URL'] ?? '$websiteBaseUrl/verify';

  // ===========================================
  // BRANDING
  // ===========================================
  // Every value here has a default matching the current production institute
  // (Gokul Shree) so existing deployments keep working unchanged. To white-label
  // for a different institute, override these via .env instead of editing code.

  /// Short brand name for compact UI (nav labels, ID cards, stylized headers).
  static String get shortName => dotenv.env['APP_SHORT_NAME'] ?? 'Gokulshree';

  /// Full registered legal entity name — used on official documents.
  static String get legalName =>
      dotenv.env['LEGAL_NAME'] ??
      'Gokulshree School Of Management And Technology Private Limited';

  /// Public-facing support/contact email.
  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'info@gokulshreeschool.com';

  /// Registered office / contact address shown on the Contact screen
  /// (split in two so no newline-escaping is needed inside .env values).
  static String get addressLine1 =>
      dotenv.env['INSTITUTE_ADDRESS_LINE1'] ?? 'Gokul Shree School of Management';

  static String get addressLine2 =>
      dotenv.env['INSTITUTE_ADDRESS_LINE2'] ?? 'Varanasi, Uttar Pradesh, India';

  /// Asset path to the primary logo, used across screens.
  static String get logoAssetPath =>
      dotenv.env['LOGO_ASSET_PATH'] ?? 'assets/images/school_logo.png';

  /// Synthetic email domain used when a user logs in with a phone/reg-no
  /// instead of an email (Supabase Auth requires an email address). Kept
  /// stable per-deployment — changing it invalidates existing synthetic
  /// accounts already stored in that deployment's Supabase project.
  static String get authEmailDomain =>
      dotenv.env['AUTH_EMAIL_DOMAIN'] ?? 'gokulshree.local';

  // ===========================================
  // VALIDATION
  // ===========================================

  /// Check if Supabase is configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Check if API is configured
  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
