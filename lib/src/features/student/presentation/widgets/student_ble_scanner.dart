import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class StudentBleScanner extends ConsumerStatefulWidget {
  const StudentBleScanner({
    super.key,
    required this.sessionId,
    required this.onVerificationComplete,
  });

  final String sessionId;
  final void Function(bool success, String message) onVerificationComplete;

  @override
  ConsumerState<StudentBleScanner> createState() => _StudentBleScannerState();
}

class _StudentBleScannerState extends ConsumerState<StudentBleScanner> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;
  double _progress = 0.0;
  Timer? _progressTimer;
  int? _foundRssi;
  String _statusText = 'Initializing Bluetooth...';
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startBluetoothScan();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _scanSubscription?.cancel();
    _progressTimer?.cancel();
    if (FlutterBluePlus.isScanningNow) {
      FlutterBluePlus.stopScan();
    }
  }

  Future<void> _startBluetoothScan() async {
    setState(() {
      _isScanning = true;
      _statusText = 'Scanning for teacher beacon...';
      _progress = 0.0;
    });

    // Check adapter state
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      setState(() {
        _isScanning = false;
        _statusText = 'Please enable Bluetooth to mark attendance';
      });
      widget.onVerificationComplete(false, 'Bluetooth is turned off.');
      return;
    }

    // Start scanning
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _progressTimer?.cancel();
            _onScanTimeout();
          }
        });
      });

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          final name = r.device.platformName;
          final targetName = 'GOKUL_${widget.sessionId}';
          
          // Match the teacher's session BLE advertisement
          if (name == targetName || r.advertisementData.advName == targetName) {
            _onBeaconFound(r);
            break;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusText = 'Scan failed: $e';
      });
      widget.onVerificationComplete(false, 'Failed to initialize Bluetooth scan.');
    }
  }

  void _onBeaconFound(ScanResult result) async {
    _cleanup();
    setState(() {
      _isScanning = false;
      _foundRssi = result.rssi;
      _statusText = 'Teacher beacon found! Verifying proximity...';
    });

    final rssi = result.rssi;
    // Approximating distance based on RSSI: d = 10 ^ ((Measured Power - RSSI) / (10 * N))
    // N is path loss exponent (usually 2 to 4), Measured Power is RSSI at 1 meter (approx -59)
    final double estimatedDistance = double.parse(
      (double.tryParse((10.0 * (( -59 - rssi) / 20.0)).toStringAsFixed(2)) ?? 1.0)
          .toString(),
    );

    // Enforce range: RSSI must be stronger than -75 dBm (approx 5-6 meters indoors)
    if (rssi < -75) {
      widget.onVerificationComplete(
        false,
        'Teacher is too far away. Please get closer to the teacher desk.',
      );
      setState(() {
        _statusText = 'Proximity check failed (Signal too weak: $rssi dBm)';
      });
      return;
    }

    setState(() {
      _statusText = 'Proximity verified ($rssi dBm). Saving to server...';
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final profile = await supabaseService.getStudentProfile();
      final studentId = profile?['id']?.toString() ?? '';

      // Submit attendance check to Supabase database
      await supabaseService.submitBleProximityEvent(
        qrSessionId: widget.sessionId,
        teacherDeviceId: result.device.remoteId.str,
        studentDeviceId: 'STUDENT_MOBILE',
        studentId: studentId,
        rssi: rssi,
        estimatedDistanceM: estimatedDistance,
        isValid: true,
      );

      await supabaseService.markSmartAttendance(
        studentId: studentId,
        source: 'ble_proximity',
        status: 'present',
        qrSessionId: widget.sessionId,
        teacherDeviceId: result.device.remoteId.str,
        studentDeviceId: 'STUDENT_MOBILE',
        bleRssi: rssi,
        estimatedDistanceM: estimatedDistance,
        confidenceScore: 0.95,
      );

      setState(() {
        _verified = true;
        _statusText = 'Attendance marked successfully!';
      });
      widget.onVerificationComplete(true, 'Attendance verified in class.');
    } catch (e) {
      setState(() {
        _statusText = 'Failed to submit attendance: $e';
      });
      widget.onVerificationComplete(false, 'Database synchronization failed.');
    }
  }

  void _onScanTimeout() {
    _cleanup();
    setState(() {
      _isScanning = false;
      _statusText = 'Teacher beacon not found in proximity.';
    });
    widget.onVerificationComplete(
      false,
      'Could not detect teacher\'s Bluetooth signal. Please stand closer to the desk.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inkNavy800.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Smart Proximity Attendance',
            style: AppTypography.headingSm.copyWith(color: AppColors.goldCta),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: _isScanning ? _progress : (_verified ? 1.0 : 0.0),
                  strokeWidth: 8,
                  backgroundColor: AppColors.inkNavy700,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _verified
                        ? AppColors.success
                        : (_isScanning ? AppColors.goldCta : Colors.redAccent),
                  ),
                ),
              ),
              Icon(
                _verified
                    ? Icons.verified_rounded
                    : (_isScanning ? Icons.bluetooth_searching_rounded : Icons.bluetooth_disabled_rounded),
                size: 40,
                color: _verified
                    ? AppColors.success
                    : (_isScanning ? AppColors.goldShine : Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _statusText,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (_foundRssi != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inkNavy700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.signal_cellular_alt_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Signal Strength: $_foundRssi dBm',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
