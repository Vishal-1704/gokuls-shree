// lib/models/user_session.dart
// Shared request context model — equivalent to attaching fields to req in Express.

class UserSession {
  final String userId;       // Supabase auth.users.id (UUID)
  final String profileId;   // profiles.id (UUID)
  final String role;
  final int? branchId;
  final String fullName;
  final Map<String, dynamic> profile;

  // Set by strictBranchGuard:
  int? queryBranchId;

  // Set by studentSelfGuard:
  int? studentId;
  int? studentBranchId;

  UserSession({
    required this.userId,
    required this.profileId,
    required this.role,
    this.branchId,
    required this.fullName,
    required this.profile,
  });
}

/// Valid roles — anything else is rejected
const Set<String> validRoles = {
  'super_admin',
  'branch_admin',
  'teacher',
  'student',
};
