import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationNumberGenerator {
  static Future<String> generateNext(SupabaseClient client) async {
    final existing = await _loadExistingRegistrationNumbers(client);
    if (existing.isEmpty) {
      return _defaultRegistration();
    }

    final template = existing.first;

    final yearPattern = RegExp(r'^([A-Za-z]+)[-/](\d{4})[-/](\d+)$');
    final templateYearMatch = yearPattern.firstMatch(template);
    if (templateYearMatch != null) {
      final prefix = templateYearMatch.group(1)!;
      final width = templateYearMatch.group(3)!.length;
      final year = DateTime.now().year.toString();

      final seriesPattern = RegExp(
        '^${RegExp.escape(prefix)}[-/]${RegExp.escape(year)}[-/](\\d+)\$',
      );

      var maxSerial = 0;
      for (final reg in existing) {
        final m = seriesPattern.firstMatch(reg);
        if (m == null) continue;
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > maxSerial) {
          maxSerial = n;
        }
      }

      final next = (maxSerial + 1).toString().padLeft(width, '0');
      return '$prefix-$year-$next';
    }

    final numericOnly = RegExp(r'^\d+$');
    if (numericOnly.hasMatch(template)) {
      var maxValue = 0;
      var width = template.length;

      for (final reg in existing) {
        if (!numericOnly.hasMatch(reg)) continue;
        width = reg.length > width ? reg.length : width;
        final n = int.tryParse(reg);
        if (n != null && n > maxValue) {
          maxValue = n;
        }
      }

      return (maxValue + 1).toString().padLeft(width, '0');
    }

    final suffixNumber = RegExp(r'^(.*?)(\d+)$');
    final suffixTemplateMatch = suffixNumber.firstMatch(template);
    if (suffixTemplateMatch != null) {
      final fixedPrefix = suffixTemplateMatch.group(1)!;
      final width = suffixTemplateMatch.group(2)!.length;
      final prefixPattern = RegExp('^${RegExp.escape(fixedPrefix)}(\\d+)\$');

      var maxValue = 0;
      for (final reg in existing) {
        final m = prefixPattern.firstMatch(reg);
        if (m == null) continue;
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > maxValue) {
          maxValue = n;
        }
      }

      return '$fixedPrefix${(maxValue + 1).toString().padLeft(width, '0')}';
    }

    return _defaultRegistration();
  }

  static Future<List<String>> _loadExistingRegistrationNumbers(
    SupabaseClient client,
  ) async {
    List<dynamic> rows;
    try {
      rows = await client
          .from('students')
          .select('registration_number')
          .not('registration_number', 'is', null)
          .order('created_at', ascending: true)
          .limit(1000);
    } catch (_) {
      rows = await client
          .from('students')
          .select('registration_number')
          .not('registration_number', 'is', null)
          .limit(1000);
    }

    return rows
        .map((e) => (e['registration_number'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _defaultRegistration() {
    final year = DateTime.now().year;
    return 'GS-$year-0001';
  }
}
