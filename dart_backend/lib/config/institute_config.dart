// lib/config/institute_config.dart
// Runtime-configurable institute branding for generated documents.
// Defaults match the current production institute (Gokul Shree) so an
// unconfigured deployment behaves exactly as before. Override via .env to
// white-label for a different institute without touching document_service.dart.
class InstituteConfig {
  InstituteConfig._();

  static String legalName =
      'Gokulshree School Of Management And Technology Private Limited';
  static String shortName = 'Gokulshree School';
  static String verifyBaseUrl = 'https://gokulshreeschool.com/verify';

  static void init({
    String? legalName,
    String? shortName,
    String? verifyBaseUrl,
  }) {
    if (legalName != null && legalName.isNotEmpty) {
      InstituteConfig.legalName = legalName;
    }
    if (shortName != null && shortName.isNotEmpty) {
      InstituteConfig.shortName = shortName;
    }
    if (verifyBaseUrl != null && verifyBaseUrl.isNotEmpty) {
      InstituteConfig.verifyBaseUrl = verifyBaseUrl;
    }
  }
}
