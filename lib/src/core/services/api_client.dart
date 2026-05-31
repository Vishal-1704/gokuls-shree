import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_constants.dart';
import 'mock_data.dart';

// Provider definition
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (ApiConstants.useMock) {
      return _handleMockGet(path);
    }
    // Append API Key to all requests
    final params = queryParameters ?? {};
    params['api_key'] = ApiConstants.apiKey;

    // Map RESTful paths to 'action' parameter for PHP script
    // Example: /auth/verify -> action=verify
    if (path.startsWith('/')) {
      final action = _mapPathToAction(path);
      if (action != null) params['action'] = action;
    }

    return _dio.get('', queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    if (ApiConstants.useMock) {
      return _handleMockPost(path, requestData: data);
    }
    // PHP Script (mobile_api.php) is Read-Only (GET).
    // If we need POST, we might need to rely on the Real Website Forms via WebView.
    // OR if we strictly need to post simple data, we'd need to update mobile_api.php
    // For now, let's assume POST allows mocking for Login flow.
    return _dio.post('', data: data);
  }

  Future<Response> getBinary(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<Response> postBinary(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    final requestOptions = options ?? Options();
    requestOptions.responseType = ResponseType.bytes;

    return _dio.post(path, data: data, options: requestOptions);
  }

  // --- MOCK LOGIC ---

  Future<Response> _handleMockGet(String path) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Sim delay

    dynamic data;
    if (path.contains('profile')) {
      data = MockData.studentProfile;
    } else if (path.contains('results')) {
      data = MockData.studentResults;
    } else if (path.contains('verify')) {
      data = {"valid": true};
    } else if (path.contains('exams/questions')) {
      data = MockData.examQuestions;
    } else if (path.contains('exams')) {
      data = MockData.examList;
    } else {
      data = {"status": "error", "message": "Mock path not found"};
    }

    return Response(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }

  Future<Response> _handleMockPost(String path, {dynamic requestData}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    dynamic responseData;
    int statusCode = 200;

    if (path.contains('login')) {
      // Check if data contains admin email (Mock Logic)
      try {
        if (requestData is Map) {
          final email = requestData['email']?.toString().toLowerCase() ?? '';

          // STRICT ADMIN CHECK
          // In a real app, the server returns the role based on the DB.
          // Here, we simulate that DB lookup.
          final adminEmails = [
            'admin@gokulshreeschool.com',
            'randomabcd@gmail.com',
          ];

          if (adminEmails.contains(email)) {
            responseData = MockData.authAdminLoginSuccess;
          } else {
            // Default to Student for all other logins (Mock behavior)
            responseData = MockData.authLoginSuccess;
          }
        } else {
          responseData = MockData.authLoginSuccess;
        }
      } catch (e) {
        responseData = MockData.authLoginSuccess;
      }
    } else if (path.contains('register')) {
      responseData = MockData.authRegisterSuccess;
      statusCode = 201;
    } else {
      responseData = {"error": "Mock POST path not found"};
      statusCode = 404;
    }

    return Response(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: statusCode,
    );
  }

  String? _mapPathToAction(String path) {
    if (path.contains('profile')) return 'profile';
    if (path.contains('results')) return 'results';
    return null;
  }

  // Kept for backward compatibility if used directly
  Future<Map<String, dynamic>> getProfile(String regNo) async {
    final response = await get('/profile', queryParameters: {'reg_no': regNo});
    return response.data;
  }
}
