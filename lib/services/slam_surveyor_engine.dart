import 'dart:async';
import 'dart:math' as math;
import 'package:ewunavsurvey/models/survey_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../models/wifi_fingerprint.dart';
import '../models/step_log_record.dart';
import '../models/area_zone.dart';
import '../models/opening.dart';
import '../models/amenity.dart';
import 'pdr_engine.dart';
import 'compass_fusion_service.dart';
import 'wifi_scanner_service.dart';
import 'geospatial_service.dart';
import '../models/survey_corridor_point.dart';
import '../models/area_loop_candidate.dart';

import '../models/building_survey_data.dart';

class SlamSurveyorEngine extends ChangeNotifier {
  SurveyConfig config = const SurveyConfig();
  final PdrEngine pdrEngine;
  final CompassFusionService compassFusion;
  final WiFiScannerService wifiScanner;
  final GeospatialService geospatialService;

  final Map<String, BuildingSurveyData> _buildingSurveys = {};
  String? _currentBuildingName;

  double pixelsPerMeter = 28.0;
  void Function(StepLogRecord record)? onStepRecorded;
  StreamSubscription<StepEvent>? _stepSub;

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
    _stepSub = pdrEngine.stepStream.listen((event) {
      if (hasActiveBuilding && _isRecording) {
        _advanceOnFootstep(event.strideLengthMeters);
      }
    });
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    pdrEngine.dispose();
    compassFusion.dispose();
    super.dispose();
  }

  
  AreaLoopCandidate? pendingLoopCandidate;
  List<AreaZone> get zones => activeSurvey?.zones ?? [];
  List<Opening> get openings => activeSurvey?.openings ?? [];
  List<Amenity> get amenities => activeSurvey?.amenities ?? [];

  bool _showHeatmap = false;
  bool get showHeatmap => _showHeatmap;
  void toggleHeatmap() {
    _showHeatmap = !_showHeatmap;
    notifyListeners();
  }

  bool _isRecording = true;
  bool get isRecording => _isRecording;

  void pauseRecording() {
    _isRecording = false;
    notifyListeners();
  }

  void resumeRecording() {
    _isRecording = true;
    notifyListeners();
  }

  void toggleRecording() {
    _isRecording = !_isRecording;
    notifyListeners();
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
    final removedRoomIds = survey.rooms.where((r) => r.floor == floorName).map((r) => r.id).toSet();
    survey.rooms.removeWhere((r) => r.floor == floorName);

    // Remove edges connected to removed rooms or floor corridor nodes
    final floorPrefix = 'node_${floorName}_';
    survey.edges.removeWhere((e) =>
        removedRoomIds.contains(e.fromId) ||
        removedRoomIds.contains(e.toId) ||
        e.fromId.startsWith(floorPrefix) ||
        e.toId.startsWith(floorPrefix));

    survey.fingerprints.removeWhere((fp) => fp.floor == floorName);
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

  void notifyEngineUpdate() {
    notifyListeners();
  }

  /// Turn hallway corner (e.g. -90/-45 for Left, +45/+90 for Right, 180 for U-turn)
  void turn(double deltaDeg) {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;
    final raw = (survey.currentHeadingDeg + deltaDeg + 360) % 360;
    survey.currentHeadingDeg = compassFusion.snapHeading(raw);
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


    _checkLoopCandidate(survey);
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

  /// Tag a corridor dead end or wall boundary at current position
  RoomNode tagDeadEnd({String? note}) {
    if (!hasActiveBuilding) {
      throw StateError('Cannot tag dead end without an active building survey');
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

    final deadEndName = (note != null && note.trim().isNotEmpty)
        ? 'Dead End (${note.trim()})'
        : 'Dead End Wall';
    final deadEndId = 'dead_end_${survey.currentFloor.replaceAll(' ', '_')}_${survey.currentX.round()}_${survey.currentY.round()}';

    final deadEndNode = RoomNode(
      id: deadEndId,
      name: deadEndName,
      roomNumber: 'DEAD-END',
      floor: survey.currentFloor,
      category: RoomCategory.deadEnd,
      x: survey.currentX,
      y: survey.currentY,
      notes: note,
      latitude: geo.latitude,
      longitude: geo.longitude,
      altitudeMeters: geo.altitudeMeters,
      floorHeightMeters: geo.floorHeightMeters,
    );

    survey.rooms.add(deadEndNode);

    // Link dead end to the current corridor centerline
    final String hallNodeId = 'node_${survey.currentFloor}_${survey.currentX.round()}_${survey.currentY.round()}';
    survey.edges.add(CorridorEdge(
      fromId: hallNodeId,
      toId: deadEndId,
      distanceMeters: 0.5,
      type: 'corridor',
    ));

    // Automatically add note to the step log
    addCommentToCurrentStep('🚫 $deadEndName');

    notifyListeners();
    return deadEndNode;
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
      final lastPoint = survey.floorTrackPoints[survey.currentFloor]!.removeLast();
      final prev = survey.floorTrackPoints[survey.currentFloor]!.last;
      survey.currentX = prev.x;
      survey.currentY = prev.y;
      survey.currentHeadingDeg = prev.headingDeg;

      final String prevId = 'node_${survey.currentFloor}_${prev.x.round()}_${prev.y.round()}';
      final String lastId = 'node_${survey.currentFloor}_${lastPoint.x.round()}_${lastPoint.y.round()}';
      survey.edges.removeWhere((e) =>
          (e.fromId == prevId && e.toId == lastId) ||
          (e.fromId == lastId && e.toId == prevId));

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
  
  void _checkLoopCandidate(BuildingSurveyData survey) {
    final pts = survey.floorTrackPoints[survey.currentFloor];
    if (pts == null || pts.length < 8) return;
    final current = pts.last;

    // Check if current position is close to any point at least 6 steps ago
    for (int i = 0; i < pts.length - 6; i++) {
      final p = pts[i];
      final dx = current.x - p.x;
      final dy = current.y - p.y;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= 1.5 * pixelsPerMeter) {
        final subList = pts.sublist(i).map((pt) => ZonePoint(pt.x, pt.y)).toList();
        final area = AreaZone.calculateArea(subList, pixelsPerMeter);
        if (area >= 4.0) {
          pendingLoopCandidate = AreaLoopCandidate(
            points: subList,
            areaSqMeters: area,
            startIndex: i,
            endIndex: pts.length - 1,
          );
          break;
        }
      }
    }
  }

  /// Enclose detected loop into an AreaZone (Courtyard, Rooftop, Hallway, etc.)
  AreaZone enclosePendingLoop({
    required String name,
    required ZoneCategory category,
    String? notes,
  }) {
    if (!hasActiveBuilding || pendingLoopCandidate == null) {
      throw StateError('No pending loop to enclose');
    }
    final survey = activeSurvey!;
    final candidate = pendingLoopCandidate!;

    final zone = AreaZone(
      id: 'zone_${DateTime.now().millisecondsSinceEpoch}_${category.name}',
      floor: survey.currentFloor,
      name: name,
      category: category,
      points: List.from(candidate.points),
      areaSqMeters: candidate.areaSqMeters,
      notes: notes,
    );

    survey.zones.add(zone);
    pendingLoopCandidate = null;
    notifyListeners();
    return zone;
  }

  void dismissPendingLoop() {
    pendingLoopCandidate = null;
    notifyListeners();
  }

  AreaZone createManualZone({
    required String name,
    required ZoneCategory category,
    required List<ZonePoint> points,
    String? notes,
  }) {
    if (!hasActiveBuilding) {
      throw StateError('Cannot create zone without active building');
    }
    final survey = activeSurvey!;
    final area = AreaZone.calculateArea(points, pixelsPerMeter);

    final zone = AreaZone(
      id: 'zone_${DateTime.now().millisecondsSinceEpoch}_${category.name}',
      floor: survey.currentFloor,
      name: name,
      category: category,
      points: points,
      areaSqMeters: area,
      notes: notes,
    );

    survey.zones.add(zone);
    notifyListeners();
    return zone;
  }

  /// Connect two existing nodes with a corridor bridge edge (e.g. bridging outer & inner rings)
  CorridorEdge connectNodes({
    required String fromId,
    required String toId,
    double? distanceMeters,
  }) {
    if (!hasActiveBuilding) {
      throw StateError('No active building');
    }
    final survey = activeSurvey!;
    double dist = distanceMeters ?? 2.5;

    final r1 = survey.rooms.where((r) => r.id == fromId).firstOrNull;
    final r2 = survey.rooms.where((r) => r.id == toId).firstOrNull;
    if (r1 != null && r2 != null) {
      final dx = r1.x - r2.x;
      final dy = r1.y - r2.y;
      dist = math.sqrt(dx * dx + dy * dy) / pixelsPerMeter;
    }

    final edge = CorridorEdge(
      fromId: fromId,
      toId: toId,
      distanceMeters: dist > 0 ? dist : 2.5,
      type: 'corridor_bridge',
    );
    survey.edges.add(edge);
    notifyListeners();
    return edge;
  }

  void deleteZone(String zoneId) {
    if (!hasActiveBuilding) return;
    activeSurvey?.zones.removeWhere((z) => z.id == zoneId);
    notifyListeners();
  }

  
  
  Future<void> loadAzimuth() async {
    final prefs = await SharedPreferences.getInstance();
    final az = prefs.getDouble('azimuth_$currentBuilding');
    if (az != null) {
      compassFusion.setBuildingBaseline(az);
    } else {
      compassFusion.setBuildingBaseline(0.0);
    }
    notifyListeners();
  }

  Future<void> saveAzimuth(double newAzimuth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('azimuth_$currentBuilding', newAzimuth);
    compassFusion.setBuildingBaseline(newAzimuth);
    notifyListeners();
  }

  Future<void> loadKFactor() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getDouble('weinbergK_$currentBuilding');
    if (k != null) {
      pdrEngine.updateKFactor(k);
    } else {
      pdrEngine.updateKFactor(0.42); // Default
    }
    notifyListeners();
  }

  Future<void> saveKFactor(double newK) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weinbergK_$currentBuilding', newK);
    pdrEngine.updateKFactor(newK);
    notifyListeners();
  }

  void resetSurvey() {
    if (!hasActiveBuilding) return;
    final survey = activeSurvey!;

    survey.rooms.clear();
    survey.zones.clear();
    survey.openings.clear();
    survey.amenities.clear();
    pendingLoopCandidate = null;
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
            'zonesCount': survey.zones.length,
      'zones': survey.zones.map((z) => z.toJson()).toList(),
      'openings': survey.openings.map((o) => o.toJson()).toList(),
      'amenities': survey.amenities.map((a) => a.toJson()).toList(),
      'rooms': survey.rooms.map((r) => r.toJson()).toList(),
      'edges': survey.edges.map((e) => e.toJson()).toList(),
      'fingerprintsCount': survey.fingerprints.length,
      'rawWifiFingerprints': survey.fingerprints.map((f) => f.toJson()).toList(),
      'stepLogsCount': survey.stepLogs.length,
      'stepLogs': survey.stepLogs.map((s) => s.toJson()).toList(),
    };
  }
}
