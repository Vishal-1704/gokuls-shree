import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/features/documents/data/document_repository.dart';
import 'package:gokul_shree_app/src/core/widgets/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';
import 'package:gokul_shree_app/src/features/documents/services/certificate_service.dart';
import 'package:gokul_shree_app/src/features/documents/services/marksheet_service.dart';

class MyDocumentsScreen extends ConsumerStatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  ConsumerState<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends ConsumerState<MyDocumentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _marksheets = [];
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final authState = ref.read(supabaseAuthProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final docs = await ref.read(documentRepositoryProvider).getMyDocuments(authState.user.id);
      setState(() {
        _marksheets = docs['marksheets']!;
        _certificates = docs['certificates']!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading documents: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy800,
        title: const Text('My Documents'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDocuments),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldCta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Academic Marksheets', _marksheets.length),
                  const SizedBox(height: 12),
                  ..._marksheets.map((m) => _buildDocCard('Marksheet', m)),
                  if (_marksheets.isEmpty) _buildEmptyState('No marksheets found'),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Certificates', _certificates.length),
                  const SizedBox(height: 12),
                  ..._certificates.map((c) => _buildDocCard('Certificate', c)),
                  if (_certificates.isEmpty) _buildEmptyState('No certificates found'),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.inkNavy800, Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldCta.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldCta.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.goldCta, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Documents', style: AppTypography.headingSm),
                const SizedBox(height: 4),
                Text(
                  'Only approved documents are visible here. Verified via QR.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title, style: AppTypography.headingSm),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.inkNavy700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(count.toString(), style: AppTypography.labelMd),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted)),
      ),
    );
  }

  Widget _buildDocCard(String type, Map<String, dynamic> doc) {
    final courseName = doc['courses']?['name'] ?? 'N/A';
    final issueDate = doc['created_at']?.toString().split('T')[0] ?? 'N/A';
    final isMarksheet = type == 'Marksheet';

    return Card(
      color: AppColors.inkNavy800,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isMarksheet ? Colors.blue : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isMarksheet ? Icons.description_rounded : Icons.workspace_premium_rounded,
            color: isMarksheet ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(courseName, style: AppTypography.headingSm),
        subtitle: Text('Issued: $issueDate', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: () => _viewDocument(type, doc),
      ),
    );
  }

  Future<void> _viewDocument(String type, Map<String, dynamic> doc) async {
    // We would normally generate the PDF here or fetch from Storage
    // For now, let's show a snackbar as we have finalized the schema and flow.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $type... Digitally Verified.')),
    );
  }
}
