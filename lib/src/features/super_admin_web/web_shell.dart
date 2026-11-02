import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'web_providers.dart';
import 'widgets/web_ui.dart';

class WebNavItem {
  const WebNavItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class WebNavSection {
  const WebNavSection(this.title, this.items);
  final String title;
  final List<WebNavItem> items;
}

const webNavSections = <WebNavSection>[
  WebNavSection('Overview', [
    WebNavItem('Dashboard', Icons.space_dashboard_outlined, '/super-admin'),
    WebNavItem('Approvals', Icons.fact_check_outlined, '/super-admin/approvals'),
    WebNavItem('Reports', Icons.insights_outlined, '/super-admin/reports'),
  ]),
  WebNavSection('People', [
    WebNavItem('Students', Icons.school_outlined, '/super-admin/students'),
    WebNavItem('Add student', Icons.person_add_alt_outlined, '/super-admin/add-student'),
    WebNavItem('Departments', Icons.badge_outlined, '/super-admin/manage-departments'),
  ]),
  WebNavSection('Branches', [
    WebNavItem('Branches', Icons.account_balance_outlined, '/super-admin/branches'),
    WebNavItem('Register branch admin', Icons.how_to_reg_outlined, '/super-admin/branch-registration'),
  ]),
  WebNavSection('Academics', [
    WebNavItem('Courses & content', Icons.menu_book_outlined, '/super-admin/content'),
    WebNavItem('Exam papers', Icons.quiz_outlined, '/super-admin/paper-manager'),
    WebNavItem('Exam scheduler', Icons.event_note_outlined, '/super-admin/exam-scheduler'),
    WebNavItem('Results entry', Icons.edit_note_outlined, '/super-admin/results-entry'),
    WebNavItem('Published results', Icons.fact_check_outlined, '/super-admin/schedule-results'),
    WebNavItem('Marksheets', Icons.workspace_premium_outlined, '/admin/marksheet-generator'),
    WebNavItem('Study material', Icons.library_books_outlined, '/super-admin/study-material'),
    WebNavItem('Attendance session', Icons.qr_code_2_outlined, '/super-admin/attendance'),
  ]),
  WebNavSection('Finance', [
    WebNavItem('Fee collection', Icons.payments_outlined, '/admin/fee-collection'),
    WebNavItem('Dues report', Icons.request_quote_outlined, '/admin/dues-report'),
    WebNavItem('Payslips', Icons.receipt_long_outlined, '/super-admin/payslip-generator'),
    WebNavItem('Salary revision', Icons.trending_up_outlined, '/super-admin/propose-salary'),
  ]),
  WebNavSection('Settings', [
    WebNavItem('Reset user password', Icons.lock_reset_outlined, '/super-admin/reset-password'),
    WebNavItem('My profile', Icons.account_circle_outlined, '/super-admin/profile'),
  ]),
];

/// Desktop frame for every super-admin page on web: persistent grouped
/// sidebar + top bar. Pages render in [child]; the sidebar never disappears.
class SuperAdminWebShell extends StatelessWidget {
  const SuperAdminWebShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1180;
    (WebNavSection, WebNavItem)? current;
    for (final s in webNavSections) {
      for (final i in s.items) {
        if (i.path == location) current = (s, i);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(location: location, compact: compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(section: current?.$1.title, page: current?.$2.label ?? ''),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location, required this.compact});

  final String location;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(webPendingTotalProvider).value ?? 0;

    return Container(
      width: compact ? 72 : 256,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(EnvConfig.logoAssetPath, width: 36, height: 36, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, color: AppColors.goldDeep)),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(EnvConfig.shortName, style: AppTypography.headingSm, overflow: TextOverflow.ellipsis),
                          Text('Admin console', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final section in webNavSections) ...[
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 16, 6),
                      child: Text(
                        section.title.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.8),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  for (final item in section.items)
                    _NavTile(
                      item: item,
                      selected: item.path == location,
                      compact: compact,
                      badge: item.path == '/super-admin/approvals' && pending > 0 ? '$pending' : null,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.compact, this.badge});

  final WebNavItem item;
  final bool selected;
  final bool compact;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldDeep : AppColors.textSecondary;
    final tile = Material(
      color: selected ? AppColors.goldCta.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.inkNavy700,
        onTap: () {
          try {
            final rootNav = Navigator.of(context, rootNavigator: true);
            while (rootNav.canPop()) {
              rootNav.pop();
            }
          } catch (_) {}
          try {
            final nav = Navigator.of(context, rootNavigator: false);
            while (nav.canPop()) {
              nav.pop();
            }
          } catch (_) {}
          context.go(item.path);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12, vertical: 9),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Badge(
                isLabelVisible: compact && badge != null,
                label: Text(badge ?? ''),
                backgroundColor: AppColors.warning,
                child: Icon(item.icon, size: 19, color: color),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: selected ? AppColors.goldDeep : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge!, style: AppTypography.labelSm.copyWith(color: Colors.white)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 10, vertical: 1),
      child: compact ? Tooltip(message: item.label, waitDuration: const Duration(milliseconds: 300), child: tile) : tile,
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.section, required this.page});

  final String? section;
  final String page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final name = session?.name.isNotEmpty == true ? session!.name : 'Super Admin';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (section != null) ...[
            Text(section!, style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
            ),
          ],
          Text(page, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Account',
            position: PopupMenuPosition.under,
            color: AppColors.surfaceCard,
            onSelected: (v) async {
              if (v == 'profile') context.go('/super-admin/profile');
              if (v == 'logout') {
                final ok = await confirmAction(
                  context,
                  title: 'Sign out?',
                  message: 'You will need to sign in again to use the admin console.',
                  confirmLabel: 'Sign out',
                  danger: true,
                );
                if (!ok) return;
                await ref.read(supabaseServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('My profile')),
              PopupMenuItem(value: 'logout', child: Text('Sign out', style: TextStyle(color: AppColors.danger))),
            ],
            child: Row(
              children: [
                InitialsAvatar(name, size: 34),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.labelLg),
                    Text('Super Admin', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interim frame for record-management screens not yet redesigned for
/// desktop: renders at a sensible width inside a bordered box instead of
/// full-bleed. Kept for the handful of Phase-2 screens with their own
/// internal tabs/lists that a plain width-cap wouldn't suit.
class WebLegacyFrame extends StatelessWidget {
  const WebLegacyFrame({super.key, required this.child, this.maxWidth = 1040});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frame for single-form screens (add student, reset password, branch
/// registration, …): just centers the screen's own Scaffold/form at a
/// comfortable reading width, no border box — the screen keeps its own
/// AppBar/body/logic untouched, only the horizontal space it fills changes.
class WebFormFrame extends StatelessWidget {
  const WebFormFrame({super.key, required this.child, this.maxWidth = 780});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
        ),
      ),
    );
  }
}
