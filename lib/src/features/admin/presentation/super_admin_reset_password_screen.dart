import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

/// Super Admin ONLY — Reset any user's password.
/// This screen is only reachable if the router confirms role == super_admin.
class SuperAdminResetPasswordScreen extends ConsumerStatefulWidget {
  const SuperAdminResetPasswordScreen({super.key});

  @override
  ConsumerState<SuperAdminResetPasswordScreen> createState() =>
      _SuperAdminResetPasswordScreenState();
}

class _SuperAdminResetPasswordScreenState
    extends ConsumerState<SuperAdminResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  List<Map<String, dynamic>> _profiles = [];
  Map<String, dynamic>? _selectedProfile;

  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all profiles — super admin can see all via RLS
      final response = await supabase
          .from('profiles')
          .select('id, full_name, role, branch_id, status')
          .order('full_name');
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to load users: $e', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfile == null) {
      _showSnack('Please select a target user first.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Password Reset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Reset password for "${_selectedProfile!['full_name'] ?? 'Unknown'}"?\n\n'
          'This action is logged. The user will need to use the new password immediately.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('Session expired. Please log in again.');

      final resp = await Dio().post(
        '$_apiBase/auth/admin/reset-password',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        }),
        data: {
          'targetProfileId': _selectedProfile!['id'],
          'newPassword': _newPasswordCtrl.text,
        },
      );

      final body = resp.data as Map<String, dynamic>;
      if (resp.statusCode == 200 && body['success'] == true) {
        final resetName = _selectedProfile?['full_name'] ?? 'user';
        _newPasswordCtrl.clear();
        _confirmCtrl.clear();
        setState(() => _selectedProfile = null);
        _showSnack('✅ Password reset successfully for $resetName!');
      } else {
        throw Exception(body['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showSnack('Reset failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin': return '🔐 Super Admin';
      case 'branch_admin': return '🏢 Branch Admin';
      case 'teacher': return '👨‍🏫 Teacher';
      case 'student': return '🎓 Student';
      default: return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return Colors.purpleAccent;
      case 'branch_admin': return Colors.blue;
      case 'teacher': return Colors.teal;
      case 'student': return AppColors.goldCta;
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A2E),
        elevation: 0,
        title: const Text('Reset User Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Super Admin Action — This operation is audit-logged. '
                              'Only you (super_admin) can perform this action.',
                              style: AppTypography.bodySm.copyWith(color: Colors.orange.shade200),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Select user
                    Text('Select Target User',
                        style: AppTypography.labelMd.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          value: _selectedProfile,
                          dropdownColor: const Color(0xFF1A0A2E),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          hint: const Text('-- Select a user --',
                              style: TextStyle(color: Colors.white38)),
                          items: _profiles.map((p) {
                            final role = p['role'] as String? ?? 'unknown';
                            final name = p['full_name'] ?? 'Unknown';
                            final active = (p['status'] ?? 0) == 1;
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: active ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(_roleLabel(role),
                                      style: TextStyle(
                                          color: _roleColor(role), fontSize: 11)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedProfile = val),
                        ),
                      ),
                    ),

                    // Selected user info card
                    if (_selectedProfile != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _roleColor(_selectedProfile!['role'] ?? '').withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _roleColor(_selectedProfile!['role'] ?? '').withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded,
                                color: _roleColor(_selectedProfile!['role'] ?? '')),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedProfile!['full_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w600)),
                                Text(_roleLabel(_selectedProfile!['role'] ?? ''),
                                    style: TextStyle(
                                        color: _roleColor(_selectedProfile!['role'] ?? ''),
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    Text('New Password',
                        style: AppTypography.labelMd.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNew,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Min. 6 characters',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A0A2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.goldCta),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureNew ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Confirm New Password',
                        style: AppTypography.labelMd.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A0A2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.goldCta),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm the password';
                        if (v != _newPasswordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _resetPassword,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_reset_rounded),
                        label: Text(
                          _isSaving ? 'Resetting...' : 'Reset Password',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '🔒 This action is recorded in the audit log.',
                        style: AppTypography.bodySm.copyWith(color: Colors.white30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
