import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:gokul_shree_app/src/core/services/api_client.dart';
import 'package:crypto/crypto.dart';

class SubjectResult {
  final String name;
  final int maxMarks;
  final int obtainedMarks;

  SubjectResult({
    required this.name,
    required this.maxMarks,
    required this.obtainedMarks,
  });
}

class MarksheetService {
  final ApiClient _apiClient;

  // Utilize the apiClient if provided, otherwise default to a new instance.
  MarksheetService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches the Marksheet PDF from the backend server (Node.js + Puppeteer).
  ///
  /// The [regNo] is used to identify the student and generate the PDF
  /// by scraping the live website.
  Future<Uint8List> generateMarksheet({
    required String studentName,
    required String regNo,
    required String courseName,
    required String session,
    required List<SubjectResult> subjects,
    required String marksheetId,
    required String verificationUrl,
    String? fatherName,
    String? centreName,
    String? courseDuration,
    Uint8List? bgImageBytes,
    Uint8List? logoImageBytes,
    Uint8List? isoImageBytes,
    Uint8List? msmeImageBytes,
    Uint8List? skillImageBytes,
  }) async {
    try {
      // Using 127.0.0.1 for physical device with `adb reverse tcp:3000 tcp:3000`
      // For emulator, use 10.0.2.2. But 127.0.0.1 works for emulator too IF you run adb reverse.
      // However, 10.0.2.2 is simpler for emulator only.
      // Since user is on physical device, we MUST use 127.0.0.1 + adb reverse.
      const pdfServiceUrl =
          'http://127.0.0.1:3000/api/v1/documents/generate_pdf';

      final response = await _apiClient.postBinary(
        pdfServiceUrl,
        data: {'regno': regNo, 'type': 'marksheet'},
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      // Return bytes
      if (response.data is List<int>) {
        return Uint8List.fromList(response.data);
      } else if (response.data is Uint8List) {
        return response.data;
      } else {
        throw Exception(
          'Unexpected response type: ${response.data.runtimeType}',
        );
      }
    } catch (e) {
      throw Exception('Failed to download marksheet PDF: $e');
    }
  }

  // Helper method kept for compatibility, though not used for server generation
  String computeHash(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return sha256.convert(bytes).toString();
  }
}
