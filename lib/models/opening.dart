enum DoorType { hinged, sliding, revolving, folding, automatic, open, none }
enum AccessControl { open, keyCard, keyPad, biometric, manual, none }

class Opening {
  final String id;
  final String levelId;
  final String unitIdA;
  final String unitIdB;
  final DoorType doorType;
  final AccessControl accessControl;
  final double? clearWidthMeters;
  final double? thresholdHeightMm;
  final bool isAccessible;
  final bool isEmergencyExit;
  final String? photoPath;

  Opening({
    required this.id,
    required this.levelId,
    required this.unitIdA,
    required this.unitIdB,
    this.doorType = DoorType.hinged,
    this.accessControl = AccessControl.open,
    this.clearWidthMeters,
    this.thresholdHeightMm,
    this.isAccessible = true,
    this.isEmergencyExit = false,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'levelId': levelId,
    'unitIdA': unitIdA,
    'unitIdB': unitIdB,
    'doorType': doorType.name,
    'accessControl': accessControl.name,
    'clearWidthMeters': clearWidthMeters,
    'thresholdHeightMm': thresholdHeightMm,
    'isAccessible': isAccessible,
    'isEmergencyExit': isEmergencyExit,
    'photoPath': photoPath,
  };

  factory Opening.fromJson(Map<String, dynamic> json) => Opening(
    id: json['id'] as String,
    levelId: json['levelId'] as String,
    unitIdA: json['unitIdA'] as String,
    unitIdB: json['unitIdB'] as String,
    doorType: DoorType.values.firstWhere((e) => e.name == json['doorType'], orElse: () => DoorType.hinged),
    accessControl: AccessControl.values.firstWhere((e) => e.name == json['accessControl'], orElse: () => AccessControl.open),
    clearWidthMeters: (json['clearWidthMeters'] as num?)?.toDouble(),
    thresholdHeightMm: (json['thresholdHeightMm'] as num?)?.toDouble(),
    isAccessible: json['isAccessible'] == null ? true : (json['isAccessible'] == true || json['isAccessible'] == 1),
    isEmergencyExit: json['isEmergencyExit'] == true || json['isEmergencyExit'] == 1,
    photoPath: json['photoPath'] as String?,
  );
}
