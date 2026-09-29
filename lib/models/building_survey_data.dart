import 'area_zone.dart';
import 'corridor_edge.dart';
import 'opening.dart';
import 'room_node.dart';
import 'step_log_record.dart';
import 'survey_corridor_point.dart';
import 'wifi_fingerprint.dart';
import 'amenity.dart';

class BuildingSurveyData {
  final String name;
  final double lat;
  final double lng;
  final List<String> floors;
  String currentFloor;
  final double originX;
  final double originY;
  double currentX;
  double currentY;
  double currentHeadingDeg;
  final Map<String, List<SurveyCorridorPoint>> floorTrackPoints;
  final List<RoomNode> rooms;
  final List<CorridorEdge> edges;
  final List<WiFiFingerprint> fingerprints;
  final List<StepLogRecord> stepLogs;
  final List<AreaZone> zones;
  final List<Opening> openings;
  final List<Amenity> amenities;

  BuildingSurveyData({
    required this.name,
    required this.lat,
    required this.lng,
    required List<String> floors,
    String? currentFloor,
    this.originX = 400.0,
    this.originY = 400.0,
    this.currentX = 400.0,
    this.currentY = 400.0,
    this.currentHeadingDeg = 0.0,
    Map<String, List<SurveyCorridorPoint>>? floorTrackPoints,
    List<RoomNode>? rooms,
    List<CorridorEdge>? edges,
    List<WiFiFingerprint>? fingerprints,
    List<StepLogRecord>? stepLogs,
    List<AreaZone>? zones,
    List<Opening>? openings,
    List<Amenity>? amenities,
  })  : floors = List<String>.from(floors),
        currentFloor = currentFloor ?? (floors.isNotEmpty ? floors.first : 'Ground Floor'),
        floorTrackPoints = floorTrackPoints ?? {for (final f in floors) f: []},
        rooms = rooms ?? [],
        edges = edges ?? [],
        fingerprints = fingerprints ?? [],
        stepLogs = stepLogs ?? [],
        zones = zones ?? [],
        openings = openings ?? [],
        amenities = amenities ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'floors': floors,
      'currentFloor': currentFloor,
      'originX': originX,
      'originY': originY,
      'currentX': currentX,
      'currentY': currentY,
      'currentHeadingDeg': currentHeadingDeg,
      'floorTrackPoints': floorTrackPoints.map((k, v) => MapEntry(k, v.map((p) => p.toJson()).toList())),
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'fingerprints': fingerprints.map((f) => f.toJson()).toList(),
      'stepLogs': stepLogs.map((s) => s.toJson()).toList(),
      'zones': zones.map((z) => z.toJson()).toList(),
      'openings': openings.map((o) => o.toJson()).toList(),
      'amenities': amenities.map((a) => a.toJson()).toList(),
    };
  }

  factory BuildingSurveyData.fromJson(Map<String, dynamic> json) {
    return BuildingSurveyData(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      floors: (json['floors'] as List).map((e) => e.toString()).toList(),
      currentFloor: json['currentFloor'] as String?,
      originX: (json['originX'] as num).toDouble(),
      originY: (json['originY'] as num).toDouble(),
      currentX: (json['currentX'] as num?)?.toDouble() ?? 400.0,
      currentY: (json['currentY'] as num?)?.toDouble() ?? 400.0,
      currentHeadingDeg: (json['currentHeadingDeg'] as num).toDouble(),
      floorTrackPoints: (json['floorTrackPoints'] as Map<String, dynamic>).map((k, v) => MapEntry(
            k,
            (v as List).map((p) => SurveyCorridorPoint.fromJson(p as Map<String, dynamic>)).toList(),
          )),
      rooms: (json['rooms'] as List).map((r) => RoomNode.fromJson(r as Map<String, dynamic>)).toList(),
      edges: (json['edges'] as List).map((e) => CorridorEdge.fromJson(e as Map<String, dynamic>)).toList(),
      fingerprints: (json['fingerprints'] as List).map((f) => WiFiFingerprint.fromJson(f as Map<String, dynamic>)).toList(),
      stepLogs: (json['stepLogs'] as List).map((s) => StepLogRecord.fromJson(s as Map<String, dynamic>)).toList(),
      zones: (json['zones'] as List).map((z) => AreaZone.fromJson(z as Map<String, dynamic>)).toList(),
      openings: (json['openings'] as List).map((o) => Opening.fromJson(o as Map<String, dynamic>)).toList(),
      amenities: (json['amenities'] as List).map((a) => Amenity.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}
