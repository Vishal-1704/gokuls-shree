import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/features/student/data/student_repository.dart';
import 'package:gokul_shree_app/src/features/teacher/presentation/widgets/teacher_employment_details.dart';
import 'package:gokul_shree_app/src/features/teacher/presentation/employee_salary_screen.dart';
import 'package:gokul_shree_app/src/features/teacher/data/attendance_repository.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  // Overrides whatever's in profiles.photo_url the instant an upload
  // succeeds, same as admin_profile_screen.dart's _localAvatarUrl — avoids
  // waiting on supabaseAuthProvider to refetch before the new photo shows.
  String? _localAvatarUrl;
  bool _isUploadingPhoto = false;

  Future<void> _showPhotoSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inkNavy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  style: AppTypography.headingSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.goldCta),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.goldCta),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );
      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await pickedFile.readAsBytes();
      String uploadedUrl;
      try {
        uploadedUrl = await ref.read(adminRepositoryProvider).uploadProfilePhoto(pickedFile.name, bytes);
      } catch (storageErr) {
        debugPrint('⚠️ Storage upload failed ($storageErr). Storing inline image data.');
        uploadedUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        await supabase.from('profiles').update({'photo_url': uploadedUrl}).eq('auth_uid', currentUser.id);
      }

      if (mounted) {
        setState(() {
          _localAvatarUrl = uploadedUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  String? _profilePhotoUrl(SupabaseAuthState authState) {
    if (authState is AuthAuthenticated) {
      return authState.profile?['photo_url']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(supabaseAuthProvider);
    final userRole = ref.watch(userRoleProvider) ?? 'student';
    final isStudent = userRole == 'student';
    // studentData is the raw profiles row (full_name/role/branch_id/...),
    // not the students table — it has no course/class_section/reg_no.
    // Those only exist on students, fetched separately here.
    final studentAsync = isStudent ? ref.watch(studentProfileProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(
            context,
            ref,
            authState,
            userRole,
            ref.watch(sessionProvider)?.name,
            _localAvatarUrl ?? _profilePhotoUrl(authState),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authState is AuthAuthenticated) ...[
                    // Students get _buildStudentInfoTable's own "Personal &
                    // Course Information" header instead — this generic
                    // "Profile Information" header only shown above it too
                    // was a redundant duplicate saying the same thing twice
                    // with no other content between them.
                    if (!(isStudent && studentAsync != null)) ...[
                      _buildSectionHeader('Profile Information'),
                      const SizedBox(height: 16),
                    ],
                    if (isStudent && studentAsync != null)
                      studentAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.goldCta,
                            ),
                          ),
                        ),
                        error: (e, _) => Text(
                          'Error loading student info: $e',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        data: (student) => _buildStudentInfoTable(student),
                      )
                    else
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: authState.user.email ?? 'N/A',
                      ),
                    const SizedBox(height: 12),
                    if (isStudent) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Fees'),
                      const SizedBox(height: 16),
                      _buildMenuTile(
                        icon: Icons.receipt_long_rounded,
                        title: 'Fee Status',
                        subtitle: 'View installments, dues & receipts',
                        onTap: () => context.push('/fee-status'),
                      ),
                    ],
                  ],

                  const SizedBox(height: 10),

                  if (userRole == 'teacher') ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Employment Details'),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final empAsync = ref.watch(
                          teacherEmployeeProfileProvider,
                        );
                        return empAsync.when(
                          data: (emp) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.inkNavy800,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.divider.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.inkNavy700,
                                    child: Icon(
                                      Icons.work_outline_rounded,
                                      color: AppColors.goldCta,
                                    ),
                                  ),
                                  title: const Text(
                                    'View Employment Details',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Salary, attendance, and department info',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.textMuted,
                                    size: 16,
                                  ),
                                  onTap: () => context.push(
                                    '/teacher/employment-details',
                                    extra: emp,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                icon: Icons.account_balance_rounded,
                                label: 'Branch',
                                value: emp?['branches']?['name']?.toString() ?? 'N/A',
                              ),
                              const SizedBox(height: 12),
                              _buildMenuTile(
                                icon: Icons.receipt_long_rounded,
                                title: 'My Salary & Payslips',
                                subtitle: 'View CTC and download payslips',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EmployeeSalaryScreen(emp: emp),
                                  ),
                                ),
                              ),
                              // const SizedBox(height: 12),
                              // _buildMenuTile(
                              //   icon: Icons.workspace_premium_rounded,
                              //   title: 'Request Experience Certificate',
                              //   subtitle: 'Submit a request for admin approval',
                              //   onTap: () => requestExperienceCertificate(context, emp),
                              // ),
                            ],
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.goldCta,
                            ),
                          ),
                          error: (e, _) => Text(
                            'Error loading profile: ',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 16),

                  ],
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    SupabaseAuthState state,
    String role,
    String? profileName,
    String? photoUrl,
  ) {
    String name = 'User';
    String sub = role.replaceAll('_', ' ').toUpperCase();

    if (state is AuthAuthenticated) {
      // profiles.full_name is the real source of truth — auth metadata is
      // only ever set at signup time and is empty for legacy-claimed
      // accounts, which silently fell back to the email's local part.
      final fallback =
          state.user.userMetadata?['name'] ??
          state.user.email?.split('@')[0] ??
          'User';
      name = (profileName != null && profileName.isNotEmpty)
          ? profileName
          : fallback;
    }

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.inkNavy800,
      actions: [
        if (state is AuthAuthenticated && role == 'student')
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: AppColors.textPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.inkNavy800,
                  title: const Text(
                    'Digital Profile QR',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: 'STU-${state.user.id}',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.goldCta),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.inkNavy700, AppColors.inkNavy900],
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              right: -50,
              top: -20,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: AppColors.goldCta.withOpacity(0.03),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _showPhotoSourceSheet,
                  child: Hero(
                    tag: 'profile-pic',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldCta, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.inkNavy700,
                            backgroundImage: resolveAvatarProvider(photoUrl),
                            child: (photoUrl == null || resolveAvatarProvider(photoUrl) == null)
                                ? Text(
                                    name[0].toUpperCase(),
                                    style: AppTypography.displayLg.copyWith(
                                      color: AppColors.goldCta,
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploadingPhoto)
                            const Positioned.fill(
                              child: CircleAvatar(
                                backgroundColor: Colors.black45,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldCta),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.goldCta,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.inkNavy900),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    name,
                    style: AppTypography.headingMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldCta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.goldCta,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headingSm.copyWith(
        color: AppColors.goldCta,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full personal & course info table — matches the legacy site's student
  /// profile view. All fields come from the real students row (via
  /// student_repository.dart's mapper), no invented data.
  Widget _buildStudentInfoTable(Map<String, dynamic> student) {
    final feeSummary = student['fee_summary'] as Map<String, dynamic>?;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.inkNavy800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Personal & Course Information',
                  style: AppTypography.headingSm.copyWith(
                    color: AppColors.goldCta,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildInfoTableRow('Name', student['name']?.toString() ?? 'N/A'),
              _buildInfoTableRow(
                'Father',
                student['father_name']?.toString() ?? 'N/A',
              ),
              _buildInfoTableRow(
                'Date of Birth',
                student['date_of_birth']?.toString() ?? 'N/A',
              ),
              _buildInfoTableRow(
                'Mobile',
                student['phone']?.toString() ?? 'N/A',
              ),
              _buildInfoTableRow(
                'Gender',
                student['gender']?.toString() ?? 'N/A',
              ),
              _buildInfoTableRow(
                'Address',
                student['address']?.toString() ?? 'N/A',
              ),
              //_buildInfoTableRow('Email', student['email']?.toString() ?? 'N/A'),
              // _buildInfoTableRow('Program Name', student['program']?.toString() ?? 'N/A'),
              _buildInfoTableRow(
                'Course Name',
                student['class_section']?.toString() ?? 'N/A',
              ),
              _buildInfoTableRow(
                'Reg. Number',
                student['reg_no']?.toString() ?? 'Pending',
                isLast: true,
              ),
            ],
          ),
        ),
        if (feeSummary != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inkNavy800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.3)),
            ),
            child: Text(
              'Course Fee: ₹${feeSummary['course_fee'] ?? 0}   Paid: ₹${feeSummary['paid_total'] ?? 0}   Due: ₹${feeSummary['due_amount'] ?? 0}',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTableRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkNavy800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inkNavy700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.inkNavy800,
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: const Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(supabaseAuthNotifierProvider).signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: Text(
          'Sign Out of Account',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.danger.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
