import 'dart:math' as math;

/// Single Bluetooth Low Energy (BLE) beacon detection sample (iBeacon / Eddystone).
class BleBeaconSignal {
  final String macAddress;
  final String? uuid;
  final int? major;
  final int? minor;
  final int rssi; // RSSI in dBm (e.g. -72)
  final int txPower; // Calibrated TX power at 1m (default -59 dBm)
  final int timestampMs;

  BleBeaconSignal({
    required this.macAddress,
    this.uuid,
    this.major,
    this.minor,
    required this.rssi,
    this.txPower = -59,
    required this.timestampMs,
  });

  /// Estimates physical distance to beacon in meters using log-distance path loss model.
  double get estimatedDistanceMeters {
    if (rssi == 0) return -1.0;
    final ratio = (txPower - rssi) / (10.0 * 2.2); // n = 2.2 indoor path loss exponent
    return math.pow(10.0, ratio).toDouble();
  }

  Map<String, dynamic> toJson() => {
    'macAddress': macAddress,
    'uuid': uuid,
    'major': major,
    'minor': minor,
    'rssi': rssi,
    'txPower': txPower,
    'estimatedDistanceMeters': estimatedDistanceMeters,
    'timestampMs': timestampMs,
  };

  factory BleBeaconSignal.fromJson(Map<String, dynamic> json) => BleBeaconSignal(
    macAddress: json['macAddress'] as String,
    uuid: json['uuid'] as String?,
    major: (json['major'] as num?)?.toInt(),
    minor: (json['minor'] as num?)?.toInt(),
    rssi: (json['rssi'] as num).toInt(),
    txPower: (json['txPower'] as num?)?.toInt() ?? -59,
    timestampMs: (json['timestampMs'] as num).toInt(),
  );
}

/// Aggregated multi-beacon BLE fingerprint at a surveyed coordinate.
class BleFingerprint {
  final String id;
  final String floor;
  final double x;
  final double y;
  final int timestampMs;
  final List<BleBeaconSignal> beacons;

  BleFingerprint({
    required this.id,
    required this.floor,
    required this.x,
    required this.y,
    required this.timestampMs,
    required this.beacons,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'floor': floor,
    'x': x,
    'y': y,
    'timestampMs': timestampMs,
    'beacons': beacons.map((b) => b.toJson()).toList(),
  };

  factory BleFingerprint.fromJson(Map<String, dynamic> json) => BleFingerprint(
    id: json['id'] as String,
    floor: json['floor'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    timestampMs: (json['timestampMs'] as num).toInt(),
    beacons: (json['beacons'] as List<dynamic>?)
            ?.map((b) => BleBeaconSignal.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
