class CorridorEdge {
  final String fromId;
  final String toId;
  final double distanceMeters;
  final String type; // 'corridor', 'door', 'stair_vertical', 'lift_vertical'
  final bool isAccessible;
  final double? widthMeters;
  final double? runningSlopePercent;
  final double? crossSlopePercent;
  final String? surfaceType;
  final bool hasTactilePaving;
  final int passCount;

  CorridorEdge({
    required this.fromId,
    required this.toId,
    required this.distanceMeters,
    this.type = 'corridor',
    this.isAccessible = true,
    this.widthMeters,
    this.runningSlopePercent,
    this.crossSlopePercent,
    this.surfaceType,
    this.hasTactilePaving = false,
    this.passCount = 1,
  });

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'toId': toId,
    'distanceMeters': distanceMeters,
    'type': type,
    'isAccessible': isAccessible,
    'widthMeters': widthMeters,
    'runningSlopePercent': runningSlopePercent,
    'crossSlopePercent': crossSlopePercent,
    'surfaceType': surfaceType,
    'hasTactilePaving': hasTactilePaving,
    'passCount': passCount,
  };

  factory CorridorEdge.fromJson(Map<String, dynamic> json) => CorridorEdge(
    fromId: (json['from'] ?? json['fromId']) as String,
    toId: (json['to'] ?? json['toId']) as String,
    distanceMeters: (json['distanceMeters'] as num).toDouble(),
    type: json['type'] as String? ?? 'corridor',
    isAccessible: json['isAccessible'] == null ? true
        : (json['isAccessible'] is bool ? json['isAccessible'] as bool : json['isAccessible'] == 1),
    widthMeters: (json['widthMeters'] as num?)?.toDouble(),
    runningSlopePercent: (json['runningSlopePercent'] as num?)?.toDouble(),
    crossSlopePercent: (json['crossSlopePercent'] as num?)?.toDouble(),
    surfaceType: json['surfaceType'] as String?,
    hasTactilePaving: json['hasTactilePaving'] == true || json['hasTactilePaving'] == 1,
    passCount: (json['passCount'] as num?)?.toInt() ?? 1,
  );
}
