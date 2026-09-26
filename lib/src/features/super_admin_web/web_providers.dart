import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/admin/data/admin_repository.dart';

// Thin cached wrappers over the shared AdminRepository so the web console's
// sidebar badge, dashboard and approvals page all read the same data.

final webPendingStudentsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getPendingStudents(),
);

final webPendingDocumentsProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>(
  (ref) => ref.watch(adminRepositoryProvider).getPendingDocuments(),
);

final webPendingExpCertsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getPendingExperienceCerts(),
);

final webPendingSalaryProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getPendingSalaryRevisions(),
);

final webPendingTotalProvider = FutureProvider<int>((ref) async {
  final results = await Future.wait([
    ref.watch(webPendingStudentsProvider.future),
    ref.watch(webPendingExpCertsProvider.future),
    ref.watch(webPendingSalaryProvider.future),
  ]);
  final docs = await ref.watch(webPendingDocumentsProvider.future);
  return results.fold<int>(0, (sum, list) => sum + list.length) +
      (docs['marksheets']?.length ?? 0) +
      (docs['certificates']?.length ?? 0);
});

void invalidatePendingApprovals(WidgetRef ref) {
  ref.invalidate(webPendingStudentsProvider);
  ref.invalidate(webPendingDocumentsProvider);
  ref.invalidate(webPendingExpCertsProvider);
  ref.invalidate(webPendingSalaryProvider);
}
