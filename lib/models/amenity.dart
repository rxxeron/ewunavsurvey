enum AmenityCategory {
  restroom, waterFountain, fireExtinguisher, aed, atm,
  vendingMachine, informationDesk, securityDesk, 
  chargingStation, prayerRoom, firstAid, parking,
  bicycleParking, elevator, escalator, unspecified
}

class Amenity {
  final String id;
  final String levelId;
  final String unitId;
  final AmenityCategory category;
  final String? name;
  final double x;
  final double y;
  final bool isAccessible;

  Amenity({
    required this.id,
    required this.levelId,
    required this.unitId,
    required this.category,
    this.name,
    required this.x,
    required this.y,
    this.isAccessible = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'levelId': levelId,
    'unitId': unitId,
    'category': category.name,
    'name': name,
    'x': x,
    'y': y,
    'isAccessible': isAccessible,
  };

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    id: json['id'] as String,
    levelId: json['levelId'] as String,
    unitId: json['unitId'] as String,
    category: AmenityCategory.values.firstWhere((e) => e.name == json['category'], orElse: () => AmenityCategory.unspecified),
    name: json['name'],
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    isAccessible: json['isAccessible'] == null ? true : (json['isAccessible'] == true || json['isAccessible'] == 1),
  );
}
