import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import 'package:gokul_shree_app/src/features/documents/presentation/certificate_viewer_screen.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AdminProfileBody();
  }
}

class _AdminProfileBody extends ConsumerStatefulWidget {
  const _AdminProfileBody();

  @override
  ConsumerState<_AdminProfileBody> createState() => _AdminProfileBodyState();
}

class _AdminProfileBodyState extends ConsumerState<_AdminProfileBody> {
  String? _localAvatarUrl;
  bool _isUploadingPhoto = false;
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _profileFuture = _loadProfileAndBranch();
  }

  Future<Map<String, dynamic>> _loadProfileAndBranch() async {
    final supabase = ref.read(supabaseServiceProvider);
    final currentUser = supabase.currentUser;

    Map<String, dynamic> personalProfile = {};
    if (currentUser != null) {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('auth_uid', currentUser.id)
            .maybeSingle();
        if (res != null) {
          personalProfile = Map<String, dynamic>.from(res);
        }
      } catch (_) {}
    }

    Map<String, dynamic> branchData = {};
    try {
      final b = await ref.read(adminRepositoryProvider).getMyBranch();
      if (b != null) {
        branchData = b;
      }
    } catch (_) {}

    return {
      'personal': personalProfile,
      'branch': branchData,
      'currentUser': currentUser,
    };
  }

  Future<void> _showPhotoSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                      color: Colors.grey.shade300,
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
                const SizedBox(height: 6),
                Text(
                  'Upload a clear personal photo for your Branch Admin profile',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldCta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.goldCta),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryIndigo),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
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
        final repo = ref.read(adminRepositoryProvider);
        uploadedUrl = await repo.uploadProfilePhoto(pickedFile.name, bytes);
      } catch (storageErr) {
        debugPrint('⚠️ Storage upload failed ($storageErr). Storing optimized inline image data.');
        final base64Str = base64Encode(bytes);
        uploadedUrl = 'data:image/jpeg;base64,$base64Str';
      }

      // 1. Update Auth metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'avatar_url': uploadedUrl,
          'photo_url': uploadedUrl,
        }),
      );

      // 2. Update Profiles table if exists
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          await Supabase.instance.client
              .from('profiles')
              .update({'photo_url': uploadedUrl})
              .eq('auth_uid', currentUser.id);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _localAvatarUrl = uploadedUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to sign out of your Admin account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(supabaseServiceProvider).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _localAvatarUrl == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldCta),
            );
          }

          final data = snapshot.data ?? {};
          final branch = (data['branch'] as Map<String, dynamic>?) ?? {};
          final personal = (data['personal'] as Map<String, dynamic>?) ?? {};
          final currentUser = ref.read(supabaseServiceProvider).currentUser;

          // Personal Details
          final adminName = personal['full_name'] ??
              personal['name'] ??
              currentUser?.userMetadata?['name'] ??
              'Branch Administrator';
          final email = currentUser?.email ?? personal['email'] ?? 'Not provided';
          final personalContact = personal['contact'] ??
              personal['phone'] ??
              currentUser?.userMetadata?['phone'] ??
              (branch['contact'] ?? 'Not provided');
          final role = personal['role'] != null
              ? personal['role'].toString().replaceAll('_', ' ').toUpperCase()
              : 'BRANCH ADMIN';

          // Photo URL
          final photoUrl = _localAvatarUrl ??
              personal['photo_url'] ??
              personal['avatar_url'] ??
              currentUser?.userMetadata?['avatar_url'] ??
              currentUser?.userMetadata?['photo_url'];

          // Branch Details
          final code = branch['code'] ?? 'N/A';
          final name = branch['name'] ?? 'N/A';
          final address = branch['address'] ?? 'N/A';
          final director = branch['owner_name'] ?? 'N/A';
          final branchContact = branch['contact'] ?? 'N/A';

          return RefreshIndicator(
            color: AppColors.goldCta,
            onRefresh: () async {
              setState(() {
                _loadData();
              });
              await _profileFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HERO PROFILE CARD WITH AVATAR
                  _buildHeroHeader(
                    adminName: adminName,
                    role: role,
                    photoUrl: photoUrl,
                    centerCode: code,
                  ),
                  const SizedBox(height: 16),

                  // 2. QUICK STATS / INFO STRIP
                  _buildQuickStatsStrip(
                    centerCode: code,
                    centerName: name,
                  ),
                  const SizedBox(height: 20),

                  // 3. BASIC PERSONAL DETAILS CARD
                  _buildCardSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.goldCta,
                    iconBgColor: AppColors.goldCta.withValues(alpha: 0.1),
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Admin Name',
                        value: adminName,
                      ),
                      _buildInfoTile(
                        icon: Icons.alternate_email_rounded,
                        label: 'Email Address',
                        value: email,
                        action: email != 'Not provided'
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.goldCta),
                                tooltip: 'Copy Email',
                                onPressed: () => _copyToClipboard(email, 'Email address'),
                              )
                            : null,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Contact / Mobile',
                        value: personalContact,
                        action: personalContact != 'Not provided'
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.goldCta),
                                tooltip: 'Copy Phone',
                                onPressed: () => _copyToClipboard(personalContact, 'Phone number'),
                              )
                            : null,
                      ),
                      _buildInfoTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Role / Designation',
                        value: role,
                        isLast: true,
                        valueWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldCta.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: AppColors.goldDeep,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. BRANCH / CENTRE DETAILS CARD
                  _buildCardSection(
                    title: 'Branch / Centre Details',
                    icon: Icons.apartment_rounded,
                    iconColor: AppColors.primaryIndigo,
                    iconBgColor: AppColors.primaryIndigo.withValues(alpha: 0.1),
                    children: [
                      _buildInfoTile(
                        icon: Icons.tag_rounded,
                        label: 'Centre Code',
                        value: code,
                      ),
                      _buildInfoTile(
                        icon: Icons.business_outlined,
                        label: 'Centre Name',
                        value: name,
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Centre Address',
                        value: address,
                      ),
                      _buildInfoTile(
                        icon: Icons.person_pin_circle_outlined,
                        label: "Director's Name",
                        value: director,
                      ),
                      _buildInfoTile(
                        icon: Icons.support_agent_rounded,
                        label: 'Centre Contact',
                        value: branchContact,
                        isLast: true,
                        action: (branchContact != 'N/A' && branchContact != 'Not provided')
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.goldCta),
                                tooltip: 'Copy Contact',
                                onPressed: () => _copyToClipboard(branchContact, 'Centre Contact'),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4b. QUICK ACCESS — MARK ATTENDANCE
                  _buildAttendanceTile(context),
                  const SizedBox(height: 20),

                  // 5. OFFICIAL CERTIFICATE CARD
                  _buildCertificateCard(
                    code: code,
                    name: name,
                    director: director,
                    adminName: adminName,
                  ),
                  const SizedBox(height: 24),

                  // 6. LOGOUT BUTTON
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── HERO BANNER & AVATAR ──────────────────────────────────────────────
  Widget _buildHeroHeader({
    required String adminName,
    required String role,
    required String? photoUrl,
    required String centerCode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Circular Avatar with edit overlay
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.goldCta, AppColors.primaryIndigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldCta.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? _getAvatarProvider(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            _getInitials(adminName),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDeep,
                            ),
                          )
                        : null,
                  ),
                ),
                // Camera action badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldCta,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            adminName,
            style: AppTypography.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Role pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldCta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.goldCta.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: AppColors.goldCta),
                const SizedBox(width: 5),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK STATS STRIP ────────────────────────────────────────────────
  Widget _buildQuickStatsStrip({
    required String centerCode,
    required String centerName,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Centre Code',
            value: centerCode,
            icon: Icons.domain_rounded,
            iconColor: AppColors.goldCta,
          ),
        ),
        const SizedBox(width: 12),
        // Expanded(
        //   child: _buildStatItem(
        //     label: 'Status',
        //     value: 'Active',
        //     icon: Icons.check_circle_rounded,
        //     iconColor: AppColors.success,
        //     isStatus: true,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isStatus ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD CONTAINER ───────────────────────────────────────────────────
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  // ── INFO TILE ────────────────────────────────────────────────────────
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? action,
    Widget? valueWidget,
    bool isLast = false,
  }) {
    final bool isNotAvailable = value == 'N/A' || value == 'Not provided';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFF8FAFC),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                valueWidget ??
                    (isNotAvailable
                        ? Text(
                            'Not configured',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ── QUICK ACCESS — MARK ATTENDANCE ───────────────────────────────────
  Widget _buildAttendanceTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/admin/attendance'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.how_to_reg_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Record student attendance for your branch',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CERTIFICATE CARD ─────────────────────────────────────────────────
  Widget _buildCertificateCard({
    required String code,
    required String name,
    required String director,
    required String adminName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => CertificateViewerScreen(
                  certificate: {
                    'students': {
                      'name': (director != 'N/A' && director.isNotEmpty)
                          ? director
                          : ((adminName.isNotEmpty && adminName != 'Branch Administrator')
                              ? adminName
                              : 'STUDY CENTRE DIRECTOR')
                    },
                    'courses': {
                      'name': (name != 'N/A' && name.isNotEmpty)
                          ? 'AUTHORISED STUDY CENTRE ($name)'
                          : 'AUTHORISED STUDY CENTRE'
                    },
                    'session': '2024-2027',
                    'grade': 'A+',
                    'certificate_no': 'AUTH-${(code != 'N/A' && code.isNotEmpty) ? code : 'GOK-001'}',
                    'issue_date': DateTime.now().toString().split(' ')[0],
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.goldCta.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.goldCta,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorisation Certificate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Accredited Study Centre (2024–2027)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String url) {
    return resolveAvatarProvider(url);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'BA';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
