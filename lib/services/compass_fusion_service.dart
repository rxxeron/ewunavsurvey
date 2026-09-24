import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CompassFusionService {
  double _currentHeadingDeg = 0.0;
  double _buildingBaselineDeg = 0.0;
  bool _isMagneticAnomaly = false;
  double _lastMagneticFieldUt = 45.0;

  // Earth's standard field intensity: 45 uT (+/- 15 uT)
  static const double minCleanFieldUt = 30.0;
  static const double maxCleanFieldUt = 62.0;

  final _headingController = StreamController<double>.broadcast();
  Stream<double> get headingStream => _headingController.stream;

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  int _lastGyroTimeMs = 0;
  bool _isHardwareActive = false;
  bool get isHardwareActive => _isHardwareActive;

  CompassFusionService({bool enableHardwareSensors = false}) {
    if (enableHardwareSensors && !kIsWeb) {
      startHardwareSensors();
    }
  }

  void startHardwareSensors() {
    if (kIsWeb) return;
    _magSub?.cancel();
    _gyroSub?.cancel();
    _isHardwareActive = true;

    _magSub = magnetometerEventStream().listen((event) {
      processMagnetometerSample(event.x, event.y, event.z);
    }, onError: (e) {
      debugPrint('Magnetometer error: $e');
      _isHardwareActive = false;
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastGyroTimeMs > 0) {
        final dt = (now - _lastGyroTimeMs) / 1000.0;
        if (dt > 0 && dt < 1.0) {
          processGyroscopeSample(event.z, dt);
        }
      }
      _lastGyroTimeMs = now;
    }, onError: (e) {
      debugPrint('Gyroscope error: $e');
    });
  }

  void stopHardwareSensors() {
    _magSub?.cancel();
    _gyroSub?.cancel();
    _magSub = null;
    _gyroSub = null;
    _isHardwareActive = false;
  }

  double get currentHeadingDeg => _currentHeadingDeg;
  double get buildingBaselineDeg => _buildingBaselineDeg;
  bool get isMagneticAnomaly => _isMagneticAnomaly;
  double get magneticFieldUt => _lastMagneticFieldUt;

  /// Initializes building alignment baseline from initial reading
  void setBuildingBaseline(double headingDeg) {
    _buildingBaselineDeg = (headingDeg % 360 + 360) % 360;
  }

  /// Process raw Magnetometer event (bx, by, bz in microteslas)
  void processMagnetometerSample(double bx, double by, double bz) {
    _lastMagneticFieldUt = math.sqrt(bx * bx + by * by + bz * bz);

    // Check for magnetic distortion (e.g. near elevators or steel beams)
    if (_lastMagneticFieldUt < minCleanFieldUt || _lastMagneticFieldUt > maxCleanFieldUt) {
      _isMagneticAnomaly = true;
    } else {
      _isMagneticAnomaly = false;
    }

    // Compass raw azimuth from x, y
    double azimuthRad = math.atan2(by, bx);
    double azimuthDeg = (azimuthRad * 180 / math.pi + 360) % 360;

    if (!_isMagneticAnomaly) {
      // Complementary fusion: smoothly nudge toward clean compass heading
      final double diff = _angleDifference(azimuthDeg, _currentHeadingDeg);
      _currentHeadingDeg = (_currentHeadingDeg + 0.05 * diff + 360) % 360;
      _headingController.add(_currentHeadingDeg);
    }
  }

  /// Process raw Gyroscope angular velocity (rad/s around Z-axis)
  void processGyroscopeSample(double gyroZ, double dtSeconds) {
    // Integrate angular velocity: delta_theta = omega * dt
    final double deltaDeg = (gyroZ * 180 / math.pi) * dtSeconds;
    _currentHeadingDeg = (_currentHeadingDeg + deltaDeg + 360) % 360;
    _headingController.add(_currentHeadingDeg);
  }

  /// Snaps current heading to the nearest orthogonal Manhattan corridor axis (0, 90, 180, 270)
  /// relative to the building's baseline orientation.
  double getSnappedOrthogonalHeading() {
    final double relativeAngle = (_currentHeadingDeg - _buildingBaselineDeg + 360) % 360;
    final int quadrant = (relativeAngle / 90.0).round() % 4;
    return (_buildingBaselineDeg + quadrant * 90.0 + 360) % 360;
  }

  double _angleDifference(double target, double current) {
    double diff = (target - current + 180) % 360 - 180;
    return diff < -180 ? diff + 360 : diff;
  }

  void dispose() {
    _magSub?.cancel();
    _gyroSub?.cancel();
    _headingController.close();
  }
}
