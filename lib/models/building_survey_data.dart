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
    this.currentHeadingDeg = 0.0,
  })  : floors = List<String>.from(floors),
        currentFloor = currentFloor ?? (floors.isNotEmpty ? floors.first : 'Ground Floor'),
        currentX = originX,
        currentY = originY,
        floorTrackPoints = {for (final f in floors) f: []},
        rooms = [],
        edges = [],
        fingerprints = [],
        stepLogs = [],
        zones = [],
        openings = [],
        amenities = [];
}
