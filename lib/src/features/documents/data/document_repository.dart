import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class DocumentRepository {
  /// Get all documents for the current student. [authUid] is the Supabase
  /// auth uid — students.profile_id is a FK to profiles.id, not the auth
  /// uid directly, so it must be resolved through profiles first (same fix
  /// as supabase_service.dart's _currentStudentId).
  Future<Map<String, List<Map<String, dynamic>>>> getMyDocuments(
    String authUid,
  ) async {
    final profile = await supabase
        .from('profiles')
        .select('id')
        .eq('auth_uid', authUid)
        .maybeSingle();
    if (profile == null) return {'marksheets': [], 'certificates': []};

    final student = await supabase
        .from('students')
        .select('id')
        .eq('profile_id', profile['id'])
        .maybeSingle();

    if (student == null) return {'marksheets': [], 'certificates': []};

    final studentId = student['id'];

    final results = await Future.wait([
      supabase
          .from('marksheets')
          .select(
            '*, courses(name, duration), students(name, father_name, reg_no, session, doj)',
          )
          .eq('student_id', studentId)
          .eq('status', 1), // Only approved
      supabase
          .from('certificates')
          .select(
            '*, courses(name, duration), students(name, father_name, reg_no, session, doj)',
          )
          .eq('student_id', studentId)
          .eq('status', 1), // Only approved
    ]);

    return {
      'marksheets': List<Map<String, dynamic>>.from(results[0]),
      'certificates': List<Map<String, dynamic>>.from(results[1]),
    };
  }

  /// Public verification of a document (Marksheet or Certificate). Checks
  /// both existence AND that the document's current data hasn't been
  /// tampered with since approval (verify_document_signature RPC —
  /// migration 20240301000014), not just "does a row with this id exist".
  ///
  /// [docType] is 'marksheet' or 'certificate', [id] is the row's numeric
  /// primary key — this must match exactly what the QR codes in
  /// marksheet_viewer_screen.dart / certificate_viewer_screen.dart encode
  /// (verifyBaseUrl/<type>/<id>).
  Future<Map<String, dynamic>> verifyDocument(String docType, int id) async {
    final signatureResult = await supabase.rpc(
      'verify_document_signature',
      params: {'p_type': docType, 'p_id': id},
    );
    final result = (signatureResult['result'] ?? 'not_found').toString();

    if (result != 'valid') {
      return {'result': result, 'type': docType, 'id': id, 'document': null};
    }

    final isEmployeeDoc = docType == 'payslip' || docType == 'experience_certificate';
    final table = switch (docType) {
      'marksheet' => 'marksheets',
      'payslip' => 'payslips',
      'experience_certificate' => 'experience_certificates',
      _ => 'certificates',
    };
    final select = isEmployeeDoc
        ? '*, employees(name, designation)'
        : '*, students(name, reg_no), courses(name)';

    final response = await supabase
        .from(table)
        .select(select)
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      // Signature said valid but the row vanished between the two calls —
      // treat as not found rather than crash on a null join.
      return {
        'result': 'not_found',
        'type': docType,
        'id': id,
        'document': null,
      };
    }

    final Map<String, dynamic> document;
    if (docType == 'payslip') {
      document = {
        'id': response['id'],
        'type': 'Payslip',
        'students': {
          'name': response['employees']?['name'],
          'registration_number': response['employees']?['designation'],
        },
        'data': {
          'course': 'Month ${response['month']}/${response['year']}',
          'session': null,
          'result': 'Rs. ${response['net_pay']}',
          'percentage': 'N/A',
        },
        'created_at': response['generated_at'],
      };
    } else if (docType == 'experience_certificate') {
      document = {
        'id': response['id'],
        'type': 'Experience Certificate',
        'students': {
          'name': response['employees']?['name'],
          'registration_number': response['employees']?['designation'],
        },
        'data': {
          'course': null,
          'session': null,
          'result': 'Issued',
          'percentage': 'N/A',
        },
        'created_at': response['issue_date'],
      };
    } else {
      document = {
        'id': response['id'],
        'type': docType == 'marksheet' ? 'Marksheet' : 'Certificate',
        'students': {
          'name': response['students']?['name'],
          'registration_number': response['students']?['reg_no'],
        },
        'data': {
          'course': response['courses']?['name'],
          'session': response['session'],
          'result': response['result'] ?? 'Issued',
          'percentage': response['percentage'] != null
              ? '${response['percentage']}%'
              : 'N/A',
        },
        'created_at': response['created_at'],
      };
    }

    return {'result': 'valid', 'type': docType, 'id': id, 'document': document};
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});
