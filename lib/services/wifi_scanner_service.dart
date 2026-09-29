import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_fingerprint.dart';

class WiFiScannerService {
  bool _canScan = false;
  bool enableWebSimulation = false; // Disabled by default so fake data doesn't pollute real survey
  final _fingerprintController = StreamController<WiFiFingerprint>.broadcast();
  Stream<WiFiFingerprint> get fingerprintStream => _fingerprintController.stream;

  bool get isHardwareSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get canScan => _canScan;

  WiFiScannerService() {
    _initScanner();
  }

  Future<void> _initScanner() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _canScan = false;
      return;
    }

    try {
      final can = await WiFiScan.instance.canStartScan();
      _canScan = (can == CanStartScan.yes);
    } catch (e) {
      _canScan = false;
    }
  }

  /// Scans all visible Wi-Fi access points and associates them with coordinate (x, y, floor)
  Future<WiFiFingerprint> scanAtLocation({
    required String floor,
    required double x,
    required double y,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<EwuWiFiSignal> detectedAPs = [];

    if (_canScan && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final startResult = await WiFiScan.instance.startScan();
        if (startResult) {
          final results = await WiFiScan.instance.getScannedResults();
          for (var ap in results) {
            // Noise floor filtering (drop < -85 dBm)
            if (ap.level >= -85 && ap.bssid.isNotEmpty) {
              detectedAPs.add(EwuWiFiSignal(
                bssid: ap.bssid,
                ssid: ap.ssid.isNotEmpty ? ap.ssid : 'Hidden AP',
                level: ap.level,
                frequency: ap.frequency,
                timestampMs: ap.timestamp ?? now,
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('WiFi Scan error: $e');
      }
    }

    // Only simulate if explicitly enabled for testing in web browsers/desktops
    if (detectedAPs.isEmpty && enableWebSimulation) {
      detectedAPs.addAll(_generateSimulatedAPs(floor, x, y, now));
    }

    final fingerprint = WiFiFingerprint(
      id: 'fp_${now}_${x.round()}_${y.round()}',
      floor: floor,
      x: x,
      y: y,
      timestampMs: now,
      accessPoints: detectedAPs,
    );

    _fingerprintController.add(fingerprint);
    return fingerprint;
  }

  List<EwuWiFiSignal> _generateSimulatedAPs(String floor, double x, double y, int now) {
    final int distRssi1 = (-45 - (x % 30).toInt()).clamp(-90, -35);
    final int distRssi2 = (-50 - (y % 25).toInt()).clamp(-90, -40);
    final int distRssi3 = (-60 - ((x + y) % 35).toInt()).clamp(-95, -55);

    return [
      EwuWiFiSignal(
        bssid: '00:1A:2B:3C:4D:01',
        ssid: 'EWU-WiFi',
        level: distRssi1,
        frequency: 5180,
        timestampMs: now,
      ),
      EwuWiFiSignal(
        bssid: '00:1A:2B:3C:4D:02',
        ssid: 'EWU-Faculty',
        level: distRssi2,
        frequency: 5240,
        timestampMs: now,
      ),
      EwuWiFiSignal(
        bssid: 'F4:8E:38:12:9A:88',
        ssid: 'EWU-Student',
        level: distRssi3,
        frequency: 2412,
        timestampMs: now,
      ),
    ];
  }

  void dispose() {
    _fingerprintController.close();
  }
}
