// lib/src/features/teacher/presentation/teacher_students_screen.dart
import 'package:flutter/material.dart';

class TeacherStudentsScreen extends StatelessWidget {
  const TeacherStudentsScreen({super.key});

  final _students = const [
    {'name': 'Renu Prajapati', 'reg': 'GOKUL0181121', 'course': 'DCA', 'status': 'Active'},
    {'name': 'Sushma Maurya',  'reg': 'GOKUL0280722', 'course': 'ADCA', 'status': 'Active'},
    {'name': 'Mahima Pandey',  'reg': 'GOKUL0300722', 'course': 'ADCA', 'status': 'Active'},
    {'name': 'Manoj Kumar',    'reg': 'GOKUL1140824', 'course': 'ADCA', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2E18),
        title: const Text('Students', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _students.length,
        itemBuilder: (ctx, i) {
          final s = _students[i];
          return Card(
            color: const Color(0xFF112A16),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.2),
                child: Text(s['name']![0], style: const TextStyle(color: Colors.greenAccent)),
              ),
              title: Text(s['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('${s['reg']} • ${s['course']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s['status']!, style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ),
            ),
          );
        },
      ),
    );
  }
}
