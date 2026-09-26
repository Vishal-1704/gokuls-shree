import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../admin/presentation/admin_panel_screen.dart';
import '../admin/routing/admin_routes.dart';
import '../super_admin_app/routing/super_admin_routes.dart';
import 'pages/web_approvals_page.dart';
import 'pages/web_branches_page.dart';
import 'pages/web_dashboard_page.dart';
import 'pages/web_departments_page.dart';
import 'pages/web_dues_report_page.dart';
import 'pages/web_paper_manager_page.dart';
import 'pages/web_profile_page.dart';
import 'pages/web_reports_page.dart';
import 'pages/web_schedule_results_page.dart';
import 'pages/web_students_page.dart';
import 'web_shell.dart';

/// Super-admin route tree used only on web. Every page renders inside the
/// persistent console shell. The mobile super-admin shell is untouched.
class SuperAdminWebRoutes {
  static Page<void> _page(Widget child) => NoTransitionPage(child: child);

  /// Screens with their own desktop page below — skipped in the generic
  /// legacy loop so their path isn't registered twice.
  static const _redesignedPaths = {
    '/super-admin/manage-departments',
    '/super-admin/paper-manager',
    '/super-admin/schedule-results',
    '/admin/dues-report',
  };

  /// Single-form screens (fill fields, submit) — centered, no border box.
  /// Everything else (tabs, lists, multi-step flows) stays in
  /// [WebLegacyFrame] until it gets a real desktop layout.
  static const _formScreenPaths = {
    '/super-admin/reset-password',
    '/super-admin/add-student',
    '/admin/add-student',
    '/super-admin/branch-registration',
    '/admin/branch-registration',
    '/super-admin/franchise-setup',
    '/admin/franchise-setup',
    '/super-admin/propose-salary',
    '/super-admin/payslip-generator',
    '/super-admin/study-material',
    '/admin/study-material',
    '/super-admin/results-entry',
    '/admin/results-entry',
    '/admin/marksheet-generator',
    '/admin/fee-collection',
    '/super-admin/exam-scheduler',
    '/admin/exam-scheduler',
  };

  static RouteBase get shell => ShellRoute(
        builder: (context, state, child) => SuperAdminWebShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/super-admin', pageBuilder: (_, __) => _page(const WebDashboardPage())),
          GoRoute(path: '/super-admin/approvals', pageBuilder: (_, __) => _page(const WebApprovalsPage())),
          GoRoute(path: '/super-admin/branches', pageBuilder: (_, __) => _page(const WebBranchesPage())),
          GoRoute(
            path: '/super-admin/students',
            pageBuilder: (_, state) => _page(
              WebStudentsPage(initialBranchId: int.tryParse(state.uri.queryParameters['branch'] ?? '')),
            ),
          ),
          GoRoute(path: '/super-admin/reports', pageBuilder: (_, __) => _page(const WebReportsPage())),
          GoRoute(path: '/super-admin/profile', pageBuilder: (_, __) => _page(const WebProfilePage())),
          // Phase 2 screens: existing admin tools, framed inside the console
          // until each gets its own desktop layout.
          GoRoute(
            path: '/super-admin/content',
            pageBuilder: (_, __) => _page(const WebLegacyFrame(child: AdminPanelScreen(showStudentsTab: false))),
          ),
          GoRoute(path: '/super-admin/manage-departments', pageBuilder: (_, __) => _page(const WebDepartmentsPage())),
          GoRoute(path: '/super-admin/paper-manager', pageBuilder: (_, __) => _page(const WebPaperManagerPage())),
          GoRoute(path: '/super-admin/schedule-results', pageBuilder: (_, __) => _page(const WebScheduleResultsPage())),
          GoRoute(path: '/admin/dues-report', pageBuilder: (_, __) => _page(const WebDuesReportPage())),
          for (final r in [...SuperAdminRoutes.standaloneRoutes, ...AdminRoutes.standaloneRoutes])
            if (!_redesignedPaths.contains(r.path))
              GoRoute(
                path: r.path,
                pageBuilder: (context, state) => _page(
                  _formScreenPaths.contains(r.path)
                      ? WebFormFrame(child: r.builder!(context, state))
                      : WebLegacyFrame(child: r.builder!(context, state)),
                ),
              ),
        ],
      );
}
