import 'package:flutter/material.dart';
import '../../services/slam_surveyor_engine.dart';
import '../../services/loop_closure_optimizer.dart';
import '../../services/db_service.dart';
import 'surveyor_canvas.dart';
import 'thumb_action_bar.dart';
import 'workbench_dock.dart';
import 'floor_selector_bar.dart';
import 'faculty_room_modal.dart';
import 'portal_transfer_modal.dart';
import 'wifi_telemetry_sheet.dart';
import 'overlays/telemetry_hud.dart';
import 'overlays/loop_candidate_banner.dart';
import 'dialogs/add_building_dialog.dart';
import 'dialogs/complete_floor_dialog.dart';
import 'dialogs/enclose_zone_dialog.dart';
import 'dialogs/schema_viewer.dart';
import 'dialogs/dead_end_dialog.dart';
import 'dialogs/step_comment_dialog.dart';
import 'dialogs/export_summary_dialog.dart';
import 'dialogs/export_dialog.dart';
import 'dialogs/azimuth_alignment_dialog.dart';
import 'dialogs/stride_calibration_dialog.dart';
import 'dialogs/corridor_properties_dialog.dart';
import 'dialogs/door_properties_dialog.dart';
import '../../models/opening.dart';

import '../../repositories/survey_repository.dart';

class SurveyorScreen extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final SurveyRepository repository;

  const SurveyorScreen({
    super.key,
    required this.engine,
    required this.dbService,
    required this.repository,
  });

  @override
  State<SurveyorScreen> createState() => _SurveyorScreenState();
}

class _SurveyorScreenState extends State<SurveyorScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-save every recorded step into SQLite database
    widget.engine.onStepRecorded = (record) {
      widget.dbService.saveStepLog(record);
    };

    // Save initial starting step if one exists
    if (widget.engine.stepLogs.isNotEmpty) {
      widget.dbService.saveStepLog(widget.engine.stepLogs.first);
    }

    _bootSequence();
  }

  Future<void> _bootSequence() async {
    final loaded = await widget.repository.loadLatestBackupIfAvailable();
    if (loaded && widget.engine.hasActiveBuilding) {
      final savedZones = await widget.dbService.getZonesForFloor(widget.engine.currentFloor);
      if (widget.engine.zones.isEmpty) {
        widget.engine.zones.addAll(savedZones);
      }
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Restored previous session: ${widget.engine.currentBuilding}'),
          backgroundColor: const Color(0xFF64B5F6),
        ));
      }
    } else {
      widget.dbService.getZonesForFloor(widget.engine.currentFloor).then((savedZones) {
        if (widget.engine.hasActiveBuilding && widget.engine.zones.isEmpty) {
          widget.engine.zones.addAll(savedZones);
        }
      });
    }
  }


  void _openAddBuildingDialog() {
    AddBuildingDialog.show(
      context,
      widget.engine,
      onBuildingCreated: () => setState(() {}),
    );
  }

  void _confirmDeleteBuilding() {
    if (!widget.engine.hasActiveBuilding) return;
    final bName = widget.engine.currentBuilding;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Delete Building Survey?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete the entire survey for "$bName"? All floors and rooms in this building will be removed from this session.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              widget.engine.deleteBuilding(bName);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted survey for "$bName".')),
              );
            },
            child: const Text('Delete Building', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openRoomModal(String doorSide) {
    if (!widget.engine.hasActiveBuilding) return;

    showDialog(
      context: context,
      builder: (context) => FacultyRoomModal(
        doorSide: doorSide,
        onSave: (name, roomNum, cat, dept, side, cap, faculty, dWidth, tHeight, photoPath) {
          final room = widget.engine.markRoomDoor(
            name: name,
            roomNumber: roomNum,
            category: cat,
            department: dept,
            doorSide: side,
            capacity: cap,
            faculty: faculty,
          );
          room.facultyMembers = faculty;
          room.photoPath = photoPath; // Set photoPath directly on room for now
          
          // Synthesize an Opening for ADA graph?
          final opening = Opening(
            id: 'op_${DateTime.now().millisecondsSinceEpoch}',
            levelId: widget.engine.currentFloor,
            unitIdA: 'corridor_${room.id}', // Fake for now if not known, or what does markRoomDoor do?
            unitIdB: room.id,
            clearWidthMeters: dWidth,
            thresholdHeightMm: tHeight,
            photoPath: photoPath,
          );
          widget.dbService.saveOpening(opening);
          widget.engine.openings.add(opening);
          
          widget.dbService.saveRoom(room);
          setState(() {});
        },
      ),
    );
  }

  void _openPortalModal(String portalType) {
    if (!widget.engine.hasActiveBuilding) return;

    final elevation = widget.engine.geospatialService.getFloorHeightMeters(widget.engine.currentFloor);

    showDialog(
      context: context,
      builder: (context) => PortalTransferModal(
        currentFloor: widget.engine.currentFloor,
        availableFloors: widget.engine.availableFloors,
        currentX: widget.engine.currentX,
        currentY: widget.engine.currentY,
        currentElevation: elevation,
        onTagOnly: (name, type) {
          final room = widget.engine.tagVerticalPortalLandmark(name: name, portalType: type);
          widget.dbService.saveRoom(room);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1C442E),
              content: Text('Tagged $name at (${room.x.round()}, ${room.y.round()}) with elevation ${elevation.toStringAsFixed(1)}m'),
            ),
          );
        },
        onTransfer: (name, type, targetFloor) {
          widget.engine.enterVerticalPortal(name: name, portalType: type);
          widget.engine.exitVerticalPortal(targetFloor: targetFloor);
          final targetElev = widget.engine.geospatialService.getFloorHeightMeters(targetFloor);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1C442E),
              content: Text('Climbed $name to $targetFloor (Elev: ${targetElev.toStringAsFixed(1)}m). 3D linked!'),
            ),
          );
        },
      ),
    );
  }

  void _openWiFiTelemetry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WiFiTelemetrySheet(
        fingerprints: widget.engine.fingerprints,
        onManualScan: () {
          widget.engine.wifiScanner.scanAtLocation(
            floor: widget.engine.currentFloor,
            x: widget.engine.currentX,
            y: widget.engine.currentY,
          );
          setState(() {});
        },
      ),
    );
  }

  void _attemptLoopClosure() {
    if (!widget.engine.hasActiveBuilding) return;

    final floorRooms = widget.engine.rooms.where((r) => r.floor == widget.engine.currentFloor).toList();
    if (floorRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No landmark/room to close loop against! Mark a start door or stair.')),
      );
      return;
    }

    final target = floorRooms.first;
    final success = LoopClosureOptimizer.optimizeLoop(
      engine: widget.engine,
      targetX: target.x,
      targetY: target.y,
    );

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: const Color(0xFF81C784), content: Text('✅ Loop Closed at ${target.name}! Drift eliminated.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not close loop (surveyor too far from start point).')),
      );
    }
  }

  void _openCommentDialog() {
    StepCommentDialog.show(context, engine: widget.engine, dbService: widget.dbService);
  }

  void _openDeadEndDialog() {
    DeadEndDialog.show(context, engine: widget.engine, dbService: widget.dbService);
  }

  void _openEncloseZoneDialog() {
    EncloseZoneDialog.show(
      context,
      engine: widget.engine,
      dbService: widget.dbService,
      onZoneSaved: () => setState(() {}),
    );
  }

  void _openCompleteFloorDialog() {
    CompleteFloorDialog.show(
      context,
      engine: widget.engine,
      onFinalizeExport: _exportDatabase,
    );
  }

  void _resetSurvey() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Reset Survey?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This will clear all in-memory survey footsteps, rooms, and corridors for this building, returning the surveyor avatar to origin (400, 400).',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              widget.engine.resetSurvey();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Survey reset to initial origin.')),
              );
            },
            child: const Text('Reset Map', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openSchemaViewer() {
    SchemaViewerSheet.show(
      context,
      engine: widget.engine,
      dbService: widget.dbService,
      onEntriesModified: () => setState(() {}),
    );
  }

  void _exportDatabase() {
    ExportSummaryDialog.show(context, engine: widget.engine, dbService: widget.dbService);
  }

  void _openImdfExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  void _openAzimuthDialog() {
    showDialog(
      context: context,
      builder: (context) => const AzimuthAlignmentDialog(),
    );
  }

  void _openStrideCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => const StrideCalibrationDialog(),
    );
  }

  void _openCorridorPropertiesDialog() {
    CorridorPropertiesDialog.show(
      context,
      engine: widget.engine,
      dbService: widget.dbService,
      onPropertiesUpdated: () => setState(() {}),
    );
  }

  void _openDoorPropertiesDialog() {
    DoorPropertiesDialog.show(
      context,
      engine: widget.engine,
      dbService: widget.dbService,
      onSaved: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. First Boot Blank Screen: User must create their first building
    if (!widget.engine.hasActiveBuilding) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141624),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, color: Color(0xFF81C784)),
              ),
            ),
          ),
          title: const Text('EWUNav Surveyor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64B5F6))),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2235),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.domain_add, size: 64, color: Color(0xFF81C784)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Building Survey Active',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Start a clean indoor survey. Create your building and add floors one by one as you walk and map the campus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('+ Create New Building Survey', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: _openAddBuildingDialog,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final latestStep = widget.engine.stepLogs.isNotEmpty ? widget.engine.stepLogs.last : null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 850;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141624),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, color: Color(0xFF81C784)),
            ),
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EWUNav', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64B5F6))),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: widget.engine.currentBuilding.isNotEmpty ? widget.engine.currentBuilding : null,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  items: [
                    ...widget.engine.availableBuildings.map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        )),
                    const DropdownMenuItem<String>(
                      value: '__ADD_NEW__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: Color(0xFF81C784)),
                          SizedBox(width: 6),
                          Text('+ New Building...', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == '__ADD_NEW__') {
                      _openAddBuildingDialog();
                    } else if (val != null) {
                      widget.engine.selectBuilding(val);
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.comment_outlined, color: Color(0xFFFFD54F)),
            tooltip: 'Add Comment to Step',
            onPressed: _openCommentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF64B5F6)),
            tooltip: 'IMDF / GeoJSON Export',
            onPressed: _openImdfExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF81C784)),
            tooltip: 'Save & Inspect Database',
            onPressed: _exportDatabase,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1E2235),
            tooltip: 'More Actions',
            onSelected: (val) {
              if (val == 'schema') _openSchemaViewer();
              if (val == 'wifi') _openWiFiTelemetry();
              if (val == 'loop') _attemptLoopClosure();
              if (val == 'azimuth') _openAzimuthDialog();
              if (val == 'stride') _openStrideCalibrationDialog();
              if (val == 'corridor_ada') _openCorridorPropertiesDialog();
              if (val == 'door_ada') _openDoorPropertiesDialog();
              if (val == 'new_b') _openAddBuildingDialog();
              if (val == 'delete_b') _confirmDeleteBuilding();
              if (val == 'reset') _resetSurvey();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'schema',
                child: Row(
                  children: [
                    Icon(Icons.data_object, color: Color(0xFFBA68C8), size: 18),
                    SizedBox(width: 8),
                    Text('Generated Schema', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'wifi',
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: Color(0xFF64B5F6), size: 18),
                    SizedBox(width: 8),
                    Text('Wi-Fi Telemetry', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'loop',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: Color(0xFFFFD54F), size: 18),
                    SizedBox(width: 8),
                    Text('Close Loop', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'azimuth',
                child: Row(
                  children: [
                    Icon(Icons.explore, color: Color(0xFF4FC3F7), size: 18),
                    SizedBox(width: 8),
                    Text('Building Azimuth', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stride',
                child: Row(
                  children: [
                    Icon(Icons.straighten, color: Color(0xFFFFB74D), size: 18),
                    SizedBox(width: 8),
                    Text('Stride Calibration', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'corridor_ada',
                child: Row(
                  children: [
                    Icon(Icons.accessible, color: Color(0xFF64B5F6), size: 18),
                    SizedBox(width: 8),
                    Text('Walkway ADA Properties', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'door_ada',
                child: Row(
                  children: [
                    Icon(Icons.sensor_door, color: Color(0xFF81C784), size: 18),
                    SizedBox(width: 8),
                    Text('Door ADA Audit', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'new_b',
                child: Row(
                  children: [
                    Icon(Icons.domain_add, color: Color(0xFF81C784), size: 18),
                    SizedBox(width: 8),
                    Text('+ Add Building', style: TextStyle(color: Color(0xFF81C784), fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_b',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Building', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Reset / Clear Map', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Modular Floor Tab Selector
          FloorSelectorBar(
            engine: widget.engine,
            onFloorChanged: () => setState(() {}),
          ),

          // Main Responsive Workspace
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      // Desktop Canvas (Left ~65%)
                      Expanded(
                        flex: 7,
                        child: Stack(
                          children: [
                            SurveyorCanvas(
                              engine: widget.engine,
                              onRoomDeleted: (room) => widget.dbService.deleteRoom(room.id),
                            ),
                            TelemetryHud(engine: widget.engine, latestStep: latestStep),
                            LoopCandidateBanner(
                              engine: widget.engine,
                              onEnclosePressed: _openEncloseZoneDialog,
                              onDismissPressed: () => setState(() => widget.engine.dismissPendingLoop()),
                            ),
                          ],
                        ),
                      ),

                      // Desktop Surveyor Workbench Dock (Right ~35%)
                      WorkbenchDock(
                        engine: widget.engine,
                        dbService: widget.dbService,
                        onToggleRecording: () => setState(() => widget.engine.toggleRecording()),
                        onCompleteFloor: _openCompleteFloorDialog,
                        onOpenRoomModal: _openRoomModal,
                        onOpenPortalModal: _openPortalModal,
                        onDeadEnd: _openDeadEndDialog,
                        onAddComment: _openCommentDialog,
                        onStepModified: () => setState(() {}),
                        onCorridorProperties: _openCorridorPropertiesDialog,
                        onDoorAudit: _openDoorPropertiesDialog,
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      SurveyorCanvas(
                        engine: widget.engine,
                        onRoomDeleted: (room) => widget.dbService.deleteRoom(room.id),
                      ),
                      TelemetryHud(engine: widget.engine, latestStep: latestStep),
                      LoopCandidateBanner(
                        engine: widget.engine,
                        onEnclosePressed: _openEncloseZoneDialog,
                        onDismissPressed: () => setState(() => widget.engine.dismissPendingLoop()),
                      ),
                    ],
                  ),
          ),

          // Mobile Tactile Thumb Action Bar (Only shown on mobile)
          if (!isDesktop)
            ThumbActionBar(
              isRecording: widget.engine.isRecording,
              onToggleRecording: () => setState(() => widget.engine.toggleRecording()),
              onCompleteFloor: _openCompleteFloorDialog,
              onMarkDeadEnd: _openDeadEndDialog,
              onEncloseZone: _openEncloseZoneDialog,
              onDoorLeft: () => _openRoomModal('left'),
              onDoorRight: () => _openRoomModal('right'),
              onTurnLeft: () => widget.engine.turn(-90),
              onTurnRight: () => widget.engine.turn(90),
              onWalkStraight: () => widget.engine.manualStep(3.0),
              onManualStep: () => widget.engine.manualStep(0.75),
              onMarkStair: () => _openPortalModal('stair'),
              onMarkLift: () => _openPortalModal('lift'),
              onAddComment: _openCommentDialog,
              onUTurn: () => widget.engine.turn(180),
              onUndo: () {
                if (widget.engine.stepLogs.isNotEmpty) {
                  final last = widget.engine.stepLogs.last;
                  widget.engine.undo();
                  widget.dbService.deleteStepLog(last.stepIndex);
                } else {
                  widget.engine.undo();
                }
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
