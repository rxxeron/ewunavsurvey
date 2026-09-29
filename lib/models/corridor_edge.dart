class CorridorEdge {
  final String fromId;
  final String toId;
  final double distanceMeters;
  final String type; // 'corridor', 'door', 'stair_vertical', 'lift_vertical'
  final bool isAccessible;

  CorridorEdge({
    required this.fromId,
    required this.toId,
    required this.distanceMeters,
    this.type = 'corridor',
    this.isAccessible = true,
  });

  Map<String, dynamic> toJson() => {
    'from': fromId,
    'to': toId,
    'distanceMeters': distanceMeters,
    'type': type,
    'isAccessible': isAccessible,
  };

  factory CorridorEdge.fromJson(Map<String, dynamic> json) => CorridorEdge(
    fromId: (json['from'] ?? json['fromId']) as String,
    toId: (json['to'] ?? json['toId']) as String,
    distanceMeters: (json['distanceMeters'] as num).toDouble(),
    type: json['type'] as String? ?? 'corridor',
    isAccessible: json['isAccessible'] is bool
        ? json['isAccessible'] as bool
        : (json['isAccessible'] == 1 || json['isAccessible'] == true),
  );
}
