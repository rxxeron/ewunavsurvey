import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeospatialReading {
  final double latitude;
  final double longitude;
  final double altitudeMeters;
  final double floorHeightMeters;
  final double gpsAccuracyMeters;
  final bool isGpsFix;

  GeospatialReading({
    required this.latitude,
    required this.longitude,
    required this.altitudeMeters,
    required this.floorHeightMeters,
    required this.gpsAccuracyMeters,
    required this.isGpsFix,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitudeMeters': altitudeMeters,
    'floorHeightMeters': floorHeightMeters,
    'gpsAccuracyMeters': gpsAccuracyMeters,
    'isGpsFix': isGpsFix,
  };
}

class GeospatialService extends ChangeNotifier {
  Position? _latestGpsPosition;
  StreamSubscription<Position>? _positionSub;
  bool _isGpsActive = false;

  Position? get latestGpsPosition => _latestGpsPosition;
  bool get isGpsActive => _isGpsActive;

  // Ground elevation of EWU Aftabnagar, Dhaka campus (~7.5m above sea level)
  static const double ewuBaseElevationMsl = 7.5;
  static const double floorHeightIncrementMeters = 4.2; // standard floor vertical height

  static const Map<String, double> floorElevations = {
    'Basement 2': -7.0,
    'Basement': -3.5,
    'Ground Floor': 0.0,
    '1st Floor': 4.2,
    '2nd Floor': 8.4,
    '3rd Floor': 12.6,
    '4th Floor': 16.8,
    '5th Floor': 21.0,
    '6th Floor': 25.2,
    '7th Floor': 29.4,
    '8th Floor': 33.6,
    '9th Floor': 37.8,
    '10th Floor': 42.0,
    'Rooftop': 46.2,
  };

  GeospatialService() {
    _startGpsListener();
  }

  Future<void> _startGpsListener() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Try initial position fix
      _latestGpsPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 5),
        ),
      ).catchError((_) => null as dynamic);

      if (_latestGpsPosition != null) {
        _isGpsActive = true;
        notifyListeners();
      }

      // Stream ongoing location updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1, // update every meter moved
        ),
      ).listen(
        (pos) {
          _latestGpsPosition = pos;
          _isGpsActive = true;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Geolocator stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('GeospatialService initialization error: $e');
    }
  }

  /// Calculates the vertical floor elevation (relative to campus ground level)
  double getFloorHeightMeters(String floorName) {
    if (floorElevations.containsKey(floorName)) {
      return floorElevations[floorName]!;
    }
    // Attempt parsing "Nth Floor"
    final match = RegExp(r'(\d+)').firstMatch(floorName);
    if (match != null) {
      final floorNum = int.tryParse(match.group(1)!) ?? 0;
      return floorNum * floorHeightIncrementMeters;
    }
    return 0.0;
  }

  /// Calculates accurate high-precision 3D geospatial coordinate:
  /// Combines GPS fix (if available) with dead-reckoned Cartesian projection from building base anchor.
  GeospatialReading calculatePosition({
    required double baseLat,
    required double baseLng,
    required double canvasX,
    required double canvasY,
    required double originCanvasX,
    required double originCanvasY,
    required double pixelsPerMeter,
    required String floorName,
  }) {
    final floorHeight = getFloorHeightMeters(floorName);

    // If active high-accuracy GPS fix is available outdoors/near windows with < 8m accuracy
    if (_latestGpsPosition != null && _latestGpsPosition!.accuracy <= 8.0) {
      return GeospatialReading(
        latitude: _latestGpsPosition!.latitude,
        longitude: _latestGpsPosition!.longitude,
        altitudeMeters: _latestGpsPosition!.altitude > 0
            ? _latestGpsPosition!.altitude
            : (ewuBaseElevationMsl + floorHeight),
        floorHeightMeters: floorHeight,
        gpsAccuracyMeters: _latestGpsPosition!.accuracy,
        isGpsFix: true,
      );
    }

    // High-precision Cartesian projection for indoor navigation
    // Canvas X is Easting (+dx), Canvas Y is Southing (+dy)
    final double dxMeters = (canvasX - originCanvasX) / pixelsPerMeter;
    final double dyMeters = (canvasY - originCanvasY) / pixelsPerMeter;

    // 1 deg Lat ~ 111,139 meters
    final double dLat = -dyMeters / 111139.0;
    // 1 deg Lng ~ 111,139 * cos(lat) meters
    final double dLng = dxMeters / (111139.0 * math.cos(baseLat * (math.pi / 180.0)));

    final double projLat = baseLat + dLat;
    final double projLng = baseLng + dLng;

    final double altitude = (_latestGpsPosition != null && _latestGpsPosition!.altitude > 0)
        ? (_latestGpsPosition!.altitude)
        : (ewuBaseElevationMsl + floorHeight);

    return GeospatialReading(
      latitude: projLat,
      longitude: projLng,
      altitudeMeters: altitude,
      floorHeightMeters: floorHeight,
      gpsAccuracyMeters: _latestGpsPosition?.accuracy ?? 1.5,
      isGpsFix: false,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
