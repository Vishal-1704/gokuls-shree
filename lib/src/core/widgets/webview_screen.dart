import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';

/// In-app WebView screen for displaying web content
class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const InAppWebViewScreen({super.key, required this.url, required this.title});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0;
            });
          },
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'back':
                  if (await _controller.canGoBack()) {
                    _controller.goBack();
                  }
                  break;
                case 'forward':
                  if (await _controller.canGoForward()) {
                    _controller.goForward();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: 20),
                    SizedBox(width: 8),
                    Text('Go Back'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 20),
                    SizedBox(width: 8),
                    Text('Go Forward'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

/// Helper class with common website URLs
class WebUrls {
  static const String baseUrl = 'https://gokulshreeschool.com';

  static const String home = '$baseUrl/index.php';
  static const String studentLogin = '$baseUrl/login.php';
  static const String examPortal = '$baseUrl/login.php';
  static const String results = '$baseUrl/result.php';
  static const String admitCard = '$baseUrl/admit-card.php';
  static const String marksheetVerification =
      '$baseUrl/marksheet-verification.php';
  static const String certificateVerification =
      '$baseUrl/certificate-verification.php';
  static const String studentVerification = '$baseUrl/verification.php';
  static const String studentRegistration = '$baseUrl/student-registration.php';
  static const String aboutUs = '$baseUrl/about-us.php';
  static const String gallery = '$baseUrl/gallery.php';
  static const String franchise = '$baseUrl/franchise.php';
  static const String contactUs = '$baseUrl/contact-us.php';
  static const String downloads = '$baseUrl/downloads.php';
  static const String studyMaterial = '$baseUrl/downloads.php';

  // Course pages
  static const String diplomaCourses = '$baseUrl/diploma-courses.php';
  static const String vocationalCourses = '$baseUrl/vocational-courses.php';
  static const String yogaCourses = '$baseUrl/yoga-courses.php';
  static const String universityCourses = '$baseUrl/university-courses.php';
}
