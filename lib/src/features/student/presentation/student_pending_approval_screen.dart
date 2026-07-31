import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_session.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../auth/data/auth_service.dart';

/// Shown instead of the normal student shell while `profiles.status != 1`.
///
/// A student can sign in as soon as they register, but every data endpoint
/// (attendance, fees, marksheets, branch record, etc.) stays locked to
/// approved accounts server-side — this screen is the honest UI reflection
/// of that: identity only, everything else pending a branch/super admin
/// approval.
class StudentPendingApprovalScreen extends ConsumerStatefulWidget {
  const StudentPendingApprovalScreen({super.key});

  @override
  ConsumerState<StudentPendingApprovalScreen> createState() =>
      _StudentPendingApprovalScreenState();
}

class _StudentPendingApprovalScreenState
    extends ConsumerState<StudentPendingApprovalScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      await ref.read(supabaseAuthNotifierProvider.notifier).refreshProfile();
      final session = ref.read(sessionProvider);
      if (mounted && session != null && session.isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re approved! Loading your dashboard...'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still pending approval. Please check back later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? session = ref.watch(sessionProvider);
    final name = session?.name.isNotEmpty == true ? session!.name : 'Student';
    final email = session?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.chipPendingBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        size: 44, color: AppColors.chipPendingFg),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Registration Pending Approval',
                    textAlign: TextAlign.center,
                    style: AppTypography.headingLg.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hi $name, your account has been created but your branch admin '
                    'hasn\'t approved it yet. Attendance, fees, marksheets, and other '
                    'records will unlock automatically once you\'re approved.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.person_outline_rounded, 'Name', name),
                        const SizedBox(height: 10),
                        _infoRow(Icons.email_outlined, 'Email', email),
                        const SizedBox(height: 10),
                        _infoRow(Icons.verified_outlined, 'Status', 'Pending approval'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Check Status',
                    icon: Icons.refresh_rounded,
                    isLoading: _checking,
                    onPressed: _checkStatus,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.read(supabaseAuthNotifierProvider.notifier).signOut(),
                    child: Text(
                      'Log Out',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text('$label: ', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
