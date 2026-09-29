import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepEvent {
  final int stepCount;
  final double strideLengthMeters;
  final double totalDistanceMeters;
  final int timestampMs;

  StepEvent({
    required this.stepCount,
    required this.strideLengthMeters,
    required this.totalDistanceMeters,
    required this.timestampMs,
  });
}

class PdrEngine {
  double strideLengthMeters = 0.75;
  double _weinbergK = 0.42; // Dynamic K-factor
  double get weinbergK => _weinbergK;
  int _stepCount = 0;
  double _totalDistanceMeters = 0.0;

  // IIR low-pass filter states
  double _smoothedZ = 0.0;
  double _lastPeakZ = 0.0;
  double _lastValleyZ = 0.0;
  bool _isPeak = false;
  int _lastStepTimeMs = 0;

  // Filter coefficient (0.85 smooths out tremors)
  final double alpha = 0.85;
  // Step detection thresholds
  final double peakThreshold = 1.25;  // m/s^2 above gravity
  final double valleyThreshold = -0.20; // m/s^2 below gravity
  final int minRefractoryMs = 280;     // Max human cadence ~3.5 steps/sec

  final _stepController = StreamController<StepEvent>.broadcast();
  Stream<StepEvent> get stepStream => _stepController.stream;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isHardwareActive = false;
  bool get isHardwareActive => _isHardwareActive;

  PdrEngine({bool enableHardwareSensors = false, double initialK = 0.42}) {
    _weinbergK = initialK;
    if (enableHardwareSensors && !kIsWeb) {
      startHardwareSensors();
    }
  }

  void startHardwareSensors() {
    if (kIsWeb) return;
    _accelSub?.cancel();
    _isHardwareActive = true;
    _accelSub = accelerometerEventStream().listen((event) {
      processAccelerometerSample(
        event.x,
        event.y,
        event.z,
        DateTime.now().millisecondsSinceEpoch,
      );
    }, onError: (e) {
      debugPrint('Accelerometer sensor error: $e');
      _isHardwareActive = false;
    });
  }

  void stopHardwareSensors() {
    _accelSub?.cancel();
    _accelSub = null;
    _isHardwareActive = false;
  }

  int get stepCount => _stepCount;
  double get totalDistanceMeters => _totalDistanceMeters;

  void processAccelerometerSample(double ax, double ay, double az, int timestampMs) {
    // Total acceleration magnitude minus standard Earth gravity (9.81 m/s^2)
    final double rawMagnitude = math.sqrt(ax * ax + ay * ay + az * az) - 9.80665;

    // Apply IIR Low-Pass Filter
    _smoothedZ = (alpha * _smoothedZ) + ((1.0 - alpha) * rawMagnitude);

    // Peak and valley detection
    if (_smoothedZ > peakThreshold && !_isPeak) {
      _isPeak = true;
      _lastPeakZ = _smoothedZ;
    } else if (_isPeak && _smoothedZ > _lastPeakZ) {
      _lastPeakZ = _smoothedZ;
    } else if (_smoothedZ < valleyThreshold && _isPeak) {
      // Step cycle completed (foot planted)
      final int now = timestampMs;
      if (now - _lastStepTimeMs >= minRefractoryMs) {
        _lastStepTimeMs = now;
        _isPeak = false;
        _lastValleyZ = _smoothedZ;

        // Dynamic Weinberg Stride Length Estimation
        // L = K * (a_max - a_min)^(1/4)
        final double accelDiff = math.max(0.1, _lastPeakZ - _lastValleyZ);
        final double estimatedStride = math.min(1.1, math.max(0.5, _weinbergK * math.pow(accelDiff, 0.25)));
        final double stepLength = (strideLengthMeters > 0) ? strideLengthMeters : estimatedStride;

        _stepCount++;
        _totalDistanceMeters += stepLength;

        _stepController.add(StepEvent(
          stepCount: _stepCount,
          strideLengthMeters: stepLength,
          totalDistanceMeters: _totalDistanceMeters,
          timestampMs: now,
        ));
      }
    }
  }

  /// Allows manual stepping (for simulation, testing, or surveyor thumb button)
  void recordManualStep([double? customStride]) {
    final double stride = customStride ?? strideLengthMeters;
    _stepCount++;
    _totalDistanceMeters += stride;

    _stepController.add(StepEvent(
      stepCount: _stepCount,
      strideLengthMeters: stride,
      totalDistanceMeters: _totalDistanceMeters,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void decrementStep([double? customStride]) {
    if (_stepCount > 0) {
      final double stride = customStride ?? strideLengthMeters;
      _stepCount--;
      _totalDistanceMeters = math.max(0.0, _totalDistanceMeters - stride);
    }
  }

  void reset() {
    _stepCount = 0;
    _totalDistanceMeters = 0.0;
    _smoothedZ = 0.0;
    _isPeak = false;
    _lastStepTimeMs = 0;
  }

  void dispose() {
    _accelSub?.cancel();
    _stepController.close();
  }

  void updateKFactor(double newK) {
    _weinbergK = newK;
  }
}
