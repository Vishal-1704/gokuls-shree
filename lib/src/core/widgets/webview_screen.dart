import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';

/// In-app WebView screen for displaying web content.
///
/// On web there's no registered webview_flutter implementation (and most
/// third-party sites block iframe embedding via X-Frame-Options anyway), so
/// this opens the URL in a new browser tab instead of embedding it.
class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const InAppWebViewScreen({super.key, required this.url, required this.title});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInNewTab());
    } else {
      _initWebView();
    }
  }

  Future<void> _openInNewTab() async {
    await launchUrl(Uri.parse(widget.url), webOnlyWindowName: '_blank');
    if (mounted) Navigator.of(context).pop();
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
    if (kIsWeb) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'back':
                  if (await controller.canGoBack()) {
                    controller.goBack();
                  }
                  break;
                case 'forward':
                  if (await controller.canGoForward()) {
                    controller.goForward();
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
                  backgroundColor: AppColors.textMuted,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: controller),
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
