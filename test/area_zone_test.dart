import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/area_zone.dart';

void main() {
  group('AreaZone Shoelace Area & Centroid Calculations', () {
    test('Calculates planar square area correctly using Shoelace formula', () {
      // 10m x 10m square at 20 pixels/meter => 200px x 200px = 40,000 px^2 / 400 = 100 m^2
      const double ppm = 20.0;
      final points = [
        const ZonePoint(0, 0),
        const ZonePoint(200, 0),
        const ZonePoint(200, 200),
        const ZonePoint(0, 200),
      ];

      final double area = AreaZone.calculateArea(points, ppm);
      expect(area, closeTo(100.0, 0.001));
    });

    test('Calculates right-triangle area correctly using Shoelace formula', () {
      // Base = 10m (200px), Height = 10m (200px) at 20 ppm => Area = 0.5 * 10 * 10 = 50 m^2
      const double ppm = 20.0;
      final points = [
        const ZonePoint(0, 0),
        const ZonePoint(200, 0),
        const ZonePoint(0, 200),
      ];

      final double area = AreaZone.calculateArea(points, ppm);
      expect(area, closeTo(50.0, 0.001));
    });

    test('Degenerate polygons with less than 3 vertices return 0.0 area', () {
      expect(AreaZone.calculateArea([], 20.0), 0.0);
      expect(AreaZone.calculateArea([const ZonePoint(10, 10)], 20.0), 0.0);
      expect(AreaZone.calculateArea([const ZonePoint(0, 0), const ZonePoint(100, 100)], 20.0), 0.0);
    });

    test('Calculates polygon centroid properly', () {
      final zone = AreaZone(
        id: 'zone_1',
        floor: 'Ground Floor',
        name: 'Central Courtyard',
        category: ZoneCategory.courtyard,
        points: const [
          ZonePoint(0, 0),
          ZonePoint(100, 0),
          ZonePoint(100, 100),
          ZonePoint(0, 100),
        ],
        areaSqMeters: 25.0,
      );

      final centroid = zone.centroid;
      expect(centroid.x, closeTo(50.0, 0.001));
      expect(centroid.y, closeTo(50.0, 0.001));
    });

    test('AreaZone JSON serialization round-trip', () {
      final original = AreaZone(
        id: 'zone_audit',
        floor: 'Floor 2',
        name: 'Auditorium A',
        category: ZoneCategory.auditorium,
        points: const [
          ZonePoint(10, 20),
          ZonePoint(50, 20),
          ZonePoint(50, 80),
        ],
        areaSqMeters: 45.5,
        colorHex: '#4CAF50',
        notes: 'Equipped with sound system and projector',
        boundaryNodeIds: ['node_1', 'node_2'],
      );

      final json = original.toJson();
      final restored = AreaZone.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.floor, original.floor);
      expect(restored.name, original.name);
      expect(restored.category, ZoneCategory.auditorium);
      expect(restored.points.length, 3);
      expect(restored.points[1].x, 50.0);
      expect(restored.areaSqMeters, 45.5);
      expect(restored.colorHex, '#4CAF50');
      expect(restored.boundaryNodeIds, ['node_1', 'node_2']);
    });
  });
}
