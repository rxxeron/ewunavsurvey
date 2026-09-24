import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/room_node.dart';
import '../../services/slam_surveyor_engine.dart';
import '../../services/loop_closure_optimizer.dart';
import '../../services/db_service.dart';
import 'surveyor_canvas.dart';
import 'thumb_action_bar.dart';
import 'faculty_room_modal.dart';
import 'portal_transfer_modal.dart';
import 'wifi_telemetry_sheet.dart';

class SurveyorScreen extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;

  const SurveyorScreen({
    super.key,
    required this.engine,
    required this.dbService,
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
  }

  void _openAddBuildingDialog() {
    final nameCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: 'Ground Floor');
    double lat = 23.7684;
    double lng = 90.4258;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: Row(
            children: const [
              Icon(Icons.domain_add, color: Color(0xFF81C784)),
              SizedBox(width: 8),
              Text('New Building Survey', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Presets (or enter custom name below):',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      backgroundColor: const Color(0xFF141624),
                      label: const Text('Main Building & Block-C', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          nameCtrl.text = 'Main Building & Block-C';
                          lat = 23.7684;
                          lng = 90.4258;
                        });
                      },
                    ),
                    ActionChip(
                      backgroundColor: const Color(0xFF141624),
                      label: const Text('Academic Building 1 (AB1)', style: TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          nameCtrl.text = 'Academic Building 1 (AB1)';
                          lat = 23.76763;
                          lng = 90.42504;
                        });
                      },
                    ),
                    ActionChip(
                      backgroundColor: const Color(0xFF141624),
                      label: const Text('Academic Building 2 (AB2)', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          nameCtrl.text = 'Academic Building 2 (AB2)';
                          lat = 23.76856;
                          lng = 90.42631;
                        });
                      },
                    ),
                    ActionChip(
                      backgroundColor: const Color(0xFF141624),
                      label: const Text('Academic Building 3 (AB3)', style: TextStyle(color: Color(0xFFBA68C8), fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          nameCtrl.text = 'Academic Building 3 (AB3)';
                          lat = 23.76725;
                          lng = 90.42732;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Building Name',
                    labelStyle: TextStyle(color: Color(0xFF64B5F6)),
                    hintText: 'e.g. Academic Building 1, Library Building',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF141624),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: floorCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Starting Floor',
                    labelStyle: TextStyle(color: Color(0xFF81C784)),
                    hintText: 'e.g. Ground Floor, Basement, 1st Floor',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF141624),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Floors are added one by one as you survey. You can add more floors at any time.',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final floor = floorCtrl.text.trim();
                if (name.isNotEmpty) {
                  widget.engine.createBuilding(
                    name: name,
                    lat: lat,
                    lng: lng,
                    initialFloor: floor.isNotEmpty ? floor : 'Ground Floor',
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1C442E),
                      content: Text('Building "$name" created. Survey active!'),
                    ),
                  );
                }
              },
              child: const Text('Begin Survey', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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

  void _confirmDeleteFloor(String floorName) {
    if (widget.engine.availableFloors.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only floor in this building.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text('Delete $floorName?', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "$floorName" from ${widget.engine.currentBuilding}? All rooms and steps on this floor will be deleted.',
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
              widget.engine.deleteFloor(floorName);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$floorName".')),
              );
            },
            child: const Text('Delete Floor', style: TextStyle(color: Colors.white)),
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
        onSave: (name, roomNum, cat, dept, side, cap, faculty) {
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
          widget.dbService.saveRoom(room);
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
    if (!widget.engine.hasActiveBuilding) return;

    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('💬 Add Step Comment / Field Note', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 16)),
        content: TextField(
          controller: commentCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Glass door to cafeteria, Water cooler on left, Floor tile transition',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Color(0xFF141624),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
            onPressed: () {
              final text = commentCtrl.text.trim();
              if (text.isNotEmpty) {
                widget.engine.addCommentToCurrentStep(text);
                if (widget.engine.stepLogs.isNotEmpty) {
                  final last = widget.engine.stepLogs.last;
                  widget.dbService.updateStepComment(last.stepIndex, text);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Color(0xFF1C442E), content: Text('Comment saved to step log!')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAddFloorDialog() {
    if (!widget.engine.hasActiveBuilding) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Add Custom Floor', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. 1st Floor, 2nd Floor, Mezzanine, Rooftop',
            hintStyle: TextStyle(color: Colors.white38),
            labelText: 'Floor Name',
            labelStyle: TextStyle(color: Color(0xFF64B5F6)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF64B5F6))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                widget.engine.addCustomFloor(text);
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add & Switch', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
    int activeTab = 0; // 0: Blueprint, 1: Raw Steps, 2: Delete Entries

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141624),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final data = widget.engine.exportGraphJson();
          final rawStepsData = {
            'building': widget.engine.currentBuilding,
            'totalSteps': widget.engine.stepLogs.length,
            'steps': widget.engine.stepLogs.map((s) => s.toJson()).toList(),
          };

          final jsonStr = const JsonEncoder.withIndent('  ').convert(
            activeTab == 0 ? data : rawStepsData,
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Blueprint Graph JSON'),
                            selected: activeTab == 0,
                            selectedColor: const Color(0xFF64B5F6),
                            backgroundColor: const Color(0xFF1E2235),
                            labelStyle: TextStyle(
                              color: activeTab == 0 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setSheetState(() => activeTab = 0),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Raw Steps & Wi-Fi'),
                            selected: activeTab == 1,
                            selectedColor: const Color(0xFF81C784),
                            backgroundColor: const Color(0xFF1E2235),
                            labelStyle: TextStyle(
                              color: activeTab == 1 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setSheetState(() => activeTab = 1),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('🗑️ Delete Entries'),
                            selected: activeTab == 2,
                            selectedColor: Colors.redAccent,
                            backgroundColor: const Color(0xFF1E2235),
                            labelStyle: TextStyle(
                              color: activeTab == 2 ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) => setSheetState(() => activeTab = 2),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF64B5F6)),
                        tooltip: 'Copy JSON',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: jsonStr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied JSON to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: activeTab == 2
                        ? ListView(
                            controller: scrollCtrl,
                            children: [
                              const Text(
                                'Manage & Delete Survey Entries',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap the red trash icon to permanently remove any wrongly placed room or step entry.',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              Text('Tagged Rooms (${widget.engine.rooms.length})',
                                  style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 13)),
                              const Divider(color: Colors.white12),
                              if (widget.engine.rooms.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No rooms tagged yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                )
                              else
                                ...widget.engine.rooms.map((r) => Container(
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(6)),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.meeting_room, color: Color(0xFF81C784), size: 18),
                                        title: Text('${r.name} (${(r.roomNumber != null && r.roomNumber!.isNotEmpty) ? r.roomNumber : "No #"})',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        subtitle: Text('${r.floor} • Side: ${r.doorSide} • (${r.x.round()}, ${r.y.round()})',
                                            style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                          tooltip: 'Delete this room entry',
                                          onPressed: () {
                                            widget.engine.deleteRoom(r.id);
                                            widget.dbService.deleteRoom(r.id);
                                            setSheetState(() {});
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Deleted room "${r.name}"')),
                                            );
                                          },
                                        ),
                                      ),
                                    )),
                              const SizedBox(height: 16),
                              Text('Step Logs (${widget.engine.stepLogs.length})',
                                  style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 13)),
                              const Divider(color: Colors.white12),
                              if (widget.engine.stepLogs.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No steps recorded yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                )
                              else
                                ...widget.engine.stepLogs.reversed.take(20).map((s) => Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(6)),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.directions_walk, color: Color(0xFF64B5F6), size: 16),
                                        title: Text('Step #${s.stepIndex} • ${s.floor} • Heading: ${s.headingDeg.round()}°',
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        subtitle: Text(
                                          '(${s.x.round()}, ${s.y.round()}) ${s.comment != null && s.comment!.isNotEmpty ? "• Note: " + s.comment! : ""}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                          tooltip: 'Delete this step',
                                          onPressed: () {
                                            widget.engine.deleteStepLog(s.stepIndex);
                                            widget.dbService.deleteStepLog(s.stepIndex);
                                            setSheetState(() {});
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Deleted step #${s.stepIndex}')),
                                            );
                                          },
                                        ),
                                      ),
                                    )),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F111A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: SingleChildScrollView(
                              controller: scrollCtrl,
                              child: SelectableText(
                                jsonStr,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFA6ADC8)),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _exportDatabase() async {
    final processedGraph = widget.engine.exportGraphJson();
    final processedJson = const JsonEncoder.withIndent('  ').convert(processedGraph);
    final rawJson = await widget.dbService.exportRawDataJson();
    final dbPath = await widget.dbService.getDatabaseFilePath();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('💾 Survey Database Export', style: TextStyle(color: Color(0xFF64B5F6))),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Building: ${widget.engine.currentBuilding}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Rooms Tagged: ${widget.engine.rooms.length}', style: const TextStyle(color: Colors.white70)),
              Text('Corridor Edges: ${widget.engine.edges.length}', style: const TextStyle(color: Colors.white70)),
              Text('Wi-Fi Fingerprints: ${widget.engine.fingerprints.length}', style: const TextStyle(color: Colors.white70)),
              Text('Step Logs Recorded: ${widget.engine.stepLogs.length}', style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24, height: 16),
              const Text('📁 Raw SQLite Database File:', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold)),
              SelectableText(dbPath, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                      icon: const Icon(Icons.copy, size: 14, color: Color(0xFF64B5F6)),
                      label: const Text('Processed Graph', style: TextStyle(fontSize: 11, color: Color(0xFF64B5F6))),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: processedJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied processed campus_graph.json to clipboard!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E)),
                      icon: const Icon(Icons.copy, size: 14, color: Color(0xFF81C784)),
                      label: const Text('Raw Steps JSON', style: TextStyle(fontSize: 11, color: Color(0xFF81C784))),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied raw step logs & Wi-Fi JSON to clipboard!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbenchCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.architecture, color: Color(0xFF81C784)),
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

    final availableFloors = widget.engine.availableFloors;
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
              errorBuilder: (_, __, ___) => const Icon(Icons.architecture, color: Color(0xFF81C784)),
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
            icon: const Icon(Icons.save, color: Color(0xFF81C784)),
            tooltip: 'Save & Export',
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
          // Floor Tab Selector
          Container(
            height: 44,
            color: const Color(0xFF141624),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: availableFloors.length + 1,
              itemBuilder: (context, index) {
                if (index == availableFloors.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Color(0xFF81C784)),
                      label: const Text('Add Floor', style: TextStyle(color: Color(0xFF81C784), fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF1E2235),
                      side: const BorderSide(color: Color(0xFF81C784), width: 0.8),
                      onPressed: _openAddFloorDialog,
                    ),
                  );
                }
                final f = availableFloors[index];
                final isSelected = (f == widget.engine.currentFloor);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: InkWell(
                    onLongPress: availableFloors.length > 1 ? () => _confirmDeleteFloor(f) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(f, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
                          if (availableFloors.length > 1 && isSelected) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _confirmDeleteFloor(f),
                              child: const Icon(Icons.close, size: 13, color: Colors.black54),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF64B5F6),
                      backgroundColor: const Color(0xFF1E2235),
                      onSelected: (selected) {
                        if (selected) widget.engine.setFloor(f);
                      },
                    ),
                  ),
                );
              },
            ),
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
                            _buildHud(latestStep),
                          ],
                        ),
                      ),

                      // Desktop Surveyor Workbench Dock (Right ~35%)
                      Container(
                        width: 380,
                        decoration: const BoxDecoration(
                          color: Color(0xFF141622),
                          border: Border(left: BorderSide(color: Color(0xFF2C324A))),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            // Card 1: Walking Controls & Undo
                            _buildWorkbenchCard(
                              '👣 Physical Movement',
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        widget.engine.pdrEngine.isHardwareActive ? Icons.directions_walk : Icons.touch_app,
                                        size: 14,
                                        color: widget.engine.pdrEngine.isHardwareActive ? const Color(0xFF81C784) : const Color(0xFF64B5F6),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.engine.pdrEngine.isHardwareActive
                                              ? 'Pedometer: ACTIVE (walking auto-records steps)'
                                              : 'Pedometer: Standby (Use buttons or walk on phone)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: widget.engine.pdrEngine.isHardwareActive ? const Color(0xFF81C784) : Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E3A5F),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.directions_walk, color: Color(0xFF64B5F6), size: 18),
                                          label: const Text('👣 Step (0.75m)', style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 12)),
                                          onPressed: () => widget.engine.manualStep(0.75),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1C442E),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.fast_forward, color: Color(0xFF81C784), size: 18),
                                          label: const Text('🚶 5 Steps (3.8m)', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                                          onPressed: () => widget.engine.manualStep(3.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD54F), side: const BorderSide(color: Color(0xFFFFD54F))),
                                          onPressed: () => widget.engine.turn(-90),
                                          child: const Text('↰ Left 90°', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD54F), side: const BorderSide(color: Color(0xFFFFD54F))),
                                          onPressed: () => widget.engine.turn(90),
                                          child: const Text('Right 90° ↱', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                                        onPressed: () => widget.engine.turn(180),
                                        child: const Text('🔄 U-Turn', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Row 3: Delete / Undo Step
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: const Icon(Icons.undo, size: 16),
                                          label: const Text('⎌ Undo / Delete Last Step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            if (widget.engine.stepLogs.isNotEmpty) {
                                              final last = widget.engine.stepLogs.last;
                                              widget.engine.undo();
                                              widget.dbService.deleteStepLog(last.stepIndex);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Undid and deleted previous step.')),
                                              );
                                            } else {
                                              widget.engine.undo();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Card 2: Tag Rooms & Portals
                            _buildWorkbenchCard(
                              '🚪 Tag Rooms & Vertical Portals',
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E), padding: const EdgeInsets.symmetric(vertical: 12)),
                                          icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF81C784)),
                                          label: const Text('Door LEFT', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                                          onPressed: () => _openRoomModal('left'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E), padding: const EdgeInsets.symmetric(vertical: 12)),
                                          icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF81C784)),
                                          label: const Text('Door RIGHT', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                                          onPressed: () => _openRoomModal('right'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF8A65), side: const BorderSide(color: Color(0xFFFF8A65))),
                                          icon: const Icon(Icons.stairs, size: 16),
                                          label: const Text('🪜 Stair', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openPortalModal('stair'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFBA68C8), side: const BorderSide(color: Color(0xFFBA68C8))),
                                          icon: const Icon(Icons.elevator, size: 16),
                                          label: const Text('🛗 Lift', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openPortalModal('lift'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Card 3: Step Field Notes & Comments
                            _buildWorkbenchCard(
                              '💬 Field Notes & Annotations',
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D3212), side: const BorderSide(color: Color(0xFFFFD54F)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                icon: const Icon(Icons.comment, color: Color(0xFFFFD54F), size: 18),
                                label: const Text('Add Note at Current Step', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: _openCommentDialog,
                              ),
                            ),

                            // Card 4: Live Wi-Fi Telemetry
                            _buildWorkbenchCard(
                              '📶 Wi-Fi Signal Telemetry',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: widget.engine.wifiScanner.isHardwareSupported ? const Color(0xFF1C442E) : const Color(0xFF332A15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          widget.engine.wifiScanner.isHardwareSupported ? Icons.check_circle : Icons.info_outline,
                                          size: 12,
                                          color: widget.engine.wifiScanner.isHardwareSupported ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            widget.engine.wifiScanner.isHardwareSupported
                                                ? 'Mode: Live Android Wi-Fi Adapter'
                                                : 'Mode: Web Sandbox (Real chips scan on Android)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: widget.engine.wifiScanner.isHardwareSupported ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Fingerprints: ${widget.engine.fingerprints.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      TextButton.icon(
                                        icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF64B5F6)),
                                        label: const Text('Scan Now', style: TextStyle(fontSize: 11, color: Color(0xFF64B5F6))),
                                        onPressed: () {
                                          widget.engine.wifiScanner.scanAtLocation(
                                            floor: widget.engine.currentFloor,
                                            x: widget.engine.currentX,
                                            y: widget.engine.currentY,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  if (!widget.engine.wifiScanner.isHardwareSupported)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Simulate APs for Web testing:', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                          SizedBox(
                                            height: 24,
                                            child: Switch(
                                              value: widget.engine.wifiScanner.enableWebSimulation,
                                              activeColor: const Color(0xFF64B5F6),
                                              onChanged: (val) {
                                                setState(() {
                                                  widget.engine.wifiScanner.enableWebSimulation = val;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (widget.engine.fingerprints.isNotEmpty && widget.engine.fingerprints.last.accessPoints.isNotEmpty) ...[
                                    for (var ap in widget.engine.fingerprints.last.accessPoints.take(3))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('📡 ${ap.ssid}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            Text('${ap.level} dBm', style: TextStyle(color: ap.level > -70 ? const Color(0xFF81C784) : const Color(0xFFFFD54F), fontSize: 11, fontFamily: 'monospace')),
                                          ],
                                        ),
                                      ),
                                  ] else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: Text('0 access points logged. Wi-Fi scans live on Android.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      SurveyorCanvas(
                        engine: widget.engine,
                        onRoomDeleted: (room) => widget.dbService.deleteRoom(room.id),
                      ),
                      _buildHud(latestStep),
                    ],
                  ),
          ),

          // Mobile Tactile Thumb Action Bar (Only shown on mobile)
          if (!isDesktop)
            ThumbActionBar(
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
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHud(dynamic latestStep) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC1E2235),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Steps: ${widget.engine.pdrEngine.stepCount} | Dist: ${widget.engine.pdrEngine.totalDistanceMeters.toStringAsFixed(1)}m | Heading: ${widget.engine.currentHeadingDeg.round()}°',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Lat: ${(latestStep?.latitude ?? widget.engine.currentBuildingLat).toStringAsFixed(6)}° | '
              'Lng: ${(latestStep?.longitude ?? widget.engine.currentBuildingLng).toStringAsFixed(6)}° | '
              'H: ${(latestStep?.floorHeightMeters ?? 0.0).toStringAsFixed(1)}m (Alt: ${(latestStep?.altitudeMeters ?? 7.5).toStringAsFixed(1)}m)',
              style: const TextStyle(color: Color(0xFF81C784), fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
