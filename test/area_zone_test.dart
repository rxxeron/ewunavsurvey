import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/area_zone.dart';
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';
import 'package:ewunavsurvey/services/pdr_engine.dart';
import 'package:ewunavsurvey/services/compass_fusion_service.dart';
import 'package:ewunavsurvey/services/wifi_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Shoelace area accurately calculates area of a 10m x 10m courtyard square', () {
    const double ppm = 28.0; // 28 pixels per meter
    // A 10m x 10m square = 100 sq meters
    final points = [
      const ZonePoint(0.0, 0.0),
      const ZonePoint(10.0 * ppm, 0.0),
      const ZonePoint(10.0 * ppm, 10.0 * ppm),
      const ZonePoint(0.0, 10.0 * ppm),
    ];

    final area = AreaZone.calculateArea(points, ppm);
    expect(area, closeTo(100.0, 0.001));

    final zone = AreaZone(
      id: 'zone_test_courtyard',
      floor: 'Ground Floor',
      name: 'Main Courtyard',
      category: ZoneCategory.courtyard,
      points: points,
      areaSqMeters: area,
    );

    expect(zone.centroid.x, closeTo(5.0 * ppm, 0.001));
    expect(zone.centroid.y, closeTo(5.0 * ppm, 0.001));
  });

  test('SlamSurveyorEngine manages AreaZones cleanly across floors', () {
    final engine = SlamSurveyorEngine(
      pdrEngine: PdrEngine(),
      compassFusion: CompassFusionService(),
      wifiScanner: WiFiScannerService(),
    );

    engine.createBuilding(name: 'Main Campus Building');
    expect(engine.zones.length, 0);

    const double ppm = 28.0;
    final points = [
      const ZonePoint(400.0, 400.0),
      const ZonePoint(400.0 + 8.0 * ppm, 400.0),
      const ZonePoint(400.0 + 8.0 * ppm, 400.0 + 6.0 * ppm),
      const ZonePoint(400.0, 400.0 + 6.0 * ppm),
    ];

    final zone = engine.createManualZone(
      name: 'Central Green',
      category: ZoneCategory.courtyard,
      points: points,
      notes: 'Grass lawn with fountain',
    );

    expect(engine.zones.length, 1);
    expect(zone.name, 'Central Green');
    expect(zone.areaSqMeters, closeTo(48.0, 0.01)); // 8m x 6m = 48 m²

    // Export graph test
    final graph = engine.exportGraphJson();
    expect(graph['zonesCount'], 1);
    expect((graph['zones'] as List).first['name'], 'Central Green');

    // Deletion test
    engine.deleteZone(zone.id);
    expect(engine.zones.length, 0);
  });
}
