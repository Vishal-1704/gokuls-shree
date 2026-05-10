import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';
import 'package:gokul_shree_app/src/core/widgets/webview_screen.dart';

const Color _pageBg = Color(0xFF020B1D);
const Color _surfaceCard = Color(0xFF0A1E3D);
const Color _surfaceCardAlt = Color(0xFF0D2448);
const Color _textPrimary = Color(0xFFF4F7FF);
const Color _textSecondary = Color(0xFFB7C5E2);
const Color _highlight = Color(0xFFF3DB73);

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: _selectedIndex == 0 ? const _HomeTab() : const _AcademicsTab(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF08172F),
        indicatorColor: _highlight,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 78,
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: _textSecondary),
            selectedIcon: const Icon(Icons.home, color: Color(0xFF1B2130)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined, color: _textSecondary),
            selectedIcon: const Icon(Icons.school, color: Color(0xFF1B2130)),
            label: 'Academics',
          ),
        ],
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontSize: 12,
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            color: _textSecondary,
            fontSize: 12,
          );
        }),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
  static const double _brandLogoSize = 92;

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://www.gokulshreeschool.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Hero Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B2753), Color(0xFF061834)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: _brandLogoSize,
                  height: _brandLogoSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Image.asset(
                        'assets/images/school_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Gokulshree School of\nManagement & Technology",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Official Student App",
                    style: TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Features Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Why Choose Us?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: const [
                    _FeatureCard(
                      icon: Icons.computer,
                      title: "Advanced Computer Labs",
                      color: Colors.blue,
                    ),
                    _FeatureCard(
                      icon: Icons.library_books,
                      title: "Digital Library",
                      color: Colors.green,
                    ),
                    _FeatureCard(
                      icon: Icons.wifi,
                      title: "WiFi Campus",
                      color: Colors.orange,
                    ),
                    _FeatureCard(
                      icon: Icons.people,
                      title: "Expert Faculty",
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Testimonials Section
          Container(
            color: const Color(0xFF05142B),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Student Testimonials",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      _TestimonialCard(
                        name: "Rahul Kumar",
                        course: "CCC Student",
                        text:
                            "Best institute for computer courses. The practical labs are very well equipped.",
                      ),
                      _TestimonialCard(
                        name: "Priya Singh",
                        course: "O Level",
                        text:
                            "Teachers are very supportive. I passed my O Level exam with S grade thanks to them.",
                      ),
                      _TestimonialCard(
                        name: "Amit Patel",
                        course: "ADCA",
                        text:
                            "Great learning environment. The digital library is very useful for extra studies.",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Verification & Trust
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _highlight.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(12),
                color: _surfaceCard,
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: _highlight, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "100% Verified Records",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "All certificates and marksheets can be verified online.",
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Login CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _highlight,
                  foregroundColor: const Color(0xFF1B2130),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "STUDENT LOGIN",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _launchWebsite,
              child: const Text(
                "Visit Official Website",
                style: TextStyle(
                  color: _textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AcademicsTab extends StatelessWidget {
  const _AcademicsTab();

  final List<Map<String, dynamic>> _programs = const [
    {
      'title': 'CCC',
      'fullName': 'Course on Computer Concepts',
      'duration': '3 Months',
      'color': Colors.blue,
      'icon': Icons.computer,
      'description':
          'Certificate course designed to impart basic level computer appreciation for the common man. Covers MS Office, Internet, and Digital Finance.',
    },
    {
      'title': 'O Level',
      'fullName': 'DOEACC \'O\' Level',
      'duration': '1 Year',
      'color': Colors.orange,
      'icon': Icons.school,
      'description':
          'Foundation level course in Computer Applications. Equivalent to a Diploma in CS. Covers HTML, C Language, Python, and IoT.',
    },
    {
      'title': 'ADCA',
      'fullName': 'Adv. Diploma in Computer App.',
      'duration': '1 Year',
      'color': Colors.purple,
      'icon': Icons.code,
      'description':
          'Advanced diploma covering Accountancy (Tally), DTP, Programming, and Web Designing. Best for job seekers.',
    },
    {
      'title': 'DCA',
      'fullName': 'Diploma in Computer App.',
      'duration': '6 Months',
      'color': Colors.teal,
      'icon': Icons.laptop,
      'description':
          'Short-term diploma for basic computer applications, office automation, and internet handling.',
    },
    {
      'title': 'Web Div',
      'fullName': 'Web Development',
      'duration': '6 Months',
      'color': Colors.pink,
      'icon': Icons.web,
      'description':
          'Learn to build modern websites using HTML5, CSS3, JavaScript, React, and Backend technologies.',
    },
    {
      'title': 'Tally',
      'fullName': 'Tally Prime & GST',
      'duration': '3 Months',
      'color': Colors.green,
      'icon': Icons.calculate,
      'description':
          'Complete accounting course covering Inventory, Payroll, GST billing, and Taxation.',
    },
  ];

  void _showProgramDetails(BuildContext context, Map<String, dynamic> program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (program['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    program['icon'] as IconData,
                    size: 32,
                    color: program['color'] as Color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program['fullName'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        program['duration'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "About Course",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              program['description'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // Close sheet
                  context.push('/login'); // Redirect to login/signup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Enroll Now / Login"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openExamPortal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InAppWebViewScreen(
          title: 'Online Exam Portal',
          url: WebUrls.examPortal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Academics & Features',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Programs
            const Text(
              "Programs Offered",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap on a course to view details",
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _programs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final program = _programs[index];
                return _ProgramCard(
                  program: program,
                  onTap: () => _showProgramDetails(context, program),
                );
              },
            ),

            const SizedBox(height: 32),

            // Student Features
            const Text(
              "Student Portal Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Login to access the following services:",
              style: TextStyle(color: _textSecondary),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _FeatureCard(
                  icon: Icons.badge,
                  title: "Admit Card",
                  color: Colors.blue,
                ),
                _FeatureCard(
                  icon: Icons.assignment_turned_in,
                  title: "Online Results",
                  color: Colors.green,
                ),
                _FeatureCard(
                  icon: Icons.card_membership,
                  title: "Certificates",
                  color: Colors.orange,
                ),
                _FeatureCard(
                  icon: Icons.download,
                  title: "Study Material",
                  color: Colors.purple,
                ),
                _FeatureCard(
                  icon: Icons.person,
                  title: "Profile Mgmt",
                  color: Colors.teal,
                ),
                _FeatureCard(
                  icon: Icons.payments,
                  title: "Fee Status",
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _highlight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: _highlight,
                ),
                child: const Text(
                  "Access Student Portal",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openExamPortal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _highlight,
                  foregroundColor: const Color(0xFF1B2130),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text(
                  "Open Exam Portal",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final VoidCallback onTap;

  const _ProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = program['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(program['icon'] as IconData, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program['fullName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          program['duration'] as String,
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.98),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String course;
  final String text;

  const _TestimonialCard({
    required this.name,
    required this.course,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCardAlt,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(name[0], style: const TextStyle(color: _highlight)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    course,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$text"',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _textSecondary,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}
