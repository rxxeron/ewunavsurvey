class EwuWiFiSignal {
  final String bssid;
  final String ssid;
  final int level; // RSSI in dBm (e.g. -65)
  final int frequency; // MHz (e.g. 2412 or 5180)
  final int timestampMs;

  EwuWiFiSignal({
    required this.bssid,
    required this.ssid,
    required this.level,
    required this.frequency,
    required this.timestampMs,
  });

  Map<String, dynamic> toJson() => {
    'bssid': bssid,
    'ssid': ssid,
    'level': level,
    'frequency': frequency,
    'timestampMs': timestampMs,
  };

  factory EwuWiFiSignal.fromJson(Map<String, dynamic> json) => EwuWiFiSignal(
    bssid: json['bssid'] as String,
    ssid: json['ssid'] as String? ?? 'Hidden',
    level: (json['level'] as num).toInt(),
    frequency: (json['frequency'] as num).toInt(),
    timestampMs: (json['timestampMs'] as num).toInt(),
  );
}

class WiFiFingerprint {
  final String id;
  final String floor;
  final double x;
  final double y;
  final int timestampMs;
  final List<EwuWiFiSignal> accessPoints;

  WiFiFingerprint({
    required this.id,
    required this.floor,
    required this.x,
    required this.y,
    required this.timestampMs,
    required this.accessPoints,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'floor': floor,
    'x': x,
    'y': y,
    'timestampMs': timestampMs,
    'accessPoints': accessPoints.map((ap) => ap.toJson()).toList(),
  };

  factory WiFiFingerprint.fromJson(Map<String, dynamic> json) => WiFiFingerprint(
    id: json['id'] as String,
    floor: json['floor'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    timestampMs: (json['timestampMs'] as num).toInt(),
    accessPoints: (json['accessPoints'] as List<dynamic>)
        .map((ap) => EwuWiFiSignal.fromJson(ap as Map<String, dynamic>))
        .toList(),
  );
}
