import 'dart:math' as math;

enum ZoneCategory {
  courtyard,
  rooftop,
  hallway,
  lobby,
  cafeteria,
  auditorium,
  openSpace,
  custom;

  String get displayName {
    switch (this) {
      case ZoneCategory.courtyard:
        return '🌳 Courtyard';
      case ZoneCategory.rooftop:
        return '☀️ Rooftop';
      case ZoneCategory.hallway:
        return '🚶 Hallway / Corridor';
      case ZoneCategory.lobby:
        return '🏛️ Lobby / Plaza';
      case ZoneCategory.cafeteria:
        return '☕ Cafeteria / Canteen';
      case ZoneCategory.auditorium:
        return '🎭 Auditorium / Hall';
      case ZoneCategory.openSpace:
        return '🌿 Open Space';
      case ZoneCategory.custom:
        return '📦 Custom Zone';
    }
  }

  int get defaultFillColorInt {
    switch (this) {
      case ZoneCategory.courtyard:
        return 0x334CAF50; // translucent green
      case ZoneCategory.rooftop:
        return 0x33FFA726; // translucent amber
      case ZoneCategory.hallway:
        return 0x2664B5F6; // translucent light blue
      case ZoneCategory.lobby:
        return 0x33BA68C8; // translucent purple
      case ZoneCategory.cafeteria:
        return 0x33FF7043; // translucent orange
      case ZoneCategory.auditorium:
        return 0x3326A69A; // translucent teal
      case ZoneCategory.openSpace:
        return 0x3381C784; // translucent light green
      case ZoneCategory.custom:
        return 0x3378909C; // translucent blue-grey
    }
  }

  int get defaultStrokeColorInt {
    switch (this) {
      case ZoneCategory.courtyard:
        return 0xFF4CAF50;
      case ZoneCategory.rooftop:
        return 0xFFFFA726;
      case ZoneCategory.hallway:
        return 0xFF64B5F6;
      case ZoneCategory.lobby:
        return 0xFFBA68C8;
      case ZoneCategory.cafeteria:
        return 0xFFFF7043;
      case ZoneCategory.auditorium:
        return 0xFF26A69A;
      case ZoneCategory.openSpace:
        return 0xFF81C784;
      case ZoneCategory.custom:
        return 0xFF78909C;
    }
  }
}

class ZonePoint {
  final double x;
  final double y;

  const ZonePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory ZonePoint.fromJson(Map<String, dynamic> json) => ZonePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

class AreaZone {
  final String id;
  final String floor;
  String name;
  ZoneCategory category;
  List<ZonePoint> points;
  double areaSqMeters;
  String? colorHex;
  String? notes;
  List<String> boundaryNodeIds;

  AreaZone({
    required this.id,
    required this.floor,
    required this.name,
    required this.category,
    required this.points,
    required this.areaSqMeters,
    this.colorHex,
    this.notes,
    List<String>? boundaryNodeIds,
  }) : boundaryNodeIds = boundaryNodeIds ?? [];

  /// Calculates planar polygon area using the Shoelace formula (Gauss's area formula)
  static double calculateArea(List<ZonePoint> pts, double pixelsPerMeter) {
    if (pts.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      sum += (p1.x * p2.y) - (p2.x * p1.y);
    }
    final double areaPx = (sum.abs()) / 2.0;
    final double ppm2 = pixelsPerMeter * pixelsPerMeter;
    return areaPx / ppm2;
  }

  /// Calculates centroid (center of mass) of polygon
  ZonePoint get centroid {
    if (points.isEmpty) return const ZonePoint(400, 400);
    double sx = 0;
    double sy = 0;
    for (var p in points) {
      sx += p.x;
      sy += p.y;
    }
    return ZonePoint(sx / points.length, sy / points.length);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floor': floor,
        'name': name,
        'category': category.name,
        'points': points.map((p) => p.toJson()).toList(),
        'areaSqMeters': areaSqMeters,
        'colorHex': colorHex,
        'notes': notes,
        'boundaryNodeIds': boundaryNodeIds,
      };

  factory AreaZone.fromJson(Map<String, dynamic> json) => AreaZone(
        id: json['id'] as String,
        floor: json['floor'] as String,
        name: json['name'] as String,
        category: ZoneCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ZoneCategory.openSpace,
        ),
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => ZonePoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        areaSqMeters: (json['areaSqMeters'] as num?)?.toDouble() ?? 0.0,
        colorHex: json['colorHex'] as String?,
        notes: json['notes'] as String?,
        boundaryNodeIds: (json['boundaryNodeIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
