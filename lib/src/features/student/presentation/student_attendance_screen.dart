// lib/src/features/student/presentation/student_attendance_screen.dart
import 'package:flutter/material.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = [
      {'date': '2026-05-10', 'day': 'Sun', 'status': 'P'},
      {'date': '2026-05-09', 'day': 'Sat', 'status': 'P'},
      {'date': '2026-05-08', 'day': 'Fri', 'status': 'A'},
      {'date': '2026-05-07', 'day': 'Thu', 'status': 'P'},
      {'date': '2026-05-06', 'day': 'Wed', 'status': 'L'},
      {'date': '2026-05-05', 'day': 'Tue', 'status': 'P'},
    ];
    final present = records.where((r) => r['status'] == 'P').length;
    final pct = ((present / records.length) * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1E33),
      appBar: AppBar(
        backgroundColor: const Color(0xFF152D4D),
        title: const Text('My Attendance', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF0E2A47)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _AttStat('$present', 'Present', Colors.greenAccent),
            _AttStat('${records.length - present}', 'Absent', Colors.redAccent),
            _AttStat('$pct%', 'Attendance', Colors.amberAccent),
          ]),
        ),
        // Records
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: records.length,
          itemBuilder: (ctx, i) {
            final r = records[i];
            final color = r['status'] == 'P' ? Colors.green
                : r['status'] == 'L' ? Colors.orange : Colors.red;
            final label = r['status'] == 'P' ? 'Present'
                : r['status'] == 'L' ? 'Late' : 'Absent';
            return Card(
              color: const Color(0xFF152D4D),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(r['day']!, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                title: Text(r['date']!, style: const TextStyle(color: Colors.white)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            );
          },
        )),
      ]),
    );
  }
}

class _AttStat extends StatelessWidget {
  const _AttStat(this.value, this.label, this.color);
  final String value, label; final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  ]);
}
