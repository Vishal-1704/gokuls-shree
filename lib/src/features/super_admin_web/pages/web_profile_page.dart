import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/utils/image_utils.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';
import '../widgets/web_ui.dart';

final _ownProfileProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(adminRepositoryProvider).getOwnProfile(),
);

class WebProfilePage extends ConsumerStatefulWidget {
  const WebProfilePage({super.key});

  @override
  ConsumerState<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends ConsumerState<WebProfilePage> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 75);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(adminRepositoryProvider).updateOwnAvatar(file.name, await file.readAsBytes());
      ref.invalidate(_ownProfileProvider);
      if (mounted) showToast(context, 'Profile photo updated.');
    } catch (e) {
      if (mounted) showToast(context, 'Could not update photo: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to use the admin console.',
      confirmLabel: 'Sign out',
      danger: true,
    );
    if (!ok) return;
    await ref.read(supabaseServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    showToast(context, '$label copied.');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(_ownProfileProvider);
    final user = ref.read(supabaseServiceProvider).currentUser;
    final branches = ref.watch(branchesProvider).whenOrNull(data: (v) => v.length);
    final students = ref.watch(adminStudentsProvider).whenOrNull(data: (v) => v.where((s) => s['status'] == 1).length);
    final dues = ref.watch(adminDuesReportProvider).whenOrNull(data: (v) => v.length);

    return WebPage(
      title: 'My profile',
      subtitle: 'Your super admin account',
      maxWidth: 1100,
      child: profile.when(
        loading: () => const SizedBox(height: 300, child: webLoading),
        error: (e, _) => SizedBox(height: 300, child: WebError(e, onRetry: () => ref.invalidate(_ownProfileProvider))),
        data: (p) {
          final name = str(p['full_name'] ?? p['name'] ?? user?.userMetadata?['name'], 'Super Administrator');
          final email = str(user?.email ?? p['email'], '');
          final phone = str(p['contact'] ?? p['phone'] ?? user?.userMetadata?['phone'], '');
          final photo = p['photo_url'] ?? p['avatar_url'] ?? user?.userMetadata?['avatar_url'];

          final identity = WebPanel(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Stack(
                  children: [
                    InitialsAvatar(name, size: 96, image: resolveAvatarProvider(photo)),
                    if (_uploading)
                      const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(name, style: AppTypography.headingLg, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const StatusChip('Super Admin', AppColors.primaryIndigo),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: webSecondaryButton(),
                  onPressed: _uploading ? null : _changePhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Change photo'),
                ),
                const Divider(height: 32, color: AppColors.divider),
                _ContactRow(icon: Icons.alternate_email_rounded, label: 'Email', value: email, onCopy: () => _copy(email, 'Email')),
                _ContactRow(icon: Icons.phone_outlined, label: 'Phone', value: phone, onCopy: () => _copy(phone, 'Phone number')),
              ],
            ),
          );

          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebPanel(
                title: 'Organisation overview',
                child: Row(
                  children: [
                    Expanded(child: StatTile(label: 'BRANCHES', value: branches == null ? '…' : '$branches', icon: Icons.account_balance_outlined, color: AppColors.primaryIndigo)),
                    const SizedBox(width: 12),
                    Expanded(child: StatTile(label: 'ACTIVE STUDENTS', value: students == null ? '…' : '$students', icon: Icons.school_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: StatTile(label: 'WITH DUES', value: dues == null ? '…' : '$dues', icon: Icons.request_quote_outlined, color: AppColors.danger)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              WebPanel(
                title: 'Account & security',
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.lock_reset_outlined,
                      title: 'Reset another user\'s password',
                      subtitle: 'Students, teachers or branch admins. Every reset is audit-logged.',
                      action: OutlinedButton(style: webSecondaryButton(), onPressed: () => context.go('/super-admin/reset-password'), child: const Text('Open')),
                    ),
                    const Divider(height: 24, color: AppColors.divider),
                    _SettingRow(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      subtitle: 'End this session on this browser.',
                      action: OutlinedButton(style: webSecondaryButton(AppColors.danger), onPressed: _signOut, child: const Text('Sign out')),
                    ),
                  ],
                ),
              ),
            ],
          );

          return LayoutBuilder(
            builder: (context, c) => c.maxWidth >= 860
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SizedBox(width: 340, child: identity), const SizedBox(width: 20), Expanded(child: right)],
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [identity, const SizedBox(height: 20), right]),
          );
        },
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label, required this.value, required this.onCopy});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: CellText(value.isEmpty ? 'Not provided' : value, secondary: label)),
          if (value.isNotEmpty)
            IconButton(tooltip: 'Copy $label', onPressed: onCopy, icon: const Icon(Icons.copy_rounded, size: 16)),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle, required this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(child: CellText(title, secondary: subtitle)),
        const SizedBox(width: 12),
        action,
      ],
    );
  }
}
