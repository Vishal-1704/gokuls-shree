import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class TeacherBleBroadcaster extends ConsumerStatefulWidget {
  const TeacherBleBroadcaster({
    super.key,
    required this.courseId,
    required this.batchId,
    required this.branchId,
  });

  final int courseId;
  final int batchId;
  final int branchId;

  @override
  ConsumerState<TeacherBleBroadcaster> createState() => _TeacherBleBroadcasterState();
}

class _TeacherBleBroadcasterState extends ConsumerState<TeacherBleBroadcaster> {
  bool _isBroadcasting = false;
  String? _sessionId;
  String? _originalBluetoothName;
  static const _platform = MethodChannel('com.gokulshree.app/bluetooth');
  
  String _statusText = 'Ready to launch attendance session.';
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes session

  @override
  void dispose() {
    _stopBroadcasting();
    super.dispose();
  }

  Future<void> _startBroadcasting() async {
    setState(() {
      _statusText = 'Generating session in database...';
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final now = DateTime.now();
      final expires = now.add(const Duration(minutes: 5));
      final nonce = DateTime.now().microsecondsSinceEpoch.toString();
      final hashPayload = 'ATT-${widget.courseId}-${widget.batchId}-$nonce';

      // 1. Create a session on the server
      final session = await supabaseService.startQrAttendanceSession(
        scopeType: 'classroom_ble',
        courseId: widget.courseId,
        batchId: widget.batchId,
        branchId: widget.branchId,
        startsAt: now,
        expiresAt: expires,
        qrNonce: nonce,
        qrPayloadHash: hashPayload,
      );

      final sessionId = session['id']?.toString() ?? nonce;

      // 2. Set discoverable Bluetooth name to "GOKUL_[session_id]" if supported natively
      try {
        _originalBluetoothName = await _platform.invokeMethod<String>('getBluetoothName');
        await _platform.invokeMethod('setBluetoothName', {'name': 'GOKUL_$sessionId'});
      } catch (e) {
        debugPrint('Platform Bluetooth renaming not supported: $e');
      }

      setState(() {
        _isBroadcasting = true;
        _sessionId = sessionId;
        _secondsRemaining = 300;
        _statusText = 'Broadcasting Bluetooth Beacon...';
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _stopBroadcasting();
          }
        });
      });
    } catch (e) {
      setState(() {
        _statusText = 'Failed to generate session: $e';
      });
    }
  }

  Future<void> _stopBroadcasting() async {
    _countdownTimer?.cancel();
    
    // Restore Bluetooth name if modified
    if (_originalBluetoothName != null) {
      try {
        await _platform.invokeMethod('setBluetoothName', {'name': _originalBluetoothName});
      } catch (_) {}
    }

    setState(() {
      _isBroadcasting = false;
      _sessionId = null;
      _statusText = 'Session ended.';
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BLE Smart Roll Call',
                style: AppTypography.headingSm.copyWith(color: AppColors.goldCta),
              ),
              if (_isBroadcasting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const _PulseIndicator(),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: AppTypography.mono.copyWith(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isBroadcasting) ...[
            const Icon(Icons.bluetooth_audio_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: _startBroadcasting,
              child: const Text('START SESSION BROADCAST'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _sessionId ?? 'N/A',
                version: QrVersions.auto,
                size: 160.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR to students. They must scan it and be within 5m of you to verify.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'BLE Local Name: GOKUL_$_sessionId',
              style: AppTypography.mono.copyWith(color: AppColors.goldShine, fontSize: 12),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              onPressed: _stopBroadcasting,
              child: const Text('STOP SESSION'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        height: 8,
        width: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
