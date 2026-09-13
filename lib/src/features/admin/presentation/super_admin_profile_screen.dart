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
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';

/// Super Admin's Profile tab. Unlike AdminProfileScreen (which is bound to
/// ONE branch via getMyBranch()), Super Admin isn't tied to a single branch,
/// so this shows the admin's own identity plus an org-wide summary instead.
class SuperAdminProfileScreen extends ConsumerStatefulWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  ConsumerState<SuperAdminProfileScreen> createState() => _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends ConsumerState<SuperAdminProfileScreen> {
  String? _localAvatarUrl;
  bool _isUploadingPhoto = false;
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final supabase = ref.read(supabaseServiceProvider);
    final currentUser = supabase.currentUser;
    if (currentUser == null) return {};
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('auth_uid', currentUser.id)
          .maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.goldCta.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
                  decoration: BoxDecoration(color: AppColors.primaryIndigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, maxWidth: 400, maxHeight: 400, imageQuality: 75);
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

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': uploadedUrl, 'photo_url': uploadedUrl}),
      );

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          await Supabase.instance.client.from('profiles').update({'photo_url': uploadedUrl}).eq('auth_uid', currentUser.id);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _localAvatarUrl = uploadedUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Text('Are you sure you want to sign out of your Super Admin account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(supabaseServiceProvider).signOut();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final studentsAsync = ref.watch(adminStudentsProvider);
    final duesAsync = ref.watch(adminDuesReportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Super Admin Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: () {
              setState(() => _profileFuture = _loadProfile());
              ref.invalidate(branchesProvider);
              ref.invalidate(adminStudentsProvider);
              ref.invalidate(adminDuesReportProvider);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _localAvatarUrl == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.goldCta));
          }

          final personal = snapshot.data ?? {};
          final currentUser = ref.read(supabaseServiceProvider).currentUser;

          final adminName = personal['full_name'] ?? personal['name'] ?? currentUser?.userMetadata?['name'] ?? 'Super Administrator';
          final email = currentUser?.email ?? personal['email'] ?? 'Not provided';
          final contact = personal['contact'] ?? personal['phone'] ?? currentUser?.userMetadata?['phone'] ?? 'Not provided';
          final photoUrl = _localAvatarUrl ??
              personal['photo_url'] ??
              personal['avatar_url'] ??
              currentUser?.userMetadata?['avatar_url'] ??
              currentUser?.userMetadata?['photo_url'];

          return RefreshIndicator(
            color: AppColors.goldCta,
            onRefresh: () async {
              setState(() => _profileFuture = _loadProfile());
              ref.invalidate(branchesProvider);
              ref.invalidate(adminStudentsProvider);
              ref.invalidate(adminDuesReportProvider);
              await _profileFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(adminName: adminName, photoUrl: photoUrl),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.goldCta,
                    iconBgColor: AppColors.goldCta.withValues(alpha: 0.1),
                    children: [
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
                        value: contact,
                        action: contact != 'Not provided'
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.goldCta),
                                tooltip: 'Copy Phone',
                                onPressed: () => _copyToClipboard(contact, 'Phone number'),
                              )
                            : null,
                      ),

                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    title: 'Organization Overview',
                    icon: Icons.corporate_fare_rounded,
                    iconColor: AppColors.primaryIndigo,
                    iconBgColor: AppColors.primaryIndigo.withValues(alpha: 0.1),
                    children: [
                      _buildInfoTile(
                        icon: Icons.account_balance_rounded,
                        label: 'Total Branches',
                        value: branchesAsync.maybeWhen(data: (b) => '${b.length}', orElse: () => '…'),
                      ),
                      _buildInfoTile(
                        icon: Icons.school_rounded,
                        label: 'Total Students (all branches)',
                        value: studentsAsync.maybeWhen(data: (s) => '${s.length}', orElse: () => '…'),
                      ),
                      _buildInfoTile(
                        icon: Icons.request_quote_rounded,
                        label: 'Students with Pending Dues',
                        value: duesAsync.maybeWhen(data: (d) => '${d.length}', orElse: () => '…'),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildHeroHeader({required String adminName, required String? photoUrl}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Colors.purpleAccent, AppColors.primaryIndigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? resolveAvatarProvider(photoUrl) : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(_getInitials(adminName), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.purple))
                        : null,
                  ),
                ),
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
                          color: Colors.purpleAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(adminName, style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, size: 14, color: Colors.purpleAccent),
              SizedBox(width: 5),
              Text('SUPER ADMIN', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
            ]),
          ),
        ],
      ),
    );
  }

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

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
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFF8FAFC)))),
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
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                valueWidget ??
                    (isNotAvailable
                        ? Text('Not configured', style: TextStyle(fontSize: 13.5, color: Colors.grey.shade400, fontStyle: FontStyle.italic))
                        : Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'SA';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
