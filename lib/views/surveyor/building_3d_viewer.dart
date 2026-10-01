import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/slam_surveyor_engine.dart';
import '../../models/room_node.dart';

class Building3DViewer extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback? onClose;
  final bool autoAscend;
  final String? fromFloor;
  final String? toFloor;

  const Building3DViewer({
    super.key,
    required this.engine,
    this.onClose,
    this.autoAscend = false,
    this.fromFloor,
    this.toFloor,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    bool autoAscend = false,
    String? fromFloor,
    String? toFloor,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        child: Building3DViewer(
          engine: engine,
          autoAscend: autoAscend,
          fromFloor: fromFloor,
          toFloor: toFloor,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  State<Building3DViewer> createState() => _Building3DViewerState();
}

class _Building3DViewerState extends State<Building3DViewer> with SingleTickerProviderStateMixin {
  // 3D Orbit Camera Angles
  double _yawDeg = 45.0;     // Horizontal orbit rotation
  double _pitchDeg = 38.0;   // Vertical tilt (15° to 85°)
  double _zoom = 0.85;       // Camera distance scale
  Offset _panOffset = Offset.zero;

  bool _isolateCurrentFloor = false;
  bool _showCorridorWalls = true;
  bool _showPortals = true;

  // 3D Stair Ascent Simulation
  late AnimationController _climbController;
  bool _isAscending = false;
  String? _climbFromFloor;
  String? _climbToFloor;

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..addListener(() {
        setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isAscending = false;
            if (_climbToFloor != null) {
              widget.engine.setFloor(_climbToFloor!);
            }
          });
        }
      });

    if (widget.autoAscend) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startStairAscent(
          fromFloor: widget.fromFloor,
          toFloor: widget.toFloor,
        );
      });
    }
  }

  @override
  void dispose() {
    _climbController.dispose();
    super.dispose();
  }

  void _startStairAscent({String? fromFloor, String? toFloor}) {
    final availableFloors = widget.engine.availableFloors;
    if (availableFloors.length < 2) return;

    final curIdx = availableFloors.indexOf(widget.engine.currentFloor);
    final targetIdx = (curIdx + 1 < availableFloors.length) ? curIdx + 1 : 0;

    _climbFromFloor = fromFloor ?? widget.engine.currentFloor;
    _climbToFloor = toFloor ?? availableFloors[targetIdx];

    // Stabilize camera angle to ideal stair viewing perspective
    setState(() {
      _isAscending = true;
      _pitchDeg = 35.0; // Stable pitch
      _yawDeg = 48.0;   // Focused on staircase orientation
      _isolateCurrentFloor = false;
    });

    _climbController.forward(from: 0.0);
  }

  void _resetCamera() {
    setState(() {
      _yawDeg = 45.0;
      _pitchDeg = 38.0;
      _zoom = 0.85;
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final availableFloors = engine.availableFloors;

    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141624),
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.view_in_ar, color: Color(0xFF64B5F6), size: 22),
            const SizedBox(width: 8),
            Text(
              '🏢 3D Building Viewer: ${engine.currentBuilding}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            tooltip: 'Reset 3D Camera',
            onPressed: _resetCamera,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close 3D View',
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 3D Gesture Viewport
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                // Orbit yaw & pitch
                _yawDeg = (_yawDeg + details.delta.dx * 0.4) % 360.0;
                _pitchDeg = (_pitchDeg - details.delta.dy * 0.3).clamp(12.0, 85.0);
              });
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([engine, _climbController]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _Building3DPainter(
                    engine: engine,
                    yawDeg: _yawDeg,
                    pitchDeg: _pitchDeg,
                    zoom: _zoom,
                    panOffset: _panOffset,
                    isolateCurrentFloor: _isolateCurrentFloor,
                    showCorridorWalls: _showCorridorWalls,
                    showPortals: _showPortals,
                    climbProgress: _isAscending ? _climbController.value : 0.0,
                    climbFromFloor: _climbFromFloor,
                    climbToFloor: _climbToFloor,
                  ),
                );
              },
            ),
          ),

          // HUD Floating Info & Compass (Top Left)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xDD191B2B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.explore, size: 14, color: Color(0xFF81C784)),
                      const SizedBox(width: 6),
                      Text('Yaw: ${_yawDeg.round()}°  |  Pitch: ${_pitchDeg.round()}°',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Active Floor: ${engine.currentFloor}',
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 11)),
                  const SizedBox(height: 2),
                  const Text('Drag: Orbit 3D  |  Tap Floor below to jump',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ),

          // Top Ascent Notification Banner
          if (_isAscending)
            Positioned(
              top: 14,
              left: 200,
              right: 80,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xEE1E2235),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF8A65), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A65)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '🪜 Ascending: $_climbFromFloor ➔ $_climbToFloor (${(_climbController.value * 100).toInt()}%)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '• Camera Stabilized',
                        style: TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating 3D Controls (Top Right)
          Positioned(
            top: 14,
            right: 14,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: '3d_zoom_in',
                  backgroundColor: const Color(0xFF1E2235),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom In',
                  onPressed: () => setState(() => _zoom = (_zoom * 1.2).clamp(0.3, 3.5)),
                  child: const Icon(Icons.add, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: '3d_zoom_out',
                  backgroundColor: const Color(0xFF1E2235),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom Out',
                  onPressed: () => setState(() => _zoom = (_zoom / 1.2).clamp(0.3, 3.5)),
                  child: const Icon(Icons.remove, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: '3d_walls_toggle',
                  backgroundColor: _showCorridorWalls ? const Color(0xFF64B5F6) : const Color(0xFF1E2235),
                  foregroundColor: _showCorridorWalls ? Colors.black : const Color(0xFF64B5F6),
                  tooltip: _showCorridorWalls ? 'Hide 3D Walls' : 'Show 3D Walls',
                  onPressed: () => setState(() => _showCorridorWalls = !_showCorridorWalls),
                  child: const Icon(Icons.view_sidebar, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: '3d_portals_toggle',
                  backgroundColor: _showPortals ? const Color(0xFFBA68C8) : const Color(0xFF1E2235),
                  foregroundColor: _showPortals ? Colors.black : const Color(0xFFBA68C8),
                  tooltip: _showPortals ? 'Hide Vertical Shafts' : 'Show 3D Stair/Lift Shafts',
                  onPressed: () => setState(() => _showPortals = !_showPortals),
                  child: const Icon(Icons.elevator, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: '3d_climb_trigger',
                  backgroundColor: _isAscending ? const Color(0xFFFF8A65) : const Color(0xFF1E2235),
                  foregroundColor: _isAscending ? Colors.black : const Color(0xFFFF8A65),
                  tooltip: _isAscending ? 'Climbing stairs...' : 'Simulate 3D Stair Ascent',
                  onPressed: _isAscending ? null : () => _startStairAscent(),
                  child: const Icon(Icons.stairs, size: 18),
                ),
              ],
            ),
          ),

          // Bottom Floor Switcher & Isolation Bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xEE141624),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterChip(
                      label: const Text('Stack All Floors', style: TextStyle(fontSize: 11)),
                      selected: !_isolateCurrentFloor,
                      selectedColor: const Color(0xFF1E3A5F),
                      backgroundColor: const Color(0xFF1E2235),
                      checkmarkColor: const Color(0xFF64B5F6),
                      labelStyle: TextStyle(
                        color: !_isolateCurrentFloor ? const Color(0xFF64B5F6) : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setState(() => _isolateCurrentFloor = !val),
                    ),
                    const SizedBox(width: 8),
                    Container(height: 24, width: 1, color: Colors.white24),
                    const SizedBox(width: 8),
                    ...availableFloors.map((f) {
                      final isSelected = (f == engine.currentFloor);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(f, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF64B5F6),
                          backgroundColor: const Color(0xFF1E2235),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() {
                                engine.setFloor(f);
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Building3DPainter extends CustomPainter {
  final SlamSurveyorEngine engine;
  final double yawDeg;
  final double pitchDeg;
  final double zoom;
  final Offset panOffset;
  final bool isolateCurrentFloor;
  final bool showCorridorWalls;
  final bool showPortals;
  final double climbProgress;
  final String? climbFromFloor;
  final String? climbToFloor;

  _Building3DPainter({
    required this.engine,
    required this.yawDeg,
    required this.pitchDeg,
    required this.zoom,
    required this.panOffset,
    required this.isolateCurrentFloor,
    required this.showCorridorWalls,
    required this.showPortals,
    this.climbProgress = 0.0,
    this.climbFromFloor,
    this.climbToFloor,
  });

  // 3D Perspective/Isometric Projector
  Offset project3D(double worldX, double worldY, double worldZ, Size size) {
    // Relative to surveyor center
    final double rx = worldX - engine.currentX;
    final double ry = worldY - engine.currentY;
    final double rz = worldZ;

    final double yawRad = yawDeg * math.pi / 180.0;
    final double pitchRad = pitchDeg * math.pi / 180.0;

    // Rotate Yaw around Z axis
    final double rotX = rx * math.cos(yawRad) - ry * math.sin(yawRad);
    final double rotY = rx * math.sin(yawRad) + ry * math.cos(yawRad);

    // Rotate Pitch around X axis
    final double isoX = rotX;
    final double isoY = rotY * math.sin(pitchRad) - (rz * 18.0) * math.cos(pitchRad);

    final double screenX = size.width / 2 + isoX * zoom + panOffset.dx;
    final double screenY = size.height / 2 + isoY * zoom + panOffset.dy;

    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!engine.hasActiveBuilding) return;

    final availableFloors = engine.availableFloors;
    final double floorZSpacing = 16.0; // Vertical elevation spacing per floor

    // 1. Draw 3D Ground Base Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF141724)
      ..strokeWidth = 1.0;

    const double extent = 1200.0;
    const double step = 80.0;
    for (double x = -extent; x <= extent; x += step) {
      final p1 = project3D(engine.currentX + x, engine.currentY - extent, -1.0, size);
      final p2 = project3D(engine.currentX + x, engine.currentY + extent, -1.0, size);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (double y = -extent; y <= extent; y += step) {
      final p1 = project3D(engine.currentX - extent, engine.currentY + y, -1.0, size);
      final p2 = project3D(engine.currentX + extent, engine.currentY + y, -1.0, size);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // 2. Render Each Floor in 3D Stack
    for (int floorIdx = 0; floorIdx < availableFloors.length; floorIdx++) {
      final floorName = availableFloors[floorIdx];
      if (isolateCurrentFloor && floorName != engine.currentFloor) continue;

      final double zLevel = floorIdx * floorZSpacing;
      final bool isActive = (floorName == engine.currentFloor);

      // Floor Plate / Slab in 3D
      _drawFloorSlab(canvas, size, floorName, zLevel, isActive);

      // 3D Corridors
      _drawFloorCorridors(canvas, size, floorName, zLevel, isActive);

      // 3D Room Pins
      _drawFloorRooms(canvas, size, floorName, zLevel, isActive);
    }

    // 3. Render Vertical Shafts (Stairs & Elevator Towers) connecting across floors
    if (showPortals && !isolateCurrentFloor && availableFloors.length > 1) {
      _drawVerticalPortals(canvas, size, floorZSpacing);
    }

    // 4. Render 3D Surveyor Avatar at Active Floor or on Staircase
    final int activeFloorIdx = availableFloors.indexOf(engine.currentFloor);
    final double userZ = (activeFloorIdx >= 0 ? activeFloorIdx : 0) * floorZSpacing;
    _draw3DSurveyor(canvas, size, userZ, floorZSpacing);
  }

  void _drawFloorSlab(Canvas canvas, Size size, String floorName, double zLevel, bool isActive) {
    final slabBorderPaint = Paint()
      ..color = isActive ? const Color(0xFF64B5F6) : const Color(0xFF2C324A)
      ..strokeWidth = isActive ? 1.8 : 1.0
      ..style = PaintingStyle.stroke;

    final slabFillPaint = Paint()
      ..color = isActive ? const Color(0x1864B5F6) : const Color(0x0C303550)
      ..style = PaintingStyle.fill;

    const double w = 700.0;
    const double h = 500.0;
    final cX = engine.currentX;
    final cY = engine.currentY;

    final p1 = project3D(cX - w, cY - h, zLevel, size);
    final p2 = project3D(cX + w, cY - h, zLevel, size);
    final p3 = project3D(cX + w, cY + h, zLevel, size);
    final p4 = project3D(cX - w, cY + h, zLevel, size);

    final slabPath = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy)..close();
    canvas.drawPath(slabPath, slabFillPaint);
    canvas.drawPath(slabPath, slabBorderPaint);

    // Floor Elevation Label
    final labelSpan = TextSpan(
      text: '$floorName (${(zLevel * 0.25).toStringAsFixed(1)}m)',
      style: TextStyle(
        color: isActive ? const Color(0xFF64B5F6) : Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(p1.dx + 8, p1.dy - 16));
  }

  void _drawFloorCorridors(Canvas canvas, Size size, String floorName, double zLevel, bool isActive) {
    final trackPoints = engine.floorTrackPoints[floorName] ?? [];
    if (trackPoints.length < 2) return;

    final corridorFloorPaint = Paint()
      ..color = isActive ? const Color(0x5564B5F6) : const Color(0x2264B5F6)
      ..strokeWidth = 3.2 * zoom
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final corridorWallPaint = Paint()
      ..color = isActive ? const Color(0x2281C784) : const Color(0x1181C784)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < trackPoints.length - 1; i++) {
      final pt1 = trackPoints[i];
      final pt2 = trackPoints[i + 1];

      final sp1 = project3D(pt1.x, pt1.y, zLevel, size);
      final sp2 = project3D(pt2.x, pt2.y, zLevel, size);

      // Hallway Centerline
      canvas.drawLine(sp1, sp2, corridorFloorPaint);

      // Extrude 3D Corridor Wall Slabs
      if (showCorridorWalls) {
        final wallTop1 = project3D(pt1.x, pt1.y, zLevel + 2.4, size);
        final wallTop2 = project3D(pt2.x, pt2.y, zLevel + 2.4, size);

        final wallQuad = Path()
          ..moveTo(sp1.dx, sp1.dy)
          ..lineTo(sp2.dx, sp2.dy)
          ..lineTo(wallTop2.dx, wallTop2.dy)
          ..lineTo(wallTop1.dx, wallTop1.dy)
          ..close();
        canvas.drawPath(wallQuad, corridorWallPaint);

        // Wall cap line
        final wallCapPaint = Paint()
          ..color = isActive ? const Color(0x6681C784) : const Color(0x2281C784)
          ..strokeWidth = 1.0;
        canvas.drawLine(wallTop1, wallTop2, wallCapPaint);
      }
    }
  }

  void _drawFloorRooms(Canvas canvas, Size size, String floorName, double zLevel, bool isActive) {
    final roomsOnFloor = engine.rooms.where((r) => r.floor == floorName).toList();

    for (final room in roomsOnFloor) {
      final base = project3D(room.x, room.y, zLevel, size);
      final top = project3D(room.x, room.y, zLevel + 2.8, size);

      Color pinColor = const Color(0xFF81C784);
      String icon = '🚪';

      if (room.category == RoomCategory.facultyOffice) {
        pinColor = const Color(0xFFFFD54F);
        icon = '👨‍🏫';
      } else if (room.category == RoomCategory.lab) {
        pinColor = const Color(0xFF4FC3F7);
        icon = '🔬';
      } else if (room.category == RoomCategory.staircase) {
        pinColor = const Color(0xFFFF8A65);
        icon = '🪜';
      } else if (room.category == RoomCategory.elevator) {
        pinColor = const Color(0xFFBA68C8);
        icon = '🛗';
      } else if (room.category == RoomCategory.restroom ||
          room.category == RoomCategory.restroomMale ||
          room.category == RoomCategory.restroomFemale) {
        pinColor = const Color(0xFFE57373);
        icon = '🚻';
      }

      // 3D Door Pillar
      final pillarPaint = Paint()
        ..color = pinColor.withValues(alpha: isActive ? 0.7 : 0.3)
        ..strokeWidth = 2.0;
      canvas.drawLine(base, top, pillarPaint);

      // Pin Head at Top
      final pinHeadPaint = Paint()
        ..color = pinColor.withValues(alpha: isActive ? 1.0 : 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(top, 6.0, pinHeadPaint);

      // Room label (only for active floor or if zoomed in)
      if (isActive) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$icon ${room.name}',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(top.dx - tp.width / 2, top.dy - 16));
      }
    }
  }

  void _drawVerticalPortals(Canvas canvas, Size size, double floorZSpacing) {
    final availableFloors = engine.availableFloors;
    if (availableFloors.length < 2) return;

    // Separate stairs and elevators
    final stairRooms = engine.rooms.where((r) => r.category == RoomCategory.staircase).toList();
    final elevatorRooms = engine.rooms.where((r) => r.category == RoomCategory.elevator).toList();

    // Group stairs by approximate (x, y) coordinates
    final renderedStairKeys = <String>{};
    for (final stair in stairRooms) {
      final key = '${stair.x.round()}_${stair.y.round()}';
      if (renderedStairKeys.contains(key)) continue;
      renderedStairKeys.add(key);

      // Render 3D stair flights for each floor transition
      for (int i = 0; i < availableFloors.length - 1; i++) {
        final double zBase = i * floorZSpacing;
        final double zTop = (i + 1) * floorZSpacing;
        _draw3DStaircase(canvas, size, stair.x, stair.y, zBase, zTop);
      }
    }

    // Group elevators by approximate (x, y) coordinates
    final renderedLiftKeys = <String>{};
    final activeFloorIdx = availableFloors.indexOf(engine.currentFloor);
    final activeFloorZ = (activeFloorIdx >= 0 ? activeFloorIdx : 0) * floorZSpacing;

    for (final lift in elevatorRooms) {
      final key = '${lift.x.round()}_${lift.y.round()}';
      if (renderedLiftKeys.contains(key)) continue;
      renderedLiftKeys.add(key);

      final double zBottom = 0.0;
      final double zTop = (availableFloors.length - 1) * floorZSpacing;
      _draw3DElevatorShaft(canvas, size, lift.x, lift.y, zBottom, zTop, activeFloorZ, floorZSpacing);
    }
  }

  void _draw3DStaircase(
    Canvas canvas,
    Size size,
    double sx,
    double sy,
    double zBase,
    double zTop,
  ) {
    const int stepCount = 10;
    final double dz = (zTop - zBase) / stepCount;
    const double stairLength = 50.0;
    const double stairWidth = 24.0;
    final double dxStep = stairLength / stepCount;

    final double startX = sx - stairLength / 2;
    final double y0 = sy - stairWidth / 2;
    final double y1 = sy + stairWidth / 2;

    // Paints
    final treadFillPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;

    final treadBorderPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final riserFillPaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;

    final handrailPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final balusterPaint = Paint()
      ..color = const Color(0xAAFFCC80)
      ..strokeWidth = 1.0;

    // 1. Draw Steps (Treads and Risers)
    for (int i = 0; i < stepCount; i++) {
      final double stepX0 = startX + i * dxStep;
      final double stepX1 = stepX0 + dxStep;
      final double stepZBottom = zBase + i * dz;
      final double stepZTop = stepZBottom + dz;

      // Vertical Riser face
      final rP1 = project3D(stepX0, y0, stepZBottom, size);
      final rP2 = project3D(stepX0, y1, stepZBottom, size);
      final rP3 = project3D(stepX0, y1, stepZTop, size);
      final rP4 = project3D(stepX0, y0, stepZTop, size);

      final riserPath = Path()
        ..moveTo(rP1.dx, rP1.dy)
        ..lineTo(rP2.dx, rP2.dy)
        ..lineTo(rP3.dx, rP3.dy)
        ..lineTo(rP4.dx, rP4.dy)
        ..close();
      canvas.drawPath(riserPath, riserFillPaint);
      canvas.drawPath(riserPath, treadBorderPaint);

      // Horizontal Tread face
      final tP1 = project3D(stepX0, y0, stepZTop, size);
      final tP2 = project3D(stepX1, y0, stepZTop, size);
      final tP3 = project3D(stepX1, y1, stepZTop, size);
      final tP4 = project3D(stepX0, y1, stepZTop, size);

      final treadPath = Path()
        ..moveTo(tP1.dx, tP1.dy)
        ..lineTo(tP2.dx, tP2.dy)
        ..lineTo(tP3.dx, tP3.dy)
        ..lineTo(tP4.dx, tP4.dy)
        ..close();
      canvas.drawPath(treadPath, treadFillPaint);
      canvas.drawPath(treadPath, treadBorderPaint);

      // Balusters (every 2 steps)
      if (i % 2 == 0) {
        final bBaseL = project3D(stepX0 + dxStep * 0.5, y0, stepZTop, size);
        final bTopL = project3D(stepX0 + dxStep * 0.5, y0, stepZTop + 1.8, size);
        canvas.drawLine(bBaseL, bTopL, balusterPaint);

        final bBaseR = project3D(stepX0 + dxStep * 0.5, y1, stepZTop, size);
        final bTopR = project3D(stepX0 + dxStep * 0.5, y1, stepZTop + 1.8, size);
        canvas.drawLine(bBaseR, bTopR, balusterPaint);
      }
    }

    // 2. Left & Right Continuous 3D Handrails
    const double railHeight = 1.8;
    final railLeftStart = project3D(startX, y0, zBase + railHeight, size);
    final railLeftEnd = project3D(startX + stairLength, y0, zTop + railHeight, size);
    canvas.drawLine(railLeftStart, railLeftEnd, handrailPaint);

    final railRightStart = project3D(startX, y1, zBase + railHeight, size);
    final railRightEnd = project3D(startX + stairLength, y1, zTop + railHeight, size);
    canvas.drawLine(railRightStart, railRightEnd, handrailPaint);

    // 3. Landings (Bottom & Top)
    final landingBottomP1 = project3D(startX - 12.0, y0, zBase, size);
    final landingBottomP2 = project3D(startX, y0, zBase, size);
    final landingBottomP3 = project3D(startX, y1, zBase, size);
    final landingBottomP4 = project3D(startX - 12.0, y1, zBase, size);
    final lPathBottom = Path()
      ..moveTo(landingBottomP1.dx, landingBottomP1.dy)
      ..lineTo(landingBottomP2.dx, landingBottomP2.dy)
      ..lineTo(landingBottomP3.dx, landingBottomP3.dy)
      ..lineTo(landingBottomP4.dx, landingBottomP4.dy)
      ..close();
    canvas.drawPath(lPathBottom, treadFillPaint);
    canvas.drawPath(lPathBottom, treadBorderPaint);

    final landingTopP1 = project3D(startX + stairLength, y0, zTop, size);
    final landingTopP2 = project3D(startX + stairLength + 12.0, y0, zTop, size);
    final landingTopP3 = project3D(startX + stairLength + 12.0, y1, zTop, size);
    final landingTopP4 = project3D(startX + stairLength, y1, zTop, size);
    final lPathTop = Path()
      ..moveTo(landingTopP1.dx, landingTopP1.dy)
      ..lineTo(landingTopP2.dx, landingTopP2.dy)
      ..lineTo(landingTopP3.dx, landingTopP3.dy)
      ..lineTo(landingTopP4.dx, landingTopP4.dy)
      ..close();
    canvas.drawPath(lPathTop, treadFillPaint);
    canvas.drawPath(lPathTop, treadBorderPaint);
  }

  void _draw3DElevatorShaft(
    Canvas canvas,
    Size size,
    double lx,
    double ly,
    double zBottom,
    double zTop,
    double activeFloorZ,
    double floorZSpacing,
  ) {
    const double radius = 16.0;
    final pX0 = lx - radius;
    final pX1 = lx + radius;
    final pY0 = ly - radius;
    final pY1 = ly + radius;

    // Corner Guide Columns
    final colPaint = Paint()
      ..color = const Color(0xFFBA68C8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final corners = [
      [pX0, pY0],
      [pX1, pY0],
      [pX1, pY1],
      [pX0, pY1],
    ];

    for (final c in corners) {
      final b = project3D(c[0], c[1], zBottom, size);
      final t = project3D(c[0], c[1], zTop + 3.0, size);
      canvas.drawLine(b, t, colPaint);
    }

    // Glass shaft wall panes
    final glassPaint = Paint()
      ..color = const Color(0x18BA68C8)
      ..style = PaintingStyle.fill;

    final gP1 = project3D(pX0, pY0, zBottom, size);
    final gP2 = project3D(pX1, pY0, zBottom, size);
    final gP3 = project3D(pX1, pY0, zTop + 3.0, size);
    final gP4 = project3D(pX0, pY0, zTop + 3.0, size);
    final glassWall = Path()
      ..moveTo(gP1.dx, gP1.dy)
      ..lineTo(gP2.dx, gP2.dy)
      ..lineTo(gP3.dx, gP3.dy)
      ..lineTo(gP4.dx, gP4.dy)
      ..close();
    canvas.drawPath(glassWall, glassPaint);

    // Floor rings
    final ringPaint = Paint()
      ..color = const Color(0x66BA68C8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double z = zBottom; z <= zTop + 0.1; z += floorZSpacing) {
      final r1 = project3D(pX0, pY0, z, size);
      final r2 = project3D(pX1, pY0, z, size);
      final r3 = project3D(pX1, pY1, z, size);
      final r4 = project3D(pX0, pY1, z, size);
      final ringPath = Path()..moveTo(r1.dx, r1.dy)..lineTo(r2.dx, r2.dy)..lineTo(r3.dx, r3.dy)..lineTo(r4.dx, r4.dy)..close();
      canvas.drawPath(ringPath, ringPaint);
    }

    // Elevator Cab (Volumetric Cube at active floor)
    const double cabHalf = 13.0;
    const double cabHeight = 2.4;
    final c1 = project3D(lx - cabHalf, ly - cabHalf, activeFloorZ, size);
    final c2 = project3D(lx + cabHalf, ly - cabHalf, activeFloorZ, size);
    final c3 = project3D(lx + cabHalf, ly + cabHalf, activeFloorZ, size);
    final c4 = project3D(lx - cabHalf, ly + cabHalf, activeFloorZ, size);

    final cTop1 = project3D(lx - cabHalf, ly - cabHalf, activeFloorZ + cabHeight, size);
    final cTop2 = project3D(lx + cabHalf, ly - cabHalf, activeFloorZ + cabHeight, size);
    final cTop3 = project3D(lx + cabHalf, ly + cabHalf, activeFloorZ + cabHeight, size);
    final cTop4 = project3D(lx - cabHalf, ly + cabHalf, activeFloorZ + cabHeight, size);

    final cabPaint = Paint()
      ..color = const Color(0x44CE93D8)
      ..style = PaintingStyle.fill;
    final cabBorder = Paint()
      ..color = const Color(0xFFE1BEE7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cabFloor = Path()..moveTo(c1.dx, c1.dy)..lineTo(c2.dx, c2.dy)..lineTo(c3.dx, c3.dy)..lineTo(c4.dx, c4.dy)..close();
    final cabRoof = Path()..moveTo(cTop1.dx, cTop1.dy)..lineTo(cTop2.dx, cTop2.dy)..lineTo(cTop3.dx, cTop3.dy)..lineTo(cTop4.dx, cTop4.dy)..close();
    canvas.drawPath(cabFloor, cabPaint);
    canvas.drawPath(cabRoof, cabPaint);
    canvas.drawPath(cabRoof, cabBorder);

    // Cab corner posts
    canvas.drawLine(c1, cTop1, cabBorder);
    canvas.drawLine(c2, cTop2, cabBorder);
    canvas.drawLine(c3, cTop3, cabBorder);
    canvas.drawLine(c4, cTop4, cabBorder);

    // Cab Light & Icon
    final cabCenter = project3D(lx, ly, activeFloorZ + cabHeight / 2, size);
    final glowPaint = Paint()..color = const Color(0xAAFFD54F);
    canvas.drawCircle(cabCenter, 4.0, glowPaint);
  }

  void _draw3DSurveyor(Canvas canvas, Size size, double userZ, double floorZSpacing) {
    double currentX = engine.currentX;
    double currentY = engine.currentY;
    double currentZ = userZ;
    final bool isClimbing = climbProgress > 0.0;

    if (isClimbing) {
      final availableFloors = engine.availableFloors;
      final fromIdx = availableFloors.indexOf(climbFromFloor ?? engine.currentFloor);
      final toIdx = availableFloors.indexOf(climbToFloor ?? (fromIdx + 1 < availableFloors.length ? availableFloors[fromIdx + 1] : availableFloors.first));

      final double zStart = (fromIdx >= 0 ? fromIdx : 0) * floorZSpacing;
      final double zEnd = (toIdx >= 0 ? toIdx : (fromIdx + 1)) * floorZSpacing;

      // Find nearest staircase or use first stair room
      final stairs = engine.rooms.where((r) => r.category == RoomCategory.staircase).toList();
      RoomNode? activeStair;
      if (stairs.isNotEmpty) {
        stairs.sort((a, b) {
          final da = (a.x - engine.currentX) * (a.x - engine.currentX) + (a.y - engine.currentY) * (a.y - engine.currentY);
          final db = (b.x - engine.currentX) * (b.x - engine.currentX) + (b.y - engine.currentY) * (b.y - engine.currentY);
          return da.compareTo(db);
        });
        activeStair = stairs.first;
      }

      final sx = activeStair?.x ?? engine.currentX;
      final sy = activeStair?.y ?? engine.currentY;

      // Smooth step climbing interpolation along the stair run
      const double stairLength = 50.0;
      final double startX = sx - stairLength / 2;
      currentX = startX + stairLength * climbProgress;
      currentY = sy;

      // Rhythmic step bounce oscillation
      final double bounce = (math.sin(climbProgress * 20 * math.pi)).abs() * 0.35;
      currentZ = zStart + (zEnd - zStart) * climbProgress + bounce;
    }

    final avatarBase = project3D(currentX, currentY, currentZ, size);
    final avatarTop = project3D(currentX, currentY, currentZ + 2.0, size);

    // Glowing step ring on current tread/floor
    final glowColor = isClimbing ? const Color(0xFFFFB74D) : const Color(0xFF81C784);
    final glowPaint = Paint()..color = glowColor.withValues(alpha: 0.35);
    canvas.drawCircle(avatarBase, 16.0 * zoom, glowPaint);

    // Surveyor Pillar Body
    final userPillarPaint = Paint()
      ..color = glowColor
      ..strokeWidth = 2.8;
    canvas.drawLine(avatarBase, avatarTop, userPillarPaint);

    // Avatar Head Sphere
    final spherePaint = Paint()..color = glowColor;
    canvas.drawCircle(avatarTop, 7.0, spherePaint);

    if (isClimbing) {
      // Climbing Step Rings (Footprints)
      final footPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(avatarBase, 6.0, footPaint);

      // Stabilized Climbing Indicator Badge
      final tp = TextPainter(
        text: TextSpan(
          text: '🪜 Ascending to $climbToFloor (${(climbProgress * 100).toInt()}%)',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(avatarTop.dx - tp.width / 2, avatarTop.dy - 22));
    } else {
      // Normal Heading Direction Arrow
      final double headingRad = (engine.currentHeadingDeg - 90) * math.pi / 180.0;
      const double coneDist = 28.0;
      final coneX = currentX + math.cos(headingRad) * coneDist;
      final coneY = currentY + math.sin(headingRad) * coneDist;
      final coneScreen = project3D(coneX, coneY, currentZ + 1.0, size);

      final conePaint = Paint()
        ..color = const Color(0xFF64B5F6)
        ..strokeWidth = 2.0;
      canvas.drawLine(avatarTop, coneScreen, conePaint);
      canvas.drawCircle(coneScreen, 4.0, conePaint);

      // User Tag
      final tp = TextPainter(
        text: const TextSpan(
          text: '📍 You are Here',
          style: TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(avatarTop.dx - tp.width / 2, avatarTop.dy - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _Building3DPainter oldDelegate) => true;
}
