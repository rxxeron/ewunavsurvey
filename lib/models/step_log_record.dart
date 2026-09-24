import 'wifi_fingerprint.dart';

class StepLogRecord {
  final int stepIndex;
  final int timestampMs;
  final String floor;
  final double x;
  final double y;
  final double headingDeg;
  final double strideMeters;
  final String? comment;
  final double? latitude;
  final double? longitude;
  final double? altitudeMeters;
  final double? floorHeightMeters;
  final double? gpsAccuracyMeters;
  final List<EwuWiFiSignal> wifiSignals;

  StepLogRecord({
    required this.stepIndex,
    required this.timestampMs,
    required this.floor,
    required this.x,
    required this.y,
    required this.headingDeg,
    required this.strideMeters,
    this.comment,
    this.latitude,
    this.longitude,
    this.altitudeMeters,
    this.floorHeightMeters,
    this.gpsAccuracyMeters,
    List<EwuWiFiSignal>? wifiSignals,
  }) : wifiSignals = wifiSignals ?? [];

  Map<String, dynamic> toJson() => {
    'stepIndex': stepIndex,
    'timestampMs': timestampMs,
    'floor': floor,
    'x': x,
    'y': y,
    'headingDeg': headingDeg,
    'strideMeters': strideMeters,
    'comment': comment,
    'latitude': latitude,
    'longitude': longitude,
    'altitudeMeters': altitudeMeters,
    'floorHeightMeters': floorHeightMeters,
    'gpsAccuracyMeters': gpsAccuracyMeters,
    'wifiSignals': wifiSignals.map((w) => w.toJson()).toList(),
  };

  factory StepLogRecord.fromJson(Map<String, dynamic> json) => StepLogRecord(
    stepIndex: json['stepIndex'] as int,
    timestampMs: json['timestampMs'] as int,
    floor: json['floor'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    headingDeg: (json['headingDeg'] as num).toDouble(),
    strideMeters: (json['strideMeters'] as num).toDouble(),
    comment: json['comment'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
    floorHeightMeters: (json['floorHeightMeters'] as num?)?.toDouble(),
    gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num?)?.toDouble(),
    wifiSignals: (json['wifiSignals'] as List<dynamic>?)
            ?.map((w) => EwuWiFiSignal.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
