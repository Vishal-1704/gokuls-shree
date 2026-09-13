import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

/// Student ("agent") side of the smart attendance system. Scans the QR a
/// teacher/branch_admin/super_admin ("host", see teacher_attendance_
/// screen.dart) is displaying, then does a brief ambient BLE scan and
/// submits both to checkin_attendance. This replaces what used to be a
/// placeholder dialog telling the student to "build on a physical
/// device" — there was no real check-in flow at all before this.
///
/// BLE here is a supplementary signal only (no specific host device to
/// pair with — flutter_blue_plus can't make the host's phone advertise
/// anything identifiable, and building that would need a different
/// plugin with real iOS background restrictions). It records the
/// strongest nearby RSSI as a rough "there is real BLE activity around
/// me" reading; the server never blocks a check-in for a missing or weak
/// reading, it only affects the confidence_score staff can review later.
class StudentCheckinScreen extends ConsumerStatefulWidget {
  const StudentCheckinScreen({super.key});

  @override
  ConsumerState<StudentCheckinScreen> createState() =>
      _StudentCheckinScreenState();
}

enum _Stage { scanning, verifying, result }

class _StudentCheckinScreenState extends ConsumerState<StudentCheckinScreen> {
  _Stage _stage = _Stage.scanning;
  bool _handledDetection = false;
  String? _resultTitle;
  String? _resultMessage;
  bool _resultIsSuccess = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handledDetection) return;
    final raw = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (raw == null) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // Not our QR format — keep scanning instead of erroring out.
    }
    final sessionId = payload['session_id']?.toString();
    final nonce = payload['nonce']?.toString();
    if (sessionId == null || nonce == null) return;

    _handledDetection = true;
    setState(() => _stage = _Stage.verifying);
    await _checkIn(sessionId, nonce);
  }

  Future<int?> _scanAmbientBleRssi() async {
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        return null; // No permission — check-in still proceeds on QR alone.
      }

      int? strongest;
      final completer = Completer<int?>();
      late final StreamSubscription<List<ScanResult>> sub;

      sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (strongest == null || r.rssi > strongest!) strongest = r.rssi;
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      Timer(const Duration(seconds: 3), () async {
        await FlutterBluePlus.stopScan();
        await sub.cancel();
        if (!completer.isCompleted) completer.complete(strongest);
      });

      return await completer.future;
    } catch (_) {
      return null; // BLE unavailable on this device — QR check-in still works.
    }
  }

  Future<void> _checkIn(String sessionId, String nonce) async {
    final bleRssi = await _scanAmbientBleRssi();

    try {
      final result = await ref
          .read(supabaseServiceProvider)
          .checkinAttendance(
            sessionId: sessionId,
            qrNonce: nonce,
            bleRssi: bleRssi,
          );

      if (result['success'] == true) {
        final alreadyIn = result['already_checked_in'] == true;
        setState(() {
          _stage = _Stage.result;
          _resultIsSuccess = true;
          _resultTitle = alreadyIn
              ? 'Already Checked In'
              : 'Attendance Marked!';
          _resultMessage = alreadyIn
              ? 'You were already marked present for this session.'
              : bleRssi != null
              ? 'You are marked present. BLE proximity signal recorded.'
              : 'You are marked present via QR.';
        });
      } else {
        setState(() {
          _stage = _Stage.result;
          _resultIsSuccess = false;
          _resultTitle = 'Check-in Failed';
          _resultMessage = _reasonToMessage(result['reason']?.toString());
        });
      }
    } catch (e) {
      setState(() {
        _stage = _Stage.result;
        _resultIsSuccess = false;
        _resultTitle = 'Check-in Failed';
        _resultMessage = 'Something went wrong: $e';
      });
    }
  }

  String _reasonToMessage(String? reason) {
    switch (reason) {
      case 'session_expired':
        return 'This QR code has expired. Ask your teacher for a new one.';
      case 'invalid_session':
        return 'This QR code is not valid.';
      case 'not_in_scope':
        return 'This session is not for your course/branch.';
      case 'not_a_student':
        return 'Only students can check in to attendance sessions.';
      default:
        return 'Could not verify your attendance. Please try again.';
    }
  }

  void _scanAgain() {
    setState(() {
      _handledDetection = false;
      _stage = _Stage.scanning;
      _resultTitle = null;
      _resultMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scan Attendance',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: switch (_stage) {
        _Stage.scanning => Stack(
          children: [
            MobileScanner(onDetect: _onDetect),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Point your camera at your teacher\'s QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        _Stage.verifying => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.goldCta),
              SizedBox(height: 16),
              Text(
                'Verifying attendance…',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        _Stage.result => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _resultIsSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: _resultIsSuccess
                      ? AppColors.success
                      : AppColors.danger,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  _resultTitle ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _resultMessage ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_resultIsSuccess)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldCta,
                    ),
                    child: const Text('Done'),
                  )
                else
                  ElevatedButton(
                    onPressed: _scanAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldCta,
                    ),
                    child: const Text('Scan Again'),
                  ),
              ],
            ),
          ),
        ),
      },
    );
  }
}
