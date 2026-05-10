// lib/src/features/student/presentation/student_id_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/session_provider.dart';

class StudentIdCardScreen extends ConsumerWidget {
  const StudentIdCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1E33),
      appBar: AppBar(
        backgroundColor: const Color(0xFF152D4D),
        title: const Text('My ID Card', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // The ID Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A5C), Color(0xFF0A1E35)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF5CC45), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5CC45),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF0E1E33), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.school_rounded, color: Color(0xFFF5CC45), size: 20)),
                    const SizedBox(width: 10),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('GOKUL SHREE', style: TextStyle(color: Color(0xFF0E1E33), fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('School of Mgmt & Technology', style: TextStyle(color: Color(0xFF1A3A5C), fontSize: 9)),
                    ]),
                  ]),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Photo placeholder
                    Container(
                      width: 80, height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF5CC45), width: 1),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white38, size: 48),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(session?.name ?? 'Student Name',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _IdRow('Reg No.',  'GOKUL0181121'),
                      _IdRow('Course',   'DCA'),
                      _IdRow('Session',  '2024-25'),
                      _IdRow('Valid',    'Mar 2026'),
                    ])),
                  ]),
                ),
                // QR
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 48),
                    const SizedBox(width: 10),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Scan to verify', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('gokulshreeschool.com', style: TextStyle(color: Color(0xFFF5CC45), fontSize: 11)),
                    ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download ID Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5CC45),
                foregroundColor: const Color(0xFF0E1E33),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
            ),
          ]),
        ),
      ),
    );
  }
}

class _IdRow extends StatelessWidget {
  const _IdRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}
