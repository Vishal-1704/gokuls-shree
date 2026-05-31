import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to interact with the custom Node.js backend
class BackendService {
  final Dio _dio;

  BackendService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  Future<Uint8List> fetchMarksheetPdf(String regNo) async {
    return _generateWebsitePdf(regNo: regNo, type: 'marksheet');
  }

  Future<Uint8List> fetchCertificatePdf(String regNo) async {
    return _generateWebsitePdf(regNo: regNo, type: 'certificate');
  }

  Future<Uint8List> _generateWebsitePdf({
    required String regNo,
    required String type,
  }) async {
    final candidates = _buildCandidateUrls();
    Object? lastError;

    for (final url in candidates) {
      try {
        final response = await _dio.post<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
          data: {'regno': regNo, 'type': type},
        );

        final data = response.data;
        if (response.statusCode == 200 && data != null && data.isNotEmpty) {
          return Uint8List.fromList(data);
        }
      } catch (e) {
        lastError = e;
        debugPrint('PDF endpoint failed: $url -> $e');
      }
    }

    throw Exception(
      'Failed to fetch PDF from all configured endpoints. Last error: $lastError',
    );
  }

  List<String> _buildCandidateUrls() {
    final envBase = EnvConfig.apiBaseUrl.trim();
    final websiteBase = EnvConfig.websiteBaseUrl.trim();

    final rawCandidates = <String>[
      envBase.endsWith('/v1') || envBase.endsWith('/v1/')
          ? '$envBase/documents/generate_pdf'
          : '$envBase/v1/documents/generate_pdf',
      // Emulator-hosted backend.
      'http://10.0.2.2:3000/api/v1/documents/generate_pdf',
      // Physical-device-hosted backend via adb reverse.
      'http://127.0.0.1:3000/api/v1/documents/generate_pdf',
      'http://localhost:3000/api/v1/documents/generate_pdf',
      // Deployed API variants.
      '$websiteBase/api/v1/documents/generate_pdf',
      '$websiteBase/v1/documents/generate_pdf',
      'https://www.gokulshreeschool.com/api/v1/documents/generate_pdf',
      'https://www.gokulshreeschool.com/v1/documents/generate_pdf',
    ];

    final normalized = <String>[];
    for (final value in rawCandidates) {
      final cleaned = value
          .replaceAll(RegExp(r'(?<!:)//+'), '/')
          .replaceAll('http:/', 'http://')
          .replaceAll('https:/', 'https://');
      if (!normalized.contains(cleaned)) {
        normalized.add(cleaned);
      }
    }
    return normalized;
  }

  /// Download a digitally signed marksheet
  /// Returns the file path of the downloaded PDF
  Future<String?> downloadMarksheet(String regNo) async {
    try {
      final filePath = '${Directory.systemTemp.path}/Marksheet_$regNo.pdf';
      final pdfBytes = await fetchMarksheetPdf(regNo);
      await File(filePath).writeAsBytes(pdfBytes, flush: true);
      return filePath;
    } catch (e) {
      debugPrint('Error downloading marksheet: $e');
      rethrow;
    }
  }
}

final backendServiceProvider = Provider<BackendService>((ref) {
  return BackendService();
});
