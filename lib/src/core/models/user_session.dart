// lib/src/core/models/user_session.dart
// Holds the logged-in user's identity and role throughout the app

enum UserRole { guest, student, teacher, branchAdmin, superAdmin }

extension UserRoleExt on UserRole {
  String get name {
    switch (this) {
      case UserRole.superAdmin:   return 'super_admin';
      case UserRole.branchAdmin:  return 'branch_admin';
      case UserRole.teacher:      return 'teacher';
      case UserRole.student:      return 'student';
      default:                    return 'guest';
    }
  }

  static UserRole fromString(String? s) {
    switch (s) {
      case 'super_admin':  return UserRole.superAdmin;
      case 'branch_admin': return UserRole.branchAdmin;
      case 'teacher':      return UserRole.teacher;
      case 'student':      return UserRole.student;
      default:             return UserRole.guest;
    }
  }

  bool get isAdmin    => this == UserRole.superAdmin || this == UserRole.branchAdmin;
  bool get isStaff    => isAdmin || this == UserRole.teacher;
  bool get isSuperAdmin => this == UserRole.superAdmin;
}

class UserSession {
  final String   profileId;
  final String   authUid;
  final UserRole role;
  final String   name;
  final String   email;
  final int?     branchId;
  final String?  accessToken;

  const UserSession({
    required this.profileId,
    required this.authUid,
    required this.role,
    required this.name,
    required this.email,
    this.branchId,
    this.accessToken,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return UserSession(
      profileId:   user['id']?.toString() ?? '',
      authUid:     '',
      role:        UserRoleExt.fromString(user['role']?.toString()),
      name:        user['name']?.toString() ?? '',
      email:       user['email']?.toString() ?? '',
      branchId:    user['branch_id'] as int?,
      accessToken: json['access_token']?.toString(),
    );
  }

  /// Which home route to open after login
  String get homeRoute {
    switch (role) {
      case UserRole.superAdmin:  return '/super-admin';
      case UserRole.branchAdmin: return '/branch-admin';
      case UserRole.teacher:     return '/teacher';
      case UserRole.student:     return '/student';
      default:                   return '/';
    }
  }
}
