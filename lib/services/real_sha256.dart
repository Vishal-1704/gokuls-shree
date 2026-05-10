// Replace _sha256short() in marksheet_service.dart with this
// once you add: crypto: ^3.0.3 to pubspec.yaml

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'marksheet_service.dart';

String generateDocumentHash(MarksheetData data) {
  final input =
      '${data.regNo}|${data.studentName}|'
      '${data.courseName}|${data.totalSecured}|'
      '${data.issueDate}|U80900UP2021PTC154024';
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  // Store full hash in PDF metadata, show first 12 chars if needed
  return digest.toString().toUpperCase();
}
