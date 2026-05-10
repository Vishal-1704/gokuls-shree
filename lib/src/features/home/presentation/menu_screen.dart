import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/widgets/webview_screen.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  void _openWebView(BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppWebViewScreen(title: title, url: url),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(supabaseAuthProvider);

    // Determine Role
    bool isAuthenticated = authState is AuthAuthenticated;
    bool isAdmin = false;
    bool isStudent = false;

    if (isAuthenticated) {
      final user = (authState as AuthAuthenticated).user;
      // Check metadata or mock role
      if (user.id.startsWith('ADMIN') ||
          user.userMetadata?['role'] == 'admin') {
        isAdmin = true;
      } else {
        isStudent = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          // Authentication Status / Login Banner
          if (!isAuthenticated)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome to Gokul Shree App",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Log in to access Student Services & Exams",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: () {
                      // Switch to Account Tab programmatically (index 2)
                      // Since we are in nested navigation, this is tricky.
                      // Simplest is to navigate to /account
                      context.go('/account');
                    },
                    child: const Text("Login Now"),
                  ),
                ],
              ),
            ),

          // ADMIN ZONE (Only for Admins)
          if (isAdmin) ...[
            _buildSectionHeader(context, 'Administration'),
            _buildMenuItem(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              subtitle: 'Manage Users & Content',
              onTap: () => context.go('/admin'),
            ),
          ],

          // STUDENT ZONE (Only for Students)
          if (isStudent || isAdmin) ...[
            // Admins can also see student stuff for testing? Or maybe keep it separate. User said "when admin shows staff related".
            // Let's hide student stuff for pure admins, unless user wants a "View As" feature.
            // For now: Stick to user request "when student logged it shows all student details".
          ],

          if (isStudent) ...[
            _buildSectionHeader(context, 'Student Zone'),
            _buildMenuItem(
              context,
              icon: Icons.dashboard,
              title: 'My Profile',
              onTap: () => context.go('/account'),
            ),
            _buildExpansionItem(
              context,
              icon: Icons.person,
              title: 'Student Services',
              children: [
                _buildSubItem(
                  context,
                  'Admit Card',
                  icon: Icons.card_membership,
                  onTap: () =>
                      _openWebView(context, 'Admit Card', WebUrls.admitCard),
                ),
                _buildSubItem(
                  context,
                  'Marksheet Verification',
                  icon: Icons.verified,
                  onTap: () => _openWebView(
                    context,
                    'Marksheet Verification',
                    WebUrls.marksheetVerification,
                  ),
                ),
                _buildSubItem(
                  context,
                  'Certificate Verification',
                  icon: Icons.workspace_premium,
                  onTap: () => context.push('/verify'),
                ),
              ],
            ),
            _buildSectionHeader(context, 'Academics'),
            _buildExpansionItem(
              context,
              icon: Icons.school,
              title: 'Courses',
              children: [
                _buildSubItem(
                  context,
                  'Diploma Courses',
                  icon: Icons.computer,
                  onTap: () => context.go('/exams'),
                ),
                _buildSubItem(
                  context,
                  'Online Exams',
                  icon: Icons.timer,
                  onTap: () => context.go('/exams'),
                ),
              ],
            ),
            _buildMenuItem(
              context,
              icon: Icons.assessment,
              title: 'Results',
              subtitle: 'Check your exam results',
              onTap: () =>
                  _openWebView(context, 'Result Verification', WebUrls.results),
            ),
            _buildMenuItem(
              context,
              icon: Icons.download,
              title: 'Downloads',
              subtitle: 'Forms, syllabi & more',
              onTap: () =>
                  _openWebView(context, 'Downloads', WebUrls.downloads),
            ),
          ],

          // PUBLIC ZONE (Always Visible)
          _buildSectionHeader(context, 'Institution'),
          if (!isAuthenticated) // Show Registration only for Guests
            _buildMenuItem(
              context,
              icon: Icons.app_registration,
              title: 'Student Registration',
              subtitle: 'New Admission',
              onTap: () => _openWebView(
                context,
                'Student Registration',
                WebUrls.studentRegistration,
              ),
            ),

          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'About Us',
            subtitle: 'Know more about us',
            onTap: () => _openWebView(context, 'About Us', WebUrls.aboutUs),
          ),
          _buildMenuItem(
            context,
            icon: Icons.business,
            title: 'Franchise / Apply',
            subtitle: 'Start your own center',
            onTap: () => _openWebView(context, 'Franchise', WebUrls.franchise),
          ),
          _buildMenuItem(
            context,
            icon: Icons.place_outlined,
            title: 'Find Centres',
            subtitle: 'Search by district or centre code',
            onTap: () => context.push('/centre-finder'),
          ),

          _buildSectionHeader(context, 'Support'),
          _buildMenuItem(
            context,
            icon: Icons.contact_phone,
            title: 'Contact Us',
            subtitle: 'Get in touch',
            onTap: () => context.push('/contact'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.public,
            title: 'Visit Website',
            subtitle: 'gokulshreeschool.com',
            onTap: () =>
                _openWebView(context, 'Gokul Shree School', WebUrls.home),
          ),

          const SizedBox(height: 24),

          // Social Media
          _buildSectionHeader(context, 'Follow Us'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  onTap: () =>
                      _launchUrl('https://facebook.com/gokulshreeschool'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.play_circle_fill,
                  color: const Color(0xFFFF0000),
                  onTap: () =>
                      _launchUrl('https://youtube.com/@gokulshreeschool'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  color: const Color(0xFFE4405F),
                  onTap: () =>
                      _launchUrl('https://instagram.com/gokulshreeschool'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Gokulshree School Of Management And Technology Pvt Ltd',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.primaryColor.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildExpansionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: children,
    );
  }

  Widget _buildSubItem(
    BuildContext context,
    String title, {
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: icon != null
          ? Icon(icon, size: 18, color: Colors.grey.shade600)
          : null,
      title: Text(
        title,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
