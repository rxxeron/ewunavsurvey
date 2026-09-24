import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../models/wifi_fingerprint.dart';
import '../models/step_log_record.dart';
import 'pdr_engine.dart';
import 'compass_fusion_service.dart';
import 'wifi_scanner_service.dart';
import 'geospatial_service.dart';

class SurveyCorridorPoint {
  final double x;
  final double y;
  final String floor;
  final double headingDeg;

  SurveyCorridorPoint({
    required this.x,
    required this.y,
    required this.floor,
    required this.headingDeg,
  });
}

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
        stepLogs = [];
}

class SlamSurveyorEngine extends ChangeNotifier {
  final PdrEngine pdrEngine;
  final CompassFusionService compassFusion;
  final WiFiScannerService wifiScanner;
  final GeospatialService geospatialService;

  final Map<String, BuildingSurveyData> _buildingSurveys = {};
  String? _currentBuildingName;

  double pixelsPerMeter = 28.0;
  void Function(StepLogRecord record)? onStepRecorded;

  // Active portal state (for stair/elevator multi-floor transition)
  String? activePortalId;
  String? activePortalType; // 'stair' or 'lift'
  double? activePortalX;
  double? activePortalY;

  SlamSurveyorEngine({
    required this.pdrEngine,
    required this.compassFusion,
    required this.wifiScanner,
    GeospatialService? geospatialService,
  }) : geospatialService = geospatialService ?? GeospatialService() {
    // Listen to physical footsteps from PDR
    pdrEngine.stepStream.listen((event) {
      if (hasActiveBuilding) {
        _advanceOnFootstep(event.strideLengthMeters);
      }
    });
  }

  bool get hasActiveBuilding =>
      _currentBuildingName != null && _buildingSurveys.containsKey(_currentBuildingName);

  List<String> get availableBuildings => _buildingSurveys.keys.toList();

  BuildingSurveyData? get activeSurvey =>
      hasActiveBuilding ? _buildingSurveys[_currentBuildingName] : null;

  String get currentBuilding => activeSurvey?.name ?? '';
  double get currentBuildingLat => activeSurvey?.lat ?? 23.7684;
  double get currentBuildingLng => activeSurvey?.lng ?? 90.4258;
  String get currentFloor => activeSurvey?.currentFloor ?? '';
  List<String> get availableFloors =>
      activeSurvey != null ? List.unmodifiable(activeSurvey!.floors) : const [];

  double get currentX => activeSurvey?.currentX ?? 400.0;
  set currentX(double val) {
    if (activeSurvey != null) activeSurvey!.currentX = val;
  }

  double get currentY => activeSurvey?.currentY ?? 400.0;
  set currentY(double val) {
    if (activeSurvey != null) activeSurvey!.currentY = val;
  }

  double get currentHeadingDeg => activeSurvey?.currentHeadingDeg ?? 0.0;
  set currentHeadingDeg(double val) {
    if (activeSurvey != null) activeSurvey!.currentHeadingDeg = val;
  }

  double get originX => activeSurvey?.originX ?? 400.0;
  double get originY => activeSurvey?.originY ?? 400.0;

  Map<String, List<SurveyCorridorPoint>> get floorTrackPoints =>
      activeSurvey?.floorTrackPoints ?? {};

  List<RoomNode> get rooms => activeSurvey?.rooms ?? [];
  List<CorridorEdge> get edges => activeSurvey?.edges ?? [];
  List<WiFiFingerprint> get fingerprints => activeSurvey?.fingerprints ?? [];
  List<StepLogRecord> get stepLogs => activeSurvey?.stepLogs ?? [];

  /// Create a new building survey from scratch
  void createBuilding({
    required String name,
    double lat = 23.7684,
    double lng = 90.4258,
    String initialFloor = 'Ground Floor',
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final cleanFloor = initialFloor.trim().isEmpty ? 'Ground Floor' : initialFloor.trim();
    final data = BuildingSurveyData(
      name: cleanName,
      lat: lat,
      lng: lng,
      floors: [cleanFloor],
      currentFloor: cleanFloor,
    );

    _buildingSurveys[cleanName] = data;
    _currentBuildingName = cleanName;

    _addTrackPointFor(data);
    _initStartStepFor(data);
    notifyListeners();
  }

  /// Select an existing building to switch active survey plan
  void selectBuilding(String name) {
    if (_buildingSurveys.containsKey(name)) {
      _currentBuildingName = name;
      notifyListeners();
    }
  }

  /// Delete an entire building survey
  void deleteBuilding(String name) {
    _buildingSurveys.remove(name);
    if (_currentBuildingName == name) {
      _currentBuildingName = _buildingSurveys.keys.isNotEmpty ? _buildingSurveys.keys.first : null;
    }
    notifyListeners();
  }

  /// Backward-compatible setBuilding method
  void setBuilding({
    required String name,
    required double lat,
    required double lng,
    List<String>? floors,
  }) {
    if (!_buildingSurveys.containsKey(name)) {
      final initialFloors = (floors != null && floors.isNotEmpty) ? floors : ['Ground Floor'];
      final data = BuildingSurveyData(
        name: name,
        lat: lat,
        lng: lng,
        floors: initialFloors,
        currentFloor: initialFloors.first,
      );
      _buildingSurveys[name] = data;
      _currentBuildingName = name;
      _addTrackPointFor(data);
      _initStartStepFor(data);
    } else {
      _currentBuildingName = name;
      final data = _buildingSurveys[name]!;
      if (floors != null) {
        for (final f in floors) {
          if (!data.floors.contains(f)) {
            data.floors.add(f);
            data.floorTrackPoints[f] = [];
          }
        }
      }
    }
    notifyListeners();
  }

  /// Add a new floor one by one to the active building
  void addCustomFloor(String floorName) {
    if (!hasActiveBuilding) return;
    final clean = floorName.trim();
    if (clean.isEmpty) return;

    final survey = activeSurvey!;
    if (!survey.floors.contains(clean)) {
      survey.floors.add(clean);
      survey.floorTrackPoints[clean] = [];
    }
    setFloor(clean);
  }

  /// Delete a specific floor from the active building
  void deleteFloor(String floorName) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;
    if (survey.floors.length <= 1) {
      // Must keep at least one floor
      return;
    }

    survey.floors.remove(floorName);
    survey.floorTrackPoints.remove(floorName);
    survey.rooms.removeWhere((r) => r.floor == floorName);
    // Remove edges connected to removed rooms
    final remainingRoomIds = survey.rooms.map((r) => r.id).toSet();
    survey.edges.removeWhere((e) =>
        (e.type == 'door' && (!remainingRoomIds.contains(e.fromId) && !remainingRoomIds.contains(e.toId))));
    survey.stepLogs.removeWhere((s) => s.floor == floorName);

    if (survey.currentFloor == floorName) {
      setFloor(survey.floors.first);
    } else {
      notifyListeners();
    }
  }

  /// Switch floor on active building
  void setFloor(String floorName) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    if (!survey.floors.contains(floorName)) {
      survey.floors.add(floorName);
      survey.floorTrackPoints[floorName] = [];
    }

    survey.currentFloor = floorName;
    survey.floorTrackPoints[floorName] ??= [];

    final pts = survey.floorTrackPoints[floorName]!;
    if (pts.isNotEmpty) {
      survey.currentX = pts.last.x;
      survey.currentY = pts.last.y;
      survey.currentHeadingDeg = pts.last.headingDeg;
    } else {
      survey.currentX = survey.originX;
      survey.currentY = survey.originY;
      survey.currentHeadingDeg = 0.0;
      _addTrackPointFor(survey);
    }
    notifyListeners();
  }

  void _initStartStepFor(BuildingSurveyData survey) {
    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: survey.currentX,
      canvasY: survey.currentY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final startStep = StepLogRecord(
      stepIndex: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      floor: survey.currentFloor,
      x: survey.currentX,
      y: survey.currentY,
      headingDeg: survey.currentHeadingDeg,
      strideMeters: 0.0,
      comment: 'Survey Started for ${survey.name}',
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
      gpsAccuracyMeters: geo.gpsAccuracyMeters,
    );
    survey.stepLogs.add(startStep);
    onStepRecorded?.call(startStep);

    wifiScanner.scanAtLocation(
      floor: survey.currentFloor,
      x: survey.currentX,
      y: survey.currentY,
    ).then((fp) {
      survey.fingerprints.add(fp);
      startStep.wifiSignals.addAll(fp.accessPoints);
    });
  }

  void _addTrackPointFor(BuildingSurveyData survey) {
    survey.floorTrackPoints[survey.currentFloor] ??= [];
    survey.floorTrackPoints[survey.currentFloor]!.add(SurveyCorridorPoint(
      x: survey.currentX,
      y: survey.currentY,
      floor: survey.currentFloor,
      headingDeg: survey.currentHeadingDeg,
    ));
  }

  void _addTrackPoint() {
    if (activeSurvey != null) {
      _addTrackPointFor(activeSurvey!);
    }
  }

  void notifyEngineUpdate() {
    notifyListeners();
  }

  /// Turn hallway corner (e.g. -90 for Left, +90 for Right, 180 for U-turn)
  void turn(double deltaDeg) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;
    survey.currentHeadingDeg = (survey.currentHeadingDeg + deltaDeg + 360) % 360;
    // Snap strictly to 0, 90, 180, 270 (Manhattan assumption)
    survey.currentHeadingDeg = (survey.currentHeadingDeg / 90.0).round() * 90.0 % 360;
    _addTrackPointFor(survey);
    notifyListeners();
  }

  void _advanceOnFootstep(double strideMeters) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    final double distPx = strideMeters * pixelsPerMeter;
    final double rad = (survey.currentHeadingDeg - 90) * (math.pi / 180.0);

    final double nextX = survey.currentX + math.cos(rad) * distPx;
    final double nextY = survey.currentY + math.sin(rad) * distPx;

    final String fromId = 'node_${survey.currentFloor}_${survey.currentX.round()}_${survey.currentY.round()}';
    final String toId = 'node_${survey.currentFloor}_${nextX.round()}_${nextY.round()}';

    survey.edges.add(CorridorEdge(
      fromId: fromId,
      toId: toId,
      distanceMeters: strideMeters,
      type: 'corridor',
    ));

    survey.currentX = nextX;
    survey.currentY = nextY;
    _addTrackPointFor(survey);

    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: survey.currentX,
      canvasY: survey.currentY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final stepLog = StepLogRecord(
      stepIndex: pdrEngine.stepCount,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      floor: survey.currentFloor,
      x: survey.currentX,
      y: survey.currentY,
      headingDeg: survey.currentHeadingDeg,
      strideMeters: strideMeters,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
      gpsAccuracyMeters: geo.gpsAccuracyMeters,
    );
    survey.stepLogs.add(stepLog);
    onStepRecorded?.call(stepLog);

    wifiScanner.scanAtLocation(
      floor: survey.currentFloor,
      x: survey.currentX,
      y: survey.currentY,
    ).then((fp) {
      survey.fingerprints.add(fp);
      stepLog.wifiSignals.addAll(fp.accessPoints);
    });

    notifyListeners();
  }

  void addCommentToCurrentStep(String comment) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    if (survey.stepLogs.isNotEmpty) {
      final lastLog = survey.stepLogs.last;
      final updatedLog = StepLogRecord(
        stepIndex: lastLog.stepIndex,
        timestampMs: lastLog.timestampMs,
        floor: lastLog.floor,
        x: lastLog.x,
        y: lastLog.y,
        headingDeg: lastLog.headingDeg,
        strideMeters: lastLog.strideMeters,
        comment: comment,
        latitude: lastLog.latitude,
        longitude: lastLog.longitude,
        altitudeMeters: lastLog.altitudeMeters,
        floorHeightMeters: lastLog.floorHeightMeters,
        gpsAccuracyMeters: lastLog.gpsAccuracyMeters,
        wifiSignals: lastLog.wifiSignals,
      );
      survey.stepLogs[survey.stepLogs.length - 1] = updatedLog;
      onStepRecorded?.call(updatedLog);
    } else {
      final geo = geospatialService.calculatePosition(
        baseLat: survey.lat,
        baseLng: survey.lng,
        canvasX: survey.currentX,
        canvasY: survey.currentY,
        originCanvasX: survey.originX,
        originCanvasY: survey.originY,
        pixelsPerMeter: pixelsPerMeter,
        floorName: survey.currentFloor,
      );
      final startLog = StepLogRecord(
        stepIndex: 0,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        floor: survey.currentFloor,
        x: survey.currentX,
        y: survey.currentY,
        headingDeg: survey.currentHeadingDeg,
        strideMeters: 0.0,
        comment: comment,
        latitude: geo.latitude,
        longitude: geo.longitude,
        altitudeMeters: geo.altitudeMeters,
        floorHeightMeters: geo.floorHeightMeters,
        gpsAccuracyMeters: geo.gpsAccuracyMeters,
      );
      survey.stepLogs.add(startLog);
      onStepRecorded?.call(startLog);
    }
    notifyListeners();
  }

  void manualStep([double? stride]) {
    pdrEngine.recordManualStep(stride);
  }

  /// Tag a room door along the corridor (offset left or right perpendicular to heading)
  RoomNode markRoomDoor({
    required String name,
    String? roomNumber,
    RoomCategory category = RoomCategory.classroom,
    String department = 'General',
    String doorSide = 'left',
    int capacity = 40,
    List<dynamic>? faculty,
  }) {
    if (!hasActiveBuilding) {
      throw StateError('Cannot mark room door without an active building survey');
    }
    final survey = activeSurvey!;

    double doorAngle = survey.currentHeadingDeg;
    if (doorSide == 'left') {
      doorAngle = (survey.currentHeadingDeg - 90 + 360) % 360;
    } else if (doorSide == 'right') {
      doorAngle = (survey.currentHeadingDeg + 90) % 360;
    }

    final double rad = (doorAngle - 90) * (math.pi / 180.0);
    final double doorOffsetPx = 1.2 * pixelsPerMeter;
    final double doorX = survey.currentX + math.cos(rad) * doorOffsetPx;
    final double doorY = survey.currentY + math.sin(rad) * doorOffsetPx;

    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: doorX,
      canvasY: doorY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final String roomId = 'room_${DateTime.now().millisecondsSinceEpoch}_${doorX.round()}';

    final room = RoomNode(
      id: roomId,
      name: name,
      roomNumber: roomNumber ?? name,
      floor: survey.currentFloor,
      category: category,
      department: department,
      x: doorX,
      y: doorY,
      doorSide: doorSide,
      studentCapacity: capacity,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
    );

    survey.rooms.add(room);

    final String hallNodeId = 'node_${survey.currentFloor}_${survey.currentX.round()}_${survey.currentY.round()}';
    survey.edges.add(CorridorEdge(
      fromId: hallNodeId,
      toId: roomId,
      distanceMeters: 1.2,
      type: 'door',
    ));

    notifyListeners();
    return room;
  }

  /// Tag a staircase or elevator landmark at the current position without changing floors
  RoomNode tagVerticalPortalLandmark({
    required String name,
    required String portalType,
  }) {
    if (!hasActiveBuilding) {
      throw StateError('Cannot tag portal without an active building survey');
    }
    final survey = activeSurvey!;

    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: survey.currentX,
      canvasY: survey.currentY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final portalId = 'portal_${name.replaceAll(' ', '_')}_${portalType}_${survey.currentFloor.replaceAll(' ', '_')}';
    final portalNode = RoomNode(
      id: portalId,
      name: name,
      roomNumber: name,
      floor: survey.currentFloor,
      category: portalType == 'stair' ? RoomCategory.staircase : RoomCategory.elevator,
      x: survey.currentX,
      y: survey.currentY,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
    );

    survey.rooms.add(portalNode);

    // Link staircase to the current corridor centerline
    final String hallNodeId = 'node_${survey.currentFloor}_${survey.currentX.round()}_${survey.currentY.round()}';
    survey.edges.add(CorridorEdge(
      fromId: hallNodeId,
      toId: portalId,
      distanceMeters: 0.8,
      type: 'portal_entrance',
    ));

    notifyListeners();
    return portalNode;
  }

  /// Enter a Vertical Portal (Staircase or Elevator) with 3D elevation capture
  void enterVerticalPortal({
    required String name,
    required String portalType,
  }) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    activePortalId = 'portal_${name.replaceAll(' ', '_')}_$portalType';
    activePortalType = portalType;
    activePortalX = survey.currentX;
    activePortalY = survey.currentY;

    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: survey.currentX,
      canvasY: survey.currentY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final portalNode = RoomNode(
      id: '${activePortalId}_${survey.currentFloor.replaceAll(' ', '_')}',
      name: name,
      roomNumber: name,
      floor: survey.currentFloor,
      category: portalType == 'stair' ? RoomCategory.staircase : RoomCategory.elevator,
      x: survey.currentX,
      y: survey.currentY,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
    );
    survey.rooms.add(portalNode);

    final String hallNodeId = 'node_${survey.currentFloor}_${survey.currentX.round()}_${survey.currentY.round()}';
    survey.edges.add(CorridorEdge(
      fromId: hallNodeId,
      toId: portalNode.id,
      distanceMeters: 0.8,
      type: 'portal_entrance',
    ));

    notifyListeners();
  }

  /// Exit Vertical Portal on a new floor with 3D vertical elevation connection
  void exitVerticalPortal({required String targetFloor}) {
    if (!hasActiveBuilding || activePortalX == null || activePortalY == null) return;
    final survey = activeSurvey!;

    final String oldFloor = survey.currentFloor;

    if (!survey.floors.contains(targetFloor)) {
      survey.floors.add(targetFloor);
      survey.floorTrackPoints[targetFloor] = [];
    }

    survey.currentFloor = targetFloor;
    survey.currentX = activePortalX!;
    survey.currentY = activePortalY!;

    final geo = geospatialService.calculatePosition(
      baseLat: survey.lat,
      baseLng: survey.lng,
      canvasX: survey.currentX,
      canvasY: survey.currentY,
      originCanvasX: survey.originX,
      originCanvasY: survey.originY,
      pixelsPerMeter: pixelsPerMeter,
      floorName: survey.currentFloor,
    );

    final newPortalNode = RoomNode(
      id: '${activePortalId}_${survey.currentFloor.replaceAll(' ', '_')}',
      name: activePortalId!,
      roomNumber: activePortalId!,
      floor: survey.currentFloor,
      category: activePortalType == 'stair' ? RoomCategory.staircase : RoomCategory.elevator,
      x: survey.currentX,
      y: survey.currentY,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
    );
    survey.rooms.add(newPortalNode);

    // Calculate vertical distance between floor elevations
    final double h1 = geospatialService.getFloorHeightMeters(oldFloor);
    final double h2 = geospatialService.getFloorHeightMeters(targetFloor);
    final double verticalDelta = (h2 - h1).abs();

    final String oldNodeId = '${activePortalId}_${oldFloor.replaceAll(' ', '_')}';
    final String newNodeId = '${activePortalId}_${survey.currentFloor.replaceAll(' ', '_')}';

    survey.edges.add(CorridorEdge(
      fromId: oldNodeId,
      toId: newNodeId,
      distanceMeters: verticalDelta > 0 ? verticalDelta : 4.2,
      type: activePortalType == 'stair' ? 'stair_vertical' : 'lift_vertical',
    ));

    activePortalId = null;
    activePortalX = null;
    activePortalY = null;

    _addTrackPointFor(survey);
    notifyListeners();
  }

  /// Undo last step or landmark on active building
  void undo() {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    if (survey.rooms.isNotEmpty && survey.rooms.last.floor == survey.currentFloor) {
      final removed = survey.rooms.removeLast();
      survey.edges.removeWhere((e) => e.fromId == removed.id || e.toId == removed.id);
    } else if (survey.floorTrackPoints[survey.currentFloor] != null &&
        survey.floorTrackPoints[survey.currentFloor]!.length > 1) {
      survey.floorTrackPoints[survey.currentFloor]!.removeLast();
      final prev = survey.floorTrackPoints[survey.currentFloor]!.last;
      survey.currentX = prev.x;
      survey.currentY = prev.y;
      survey.currentHeadingDeg = prev.headingDeg;
      if (survey.edges.isNotEmpty) survey.edges.removeLast();
      if (survey.stepLogs.isNotEmpty) {
        survey.stepLogs.removeLast();
        pdrEngine.decrementStep();
      }
    }
    notifyListeners();
  }

  /// Delete a specific room/landmark entry and its connecting edges
  void deleteRoom(String roomId) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;
    survey.rooms.removeWhere((r) => r.id == roomId);
    survey.edges.removeWhere((e) => e.fromId == roomId || e.toId == roomId);
    notifyListeners();
  }

  /// Delete a specific step log entry
  void deleteStepLog(int stepIndex) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;
    survey.stepLogs.removeWhere((s) => s.stepIndex == stepIndex);
    notifyListeners();
  }

  /// Reset survey state for the active building
  void resetSurvey() {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    survey.rooms.clear();
    survey.edges.clear();
    survey.fingerprints.clear();
    survey.stepLogs.clear();
    for (final key in survey.floorTrackPoints.keys) {
      survey.floorTrackPoints[key]!.clear();
    }
    survey.currentX = survey.originX;
    survey.currentY = survey.originY;
    survey.currentHeadingDeg = 0.0;
    pdrEngine.reset();
    _addTrackPointFor(survey);
    _initStartStepFor(survey);
    notifyListeners();
  }

  /// Export master database to campus_graph.json
  Map<String, dynamic> exportGraphJson() {
    if (!hasActiveBuilding) {
      return {
        'version': '2.0-survey',
        'buildings': [],
      };
    }
    final survey = activeSurvey!;
    return {
      'version': '2.0-survey',
      'building': survey.name,
      'buildingLat': survey.lat,
      'buildingLng': survey.lng,
      'pixelsPerMeter': pixelsPerMeter,
      'floors': survey.floors,
      'rooms': survey.rooms.map((r) => r.toJson()).toList(),
      'edges': survey.edges.map((e) => e.toJson()).toList(),
      'fingerprintsCount': survey.fingerprints.length,
      'rawWifiFingerprints': survey.fingerprints.map((f) => f.toJson()).toList(),
      'stepLogsCount': survey.stepLogs.length,
      'stepLogs': survey.stepLogs.map((s) => s.toJson()).toList(),
    };
  }
}
