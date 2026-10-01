import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/opening.dart';
import 'package:ewunavsurvey/models/amenity.dart';
import 'package:ewunavsurvey/models/corridor_edge.dart';
import 'package:ewunavsurvey/models/room_node.dart';

void main() {
  group('IMDF Data Models & ADA Compliance Serialization', () {
    test('Opening door entity models ADA clear width, threshold height, and fire exits', () {
      final door = Opening(
        id: 'door_101',
        levelId: 'level_gf',
        unitIdA: 'room_101',
        unitIdB: 'corridor_main',
        doorType: DoorType.automatic,
        accessControl: AccessControl.keyCard,
        clearWidthMeters: 0.95,
        thresholdHeightMm: 8.0,
        isEmergencyExit: true,
        isAccessible: true,
      );

      final json = door.toJson();
      final fromJson = Opening.fromJson(json);

      expect(fromJson.id, 'door_101');
      expect(fromJson.levelId, 'level_gf');
      expect(fromJson.unitIdA, 'room_101');
      expect(fromJson.unitIdB, 'corridor_main');
      expect(fromJson.doorType, DoorType.automatic);
      expect(fromJson.accessControl, AccessControl.keyCard);
      expect(fromJson.clearWidthMeters, 0.95);
      expect(fromJson.thresholdHeightMm, 8.0);
      expect(fromJson.isEmergencyExit, isTrue);
      expect(fromJson.isAccessible, isTrue);
    });

    test('Amenity entity models POIs, categories, and accessibility', () {
      final amenity = Amenity(
        id: 'amenity_aed',
        levelId: 'level_1',
        unitId: 'corridor_north',
        category: AmenityCategory.aed,
        name: 'Automated External Defibrillator',
        x: 220.0,
        y: 180.0,
        isAccessible: true,
      );

      final json = amenity.toJson();
      final fromJson = Amenity.fromJson(json);

      expect(fromJson.id, 'amenity_aed');
      expect(fromJson.levelId, 'level_1');
      expect(fromJson.unitId, 'corridor_north');
      expect(fromJson.category, AmenityCategory.aed);
      expect(fromJson.name, 'Automated External Defibrillator');
      expect(fromJson.x, 220.0);
      expect(fromJson.y, 180.0);
      expect(fromJson.isAccessible, isTrue);
    });

    test('CorridorEdge models ADA slopes, clear width, tactile paving, and multi-pass count', () {
      final edge = CorridorEdge(
        fromId: 'node_a',
        toId: 'node_b',
        distanceMeters: 12.5,
        type: 'corridor',
        isAccessible: true,
        widthMeters: 1.8,
        runningSlopePercent: 4.5,
        crossSlopePercent: 1.2,
        surfaceType: 'concrete_polished',
        hasTactilePaving: true,
        passCount: 3,
      );

      final json = edge.toJson();
      final fromJson = CorridorEdge.fromJson(json);

      expect(fromJson.fromId, 'node_a');
      expect(fromJson.toId, 'node_b');
      expect(fromJson.distanceMeters, 12.5);
      expect(fromJson.widthMeters, 1.8);
      expect(fromJson.runningSlopePercent, 4.5);
      expect(fromJson.crossSlopePercent, 1.2);
      expect(fromJson.surfaceType, 'concrete_polished');
      expect(fromJson.hasTactilePaving, isTrue);
      expect(fromJson.passCount, 3);
    });

    test('RoomNode supports expanded OGC IMDF room categories', () {
      final lab = RoomNode(
        id: 'room_ece_lab',
        name: 'Hardware Lab',
        floor: 'Floor 3',
        category: RoomCategory.laboratory,
        x: 100,
        y: 150,
      );

      final prayerRoom = RoomNode(
        id: 'room_prayer',
        name: 'Prayer Hall',
        floor: 'Floor 2',
        category: RoomCategory.prayerRoom,
        x: 80,
        y: 90,
      );

      expect(lab.category, RoomCategory.laboratory);
      expect(prayerRoom.category, RoomCategory.prayerRoom);

      final labJson = lab.toJson();
      final restoredLab = RoomNode.fromJson(labJson);
      expect(restoredLab.category, RoomCategory.laboratory);
      expect(restoredLab.name, 'Hardware Lab');
    });

    test('Push, slide, and glass door mechanisms serialize accurately with door materials', () {
      final glassDoor = Opening(
        id: 'door_glass_slide',
        levelId: 'level_3',
        unitIdA: 'room_lab_301',
        unitIdB: 'corridor_3',
        doorType: DoorType.slideGlass,
        doorMaterial: DoorMaterial.glass,
        accessControl: AccessControl.open,
        clearWidthMeters: 1.2,
      );

      final json = glassDoor.toJson();
      final restored = Opening.fromJson(json);

      expect(restored.doorType, DoorType.slideGlass);
      expect(restored.doorMaterial, DoorMaterial.glass);
      expect(restored.clearWidthMeters, 1.2);

      final facultyRoom = RoomNode(
        id: 'faculty_401',
        name: 'Prof. Office 401',
        floor: '4th Floor',
        category: RoomCategory.facultyOffice,
        x: 350.0,
        y: 220.0,
        doorType: 'pushGlass',
        doorMaterial: 'glass',
      );

      expect(facultyRoom.doorType, 'pushGlass');
      expect(facultyRoom.doorMaterial, 'glass');
      expect(facultyRoom.isGlassDoor, isTrue);
      expect(facultyRoom.isSlidingDoor, isFalse);

      final restoredRoom = RoomNode.fromJson(facultyRoom.toJson());
      expect(restoredRoom.doorType, 'pushGlass');
      expect(restoredRoom.doorMaterial, 'glass');
      expect(restoredRoom.isGlassDoor, isTrue);
    });
  });
}
