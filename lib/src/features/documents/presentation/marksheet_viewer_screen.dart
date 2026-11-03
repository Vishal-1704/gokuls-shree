
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

/// Renders on top of the school's real A4 letterhead (marksheet_bg.jpg) —
/// a portrait document, not an app-themed card, since this is meant to be
/// printed/saved as an actual academic record.
class _MarksheetColors {
_MarksheetColors._();

// Institutional palette: deep navy + restrained gold + neutral slate.
static const navy = Color(0xFF12324A);
static const gold = Color(0xFFC8A951);
static const goldSoft = Color(0xFFF7F1DF);
static const pageBackground = Color(0xFFF3F5F7);
static const text = Color(0xFF1F2937);
static const mutedText = Color(0xFF64748B);
static const border = Color(0xFFD6DEE6);
static const pass = Color(0xFF167C5C);
static const fail = Color(0xFFB42318);
static const warning = Color(0xFF9A6700);
}

class MarksheetViewerScreen extends StatefulWidget {
const MarksheetViewerScreen({super.key, required this.marksheet});

final Map<String, dynamic> marksheet;

@override
State<MarksheetViewerScreen> createState() => _MarksheetViewerScreenState();
}

class _MarksheetViewerScreenState extends State<MarksheetViewerScreen> {
final GlobalKey _sheetKey = GlobalKey();
bool _isExporting = false;

Future<Uint8List?> _capturePng() async {
try {
final boundary =
_sheetKey.currentContext?.findRenderObject()
as RenderRepaintBoundary?;
if (boundary == null) return null;
final image = await boundary.toImage(pixelRatio: 3.0);
final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
return byteData?.buffer.asUint8List();
} catch (_) {
return null;
}
}

Future<void> _exportPdf({bool isShare = false}) async {
if (_isExporting) return;
setState(() => _isExporting = true);
try {
await Future.delayed(const Duration(milliseconds: 100));
final pngBytes = await _capturePng();
if (pngBytes == null) throw Exception('Could not render marksheet');

// The on-screen widget is real A4-shaped (see build()), so a plain
// A4 page with BoxFit.fill needs no letterboxing — this also means
// Android's print framework, which fits/pads a PDF onto whatever
// physical paper size is selected regardless of the PDF's own
// page shape, has nothing left to pad either.
final pdf = pw.Document();
final image = pw.MemoryImage(pngBytes);
pdf.addPage(
pw.Page(
pageFormat: PdfPageFormat.a4,
margin: pw.EdgeInsets.zero,
build: (ctx) => pw.Image(image, fit: pw.BoxFit.fill),
),
);
final pdfBytes = await pdf.save();
final regNo = widget.marksheet['students']?['reg_no'] ?? 'marksheet';

if (isShare) {
await Printing.sharePdf(
bytes: pdfBytes,
filename: 'Marksheet_$regNo.pdf',
);
} else {
await Printing.layoutPdf(
onLayout: (format) async => pdfBytes,
name: 'Marksheet_$regNo.pdf',
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Failed to export: $e'),
backgroundColor: _MarksheetColors.fail,
),
);
}
} finally {
if (mounted) setState(() => _isExporting = false);
}
}

@override
Widget build(BuildContext context) {
final marksheet = widget.marksheet;
final student = marksheet['students'] as Map<String, dynamic>? ?? {};
final course = marksheet['courses'] as Map<String, dynamic>? ?? {};

Map<String, dynamic> marksData = {};
if (marksheet['marks'] is Map) {
  marksData = Map<String, dynamic>.from(marksheet['marks'] as Map);
} else if (marksheet['marks'] is String) {
  try {
    marksData = jsonDecode(marksheet['marks'] as String);
  } catch (_) {}
}
final List<dynamic> subjects = marksData['subjects'] as List<dynamic>? ??
    (marksheet['subjects'] as List<dynamic>?) ??
    [];

final obtainedMarks = marksheet['obtained_marks'] ?? 0;
final totalMarks = marksheet['total_marks'] ?? 100;
final percentage = marksheet['percentage']?.toString() ?? '0.0';
final grade = marksheet['grade'] ?? 'N/A';
final result = (marksheet['result'] ?? 'PASS').toString();
final marksheetId = marksheet['id']?.toString() ?? 'N/A';

return Scaffold(
backgroundColor: _MarksheetColors.pageBackground,
appBar: AppBar(
title: const Text('Digital Marksheet'),
backgroundColor: _MarksheetColors.gold,
foregroundColor: Colors.white,
elevation: 0,
actions: [
IconButton(
icon: const Icon(Icons.share_rounded),
tooltip: 'Share PDF',
onPressed: _isExporting ? null : () => _exportPdf(isShare: true),
),
IconButton(
icon: const Icon(Icons.print_rounded),
tooltip: 'Print / Save as PDF',
onPressed: _isExporting ? null : () => _exportPdf(),
),
],
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Center(
child: RepaintBoundary(
key: _sheetKey,
// Page is authored at a fixed 800px design width so text
// never has to shrink line-by-line to fit. SingleChildScrollView
// only scrolls vertically, so a fixed-width child wider than
// the phone screen (800px vs. a ~360-430px viewport) never
// actually got 800px of real horizontal space — nested
// Expanded widgets resolved against whatever narrow width
// leaked through instead, causing letter-by-letter text wrap
// and the footer-row overflow seen in testing.
//
// FittedBox (not Transform.scale — that only affects painting,
// not the layout size SingleChildScrollView measures) reports
// its OWN size as whatever width the parent actually gives it,
// while still laying out the 800px-wide child internally and
// visually scaling it down to fit. That's what actually
// constrains the scroll view's cross axis correctly.
child: FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.topCenter,
child: SizedBox(
width: 800,
// Real A4 proportions (210:297mm), on purpose this time —
// Android's print framework fits/letterboxes a PDF page
// onto the PHYSICAL paper size chosen in the print dialog
// ("ISO A4"), regardless of what shape our own PDF page
// is. Matching true A4 here means there's nothing left
// for the OS print service to pad — the earlier "custom
// page ratio" fix in _exportPdf only controlled our own
// PDF's mediabox, not what the OS does with it at print
// time, so it couldn't fix the blank strip on its own.
height: 800 * 297 / 210,
child: Container(
decoration: const BoxDecoration(
image: DecorationImage(
image: AssetImage('assets/images/marksheet_bg.jpg'),
fit: BoxFit.fill,
opacity: 0.45,
),
),
padding: const EdgeInsets.symmetric(
horizontal: 72,
vertical: 48,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
_buildHeader(),
_buildStudentInfo(student, course),
_buildMarksTable(subjects),
_buildSummary(
obtainedMarks,
totalMarks,
percentage,
grade,
result,
marksheetId,
),
_buildFooterRow(marksheet['signature_hash'] != null),
],
),
),
),
),
),
),
),
);
}

Widget _buildHeader() {
return Column(
children: [
Image.asset(
'assets/images/school_logo.png',
height: 68,
errorBuilder: (_, __, ___) => Image.asset(
'assets/images/logo.png',
height: 68,
errorBuilder: (_, __, ___) => const SizedBox(height: 68),
),
),
const SizedBox(height: 8),
SizedBox(
width: double.infinity,
child: Text(
'GOKULSHREE SCHOOL OF MANAGEMENT AND TECHNOLOGY PRIVATE LIMITED',
style: const TextStyle(
fontSize: 21,
fontWeight: FontWeight.w900,
letterSpacing: 0.6,
height: 1.25,
color: _MarksheetColors.navy,
),
textAlign: TextAlign.center,
),
),
const SizedBox(height: 4),
const Text(
'Registered Under Companies Act 2013 | CIN: U85499UP2024PTC196434 | ISO 9001:2015 & MSME Certified',
style: TextStyle(
fontSize: 9.5,
fontWeight: FontWeight.w600,
letterSpacing: 0.5,
color: _MarksheetColors.mutedText,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
const Text(
'STATEMENT OF MARKS',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
letterSpacing: 2,
color: _MarksheetColors.text,
),
),
const SizedBox(height: 6),
Container(height: 1.5, color: _MarksheetColors.gold),
],
);
}

Widget _buildStudentInfo(
Map<String, dynamic> student,
Map<String, dynamic> course,
) {
final avatarUrl = student['avatar_url']?.toString();

return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
children: [
_buildInfoRow(
'Student Name',
student['name']?.toString().toUpperCase() ?? 'N/A',
),
_buildInfoRow(
"Father's Name",
student['father_name']?.toString().toUpperCase() ?? 'N/A',
),
_buildInfoRow('Course Name', course['name']?.toString() ?? 'N/A'),
_buildInfoRow(
'Roll Number',
widget.marksheet['roll_no']?.toString() ?? 'N/A',
),
_buildInfoRow(
'Registration No',
student['reg_no']?.toString() ?? 'N/A',
),
_buildInfoRow('Academic Session', _academicSession(student, course)),
],
),
),
const SizedBox(width: 16),
Container(
width: 90,
height: 110,
decoration: BoxDecoration(
color: Colors.white,
border: Border.all(color: _MarksheetColors.border, width: 1.5),
borderRadius: BorderRadius.circular(4),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.05),
blurRadius: 4,
offset: const Offset(0, 2),
),
],
),
child: (avatarUrl != null && avatarUrl.isNotEmpty)
    ? ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.person, size: 48, color: _MarksheetColors.mutedText),
          ),
        ),
      )
    : const Center(
        child: Icon(Icons.person, size: 48, color: _MarksheetColors.mutedText),
      ),
),
],
);
}

/// marksheets.session is unpopulated for legacy-migrated records —
/// students.session (the enrolment year) is the real source. When the
/// course's duration is known, the session end is doj + duration; when
/// duration is unknown (true for most courses today), fall back to
/// session – (session + 1) rather than fabricate a duration.
String _academicSession(
Map<String, dynamic> student,
Map<String, dynamic> course,
) {
final sessionStr = student['session']?.toString();
final startYear = int.tryParse(sessionStr ?? '');
if (startYear == null) return 'N/A';

final durationMonths = _parseDurationMonths(course['duration']?.toString());
if (durationMonths != null) {
final doj = DateTime.tryParse(student['doj']?.toString() ?? '');
if (doj != null) {
final end = DateTime(doj.year, doj.month + durationMonths, doj.day);
return '${_monthYear(doj)} - ${_monthYear(end)}';
}
}

return '$startYear - ${startYear + 1}';
}

/// Parses strings like "6 Months" / "1 Year" / "2 Years" — the only
/// formats seen in courses.duration. Returns null for anything else
/// rather than guessing.
int? _parseDurationMonths(String? duration) {
if (duration == null || duration.isEmpty) return null;
final match = RegExp(
r'(\d+)\s*(month|year)',
caseSensitive: false,
).firstMatch(duration);
if (match == null) return null;
final value = int.tryParse(match.group(1) ?? '');
if (value == null) return null;
final unit = match.group(2)!.toLowerCase();
return unit == 'year' ? value * 12 : value;
}

String _monthYear(DateTime d) {
const months = [
'Jan',
'Feb',
'Mar',
'Apr',
'May',
'Jun',
'Jul',
'Aug',
'Sep',
'Oct',
'Nov',
'Dec',
];
return '${months[d.month - 1]} ${d.year}';
}

Widget _buildInfoRow(String label, String value) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(
width: 180,
child: Text(
label,
style: const TextStyle(
fontSize: 15,
color: _MarksheetColors.mutedText,
),
),
),
const Text(
':  ',
style: TextStyle(fontSize: 15, color: _MarksheetColors.mutedText),
),
Expanded(
child: Text(
value,
style: const TextStyle(
fontSize: 16,
color: _MarksheetColors.text,
fontWeight: FontWeight.w700,
),
),
),
],
),
);
}

Widget _buildMarksTable(List<dynamic> subjects) {
return Table(
columnWidths: const {
0: FlexColumnWidth(4),
1: FlexColumnWidth(2),
2: FlexColumnWidth(2),
},
border: TableBorder.all(color: _MarksheetColors.navy, width: 1.4),
children: [
TableRow(
decoration: const BoxDecoration(color: _MarksheetColors.navy),
children: [
_buildTableCell('SUBJECT NAME', isHeader: true),
_buildTableCell('MAX MARKS', isHeader: true),
_buildTableCell('OBTAINED', isHeader: true),
],
),
if (subjects.isEmpty)
TableRow(
children: [
_buildTableCell('No records found'),
_buildTableCell(''),
_buildTableCell(''),
],
)
else
...subjects.map((sub) {
final name = sub['name']?.toString() ?? sub['subject_name']?.toString() ?? 'Course Module';
final max = sub['max']?.toString() ?? sub['max_marks']?.toString() ?? sub['total_marks']?.toString() ?? '100';
final obtained = sub['theory']?.toString() ?? sub['marks_obtained']?.toString() ?? sub['obtained']?.toString() ?? '0';
return TableRow(
children: [
_buildTableCell(name),
_buildTableCell(max),
_buildTableCell(obtained, highlight: true),
],
);
}),
],
);
}

Widget _buildTableCell(
String text, {
bool isHeader = false,
bool highlight = false,
}) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
child: Text(
text,
textAlign: isHeader ? TextAlign.center : TextAlign.left,
style: TextStyle(
fontSize: 14,
fontWeight: isHeader || highlight
? FontWeight.bold
    : FontWeight.normal,
color: isHeader
? _MarksheetColors.gold
    : (highlight ? _MarksheetColors.navy : _MarksheetColors.text),
),
),
);
}

Widget _buildSummary(
int obtained,
int total,
String percentage,
String grade,
String result,
String marksheetId,
) {
final isPass = result.toUpperCase() == 'PASS';

return Container(
margin: const EdgeInsets.symmetric(vertical: 16),
padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
decoration: BoxDecoration(
color: _MarksheetColors.goldSoft,
border: Border.all(color: _MarksheetColors.gold, width: 1),
borderRadius: BorderRadius.circular(8),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
_buildSummaryItem('Obtained Marks', '$obtained / $total'),
_buildSummaryItem('Percentage', '$percentage%'),
_buildSummaryItem('Grade', grade),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Status',
style: TextStyle(
fontSize: 13,
color: _MarksheetColors.mutedText,
),
),
const SizedBox(height: 5),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 5,
),
decoration: BoxDecoration(
color:
(isPass ? _MarksheetColors.pass : _MarksheetColors.fail)
    .withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: isPass
? _MarksheetColors.pass
    : _MarksheetColors.fail,
),
),
child: Text(
result,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: isPass
? _MarksheetColors.pass
    : _MarksheetColors.fail,
),
),
),
],
),
QrImageView(
data: '${EnvConfig.verifyBaseUrl}/marksheet/$marksheetId',
version: QrVersions.auto,
size: 64.0,
),
],
),
);
}

Widget _buildSummaryItem(String label, String value) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
fontSize: 13,
color: _MarksheetColors.mutedText,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 18,
color: _MarksheetColors.text,
fontWeight: FontWeight.bold,
),
),
],
);
}

/// One footer row: ISO / MSME / Skill India accreditation logos on the
/// left (own space, no longer squeezed against the stamp), a
/// digital-signature stamp (real signed/unsigned state, not a hardcoded
/// badge) on the right — QR moved into _buildSummary by hand-edit.
Widget _buildFooterRow(bool isSigned) {
return Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Expanded(
flex: 5,
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Image.asset(
'assets/images/iso-logo.png',
height: 74,
fit: BoxFit.contain,
),
Image.asset(
'assets/images/msme_logo.png',
height: 56,
fit: BoxFit.contain,
),
Image.asset(
'assets/images/skill_India-logo.png',
height: 74,
fit: BoxFit.contain,
),
_buildSignatureStamp(isSigned),
],
),
),
],
);
}

/// Digital-signature stamp, matching the reference Adobe-style panel:
/// a large bold title ("Signature valid") sits clear of the mark, and a
/// big tilted translucent checkmark/question-mark cuts across the
/// smaller identity/detail lines beneath it — not the title itself.
/// Font sizes here are bigger than a first attempt because this whole
/// page is scaled down once more (FittedBox in build()) to fit a phone
/// screen; text has to survive that shrink and still be legible under
/// a translucent icon.
Widget _buildSignatureStamp(bool isSigned) {
final color = isSigned ? _MarksheetColors.pass : _MarksheetColors.warning;
final label = isSigned ? 'Signature valid' : 'Validity unknown';

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
label,
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: color,
),
),
const SizedBox(height: 6),
Stack(
clipBehavior: Clip.none,
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
const Text(
'Digitally signed by',
style: TextStyle(
fontSize: 13,
color: _MarksheetColors.mutedText,
),
),
const Text(
'Controller of Examninations',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: _MarksheetColors.navy,

),

),
const Text(
'GSMT',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: _MarksheetColors.navy,

),
),
],
),
// Large tilted mark bleeding across the detail lines above,
// matching the reference image — real stamp artwork (already
// has the black-outline/drop-shadow look), not a custom paint.
Positioned(
left: 30,
top: -8,
child: Transform.rotate(
angle: 0.0,
child: Opacity(
opacity: 0.7,
child: Image.asset(
isSigned
? 'assets/images/chekcIconpng .png'
    : 'assets/images/uncheck.png',
width: 70,
height: 70,
),
),
),
),
],
),
],
);
}
}