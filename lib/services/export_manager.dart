import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';

class ExportManager {
  final SlamSurveyorEngine engine;

  ExportManager({required this.engine});

  Future<File?> exportIMDFArchive() async {
    if (!engine.hasActiveBuilding) return null;
    final survey = engine.activeSurvey!;

    final archive = Archive();

    // 1. Venue
    final venueFeature = {
      "type": "FeatureCollection",
      "features": [
        {
          "id": "${survey.name}_venue_id",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [survey.lng, survey.lat]
          },
          "properties": {
            "category": "university",
            "name": {"en": survey.name}
          }
        }
      ]
    };
    archive.addFile(ArchiveFile('venue.geojson', utf8.encode(jsonEncode(venueFeature)).length, utf8.encode(jsonEncode(venueFeature))));

    // 2. Levels
    final List<Map<String, dynamic>> levelFeatures = survey.floors.map((floor) => {
      "id": "${survey.name}_level_$floor",
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [] // We don't have footprint polygons yet
      },
      "properties": {
        "category": "level",
        "name": {"en": floor},
        "ordinal": survey.floors.indexOf(floor),
        "building_id": "${survey.name}_venue_id"
      }
    }).toList();
    
    final levelCollection = {
      "type": "FeatureCollection",
      "features": levelFeatures
    };
    archive.addFile(ArchiveFile('level.geojson', utf8.encode(jsonEncode(levelCollection)).length, utf8.encode(jsonEncode(levelCollection))));

    // Compress to Zip
    final zipEncoder = ZipEncoder();
    final List<int>? encodedZip = zipEncoder.encode(archive);
    if (encodedZip == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${survey.name}_imdf.zip');
    await file.writeAsBytes(encodedZip);
    return file;
  }

  Future<File?> exportGeoJSON() async {
    if (!engine.hasActiveBuilding) return null;
    final survey = engine.activeSurvey!;

    final List<Map<String, dynamic>> features = [];

    // Export edges as LineStrings
    for (var edge in survey.edges) {
      double? x1, y1, x2, y2;
      String floor1 = '', floor2 = '';

      final fromParts = edge.fromId.split('_');
      if (fromParts.length >= 4 && fromParts[0] == 'node') {
        floor1 = fromParts[1];
        x1 = double.tryParse(fromParts[2]);
        y1 = double.tryParse(fromParts[3]);
      } else {
        final roomMatches = survey.rooms.where((r) => r.id == edge.fromId);
        if (roomMatches.isNotEmpty) {
          x1 = roomMatches.first.x;
          y1 = roomMatches.first.y;
          floor1 = roomMatches.first.floor;
        }
      }

      final toParts = edge.toId.split('_');
      if (toParts.length >= 4 && toParts[0] == 'node') {
        floor2 = toParts[1];
        x2 = double.tryParse(toParts[2]);
        y2 = double.tryParse(toParts[3]);
      } else {
        final roomMatches = survey.rooms.where((r) => r.id == edge.toId);
        if (roomMatches.isNotEmpty) {
          x2 = roomMatches.first.x;
          y2 = roomMatches.first.y;
          floor2 = roomMatches.first.floor;
        }
      }

      if (x1 == null || y1 == null || x2 == null || y2 == null) {
        continue;
      }

      final geo1 = engine.geospatialService.calculatePosition(
        baseLat: survey.lat,
        baseLng: survey.lng,
        canvasX: x1,
        canvasY: y1,
        originCanvasX: survey.originX,
        originCanvasY: survey.originY,
        pixelsPerMeter: engine.config.pixelsPerMeter,
        floorName: floor1,
      );

      final geo2 = engine.geospatialService.calculatePosition(
        baseLat: survey.lat,
        baseLng: survey.lng,
        canvasX: x2,
        canvasY: y2,
        originCanvasX: survey.originX,
        originCanvasY: survey.originY,
        pixelsPerMeter: engine.config.pixelsPerMeter,
        floorName: floor2,
      );

      features.add({
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [geo1.longitude, geo1.latitude],
            [geo2.longitude, geo2.latitude]
          ]
        },
        "properties": {
          "type": edge.type,
          "isAccessible": edge.isAccessible,
          "passCount": edge.passCount,
          "distanceMeters": edge.distanceMeters,
          "widthMeters": edge.widthMeters,
          "runningSlopePercent": edge.runningSlopePercent,
          "crossSlopePercent": edge.crossSlopePercent,
          "surfaceType": edge.surfaceType,
          "hasTactilePaving": edge.hasTactilePaving
        }
      });
    }

    final featureCollection = {
      "type": "FeatureCollection",
      "features": features
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${survey.name}_edges.geojson');
    await file.writeAsString(jsonEncode(featureCollection));
    return file;
  }
}
