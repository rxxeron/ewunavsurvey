import 'faculty_member.dart';

enum RoomCategory {
  room, corridor, walkway, openSpace, elevator, escalator, 
  stairs, ramp, restroom, restroomMale, restroomFemale,
  serverRoom, parking, lobby, atrium, office, classroom,
  laboratory, library, auditorium, cafeteria, prayerRoom,
  storage, mechanical, electrical, utility, unspecified,
  // Legacy mappings for backward compatibility
  lab, facultyOffice, adminOffice, staircase, amenity, entrance, corridorJunction, deadEnd,
  custom
}

class RoomNode {
  final String id;
  String name;
  String? roomNumber;
  final String floor;
  RoomCategory category;
  String department;
  String? customCategoryName;
  int liftCount;
  int facultyCount;
  double x;
  double y;
  String doorSide; // 'left', 'right', 'straight'
  String doorType; // 'push', 'slide', 'push_glass', 'slide_glass', 'automatic_glass'
  String doorMaterial; // 'glass', 'wood', 'metal'
  int studentCapacity;
  bool isAccessible;
  List<FacultyMember> facultyMembers;
  String? notes;
  double? latitude;
  double? longitude;
  double? altitudeMeters;
  double? floorHeightMeters;
  String? photoPath;

  bool get isGlassDoor => doorMaterial == 'glass' || doorType.contains('glass');
  bool get isSlidingDoor => doorType.contains('slide') || doorType == 'sliding';

  RoomNode({
    required this.id,
    required this.name,
    this.roomNumber,
    required this.floor,
    required this.category,
    this.department = 'General',
    this.customCategoryName,
    this.liftCount = 1,
    this.facultyCount = 0,
    required this.x,
    required this.y,
    this.doorSide = 'straight',
    this.doorType = 'push',
    this.doorMaterial = 'wood',
    this.studentCapacity = 40,
    this.isAccessible = true,
    List<FacultyMember>? facultyMembers,
    this.notes,
    this.latitude,
    this.longitude,
    this.altitudeMeters,
    this.floorHeightMeters,
    this.photoPath,
  }) : facultyMembers = facultyMembers ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roomNumber': roomNumber,
    'floor': floor,
    'category': category.name,
    'department': department,
    'customCategoryName': customCategoryName,
    'liftCount': liftCount,
    'facultyCount': facultyCount,
    'x': x,
    'y': y,
    'doorSide': doorSide,
    'doorType': doorType,
    'doorMaterial': doorMaterial,
    'studentCapacity': studentCapacity,
    'isAccessible': isAccessible,
    'facultyMembers': facultyMembers.map((f) => f.toJson()).toList(),
    'notes': notes,
    'latitude': latitude,
    'longitude': longitude,
    'altitudeMeters': altitudeMeters,
    'floorHeightMeters': floorHeightMeters,
    'photoPath': photoPath,
  };

  factory RoomNode.fromJson(Map<String, dynamic> json) => RoomNode(
    id: json['id'] as String,
    name: json['name'] as String,
    roomNumber: json['roomNumber'] as String?,
    floor: json['floor'] as String,
    category: RoomCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => RoomCategory.classroom,
    ),
    department: json['department'] as String? ?? 'General',
    customCategoryName: json['customCategoryName'] as String?,
    liftCount: (json['liftCount'] as num?)?.toInt() ?? 1,
    facultyCount: (json['facultyCount'] as num?)?.toInt() ?? 0,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    doorSide: json['doorSide'] as String? ?? 'straight',
    doorType: json['doorType'] as String? ?? 'push',
    doorMaterial: json['doorMaterial'] as String? ?? 'wood',
    studentCapacity: (json['studentCapacity'] as num?)?.toInt() ?? 40,
    isAccessible: json['isAccessible'] == null 
        ? true 
        : (json['isAccessible'] == true || json['isAccessible'] == 1 || json['isAccessible'] == '1' || json['isAccessible'] == 'true'),
    facultyMembers: (json['facultyMembers'] as List<dynamic>?)
            ?.map((f) => FacultyMember.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
    floorHeightMeters: (json['floorHeightMeters'] as num?)?.toDouble(),
    photoPath: json['photoPath'] as String?,
  );
}
