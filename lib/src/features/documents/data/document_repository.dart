import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class DocumentRepository {
  /// Get all documents for the current student
  Future<Map<String, List<Map<String, dynamic>>>> getMyDocuments(String profileId) async {
    // 1. Get student record by profile_id
    final student = await supabase
        .from('students')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    
    if (student == null) return {'marksheets': [], 'certificates': []};
    
    final studentId = student['id'];

    final results = await Future.wait([
      supabase
          .from('marksheets')
          .select('*, courses(name)')
          .eq('student_id', studentId)
          .eq('status', 1), // Only approved
      supabase
          .from('certificates')
          .select('*, courses(name)')
          .eq('student_id', studentId)
          .eq('status', 1), // Only approved
    ]);

    return {
      'marksheets': List<Map<String, dynamic>>.from(results[0]),
      'certificates': List<Map<String, dynamic>>.from(results[1]),
    };
  }

  /// Public verification of a document (Marksheet or Certificate)
  Future<Map<String, dynamic>?> getDocumentById(String docId) async {
    // docId format: "M-123" for marksheet, "C-123" for certificate
    final parts = docId.split('-');
    if (parts.length != 2) return null;

    final type = parts[0] == 'M' ? 'marksheets' : 'certificates';
    final id = int.tryParse(parts[1]);
    if (id == null) return null;

    try {
      final response = await supabase
          .from(type)
          .select('*, students(name, reg_no), courses(name)')
          .eq('id', id)
          .eq('status', 1) // ONLY verify approved documents
          .maybeSingle();

      if (response == null) return null;

      // Return a unified structure for the UI
      return {
        'id': response['id'],
        'type': parts[0] == 'M' ? 'Marksheet' : 'Certificate',
        'status': response['status'],
        'students': {
          'name': response['students']['name'],
          'registration_number': response['students']['reg_no'],
        },
        'data': {
          'course': response['courses']['name'],
          'session': response['session'],
          'result': response['result'] ?? 'Issued',
          'percentage': response['percentage'] != null ? '${response['percentage']}%' : 'N/A',
        },
        'created_at': response['created_at'],
      };
    } catch (e) {
      return null;
    }
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});
