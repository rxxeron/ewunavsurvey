import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/room_node.dart';
import '../../models/area_zone.dart';
import '../../services/slam_surveyor_engine.dart';

class SurveyorCanvas extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final Function(RoomNode room)? onRoomDeleted;

  const SurveyorCanvas({
    super.key,
    required this.engine,
    this.onRoomDeleted,
  });

  @override
  State<SurveyorCanvas> createState() => _SurveyorCanvasState();
}

class _SurveyorCanvasState extends State<SurveyorCanvas> {
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  void _zoomIn() => setState(() => _zoom = (_zoom * 1.25).clamp(0.3, 3.5));
  void _zoomOut() => setState(() => _zoom = (_zoom / 1.25).clamp(0.3, 3.5));
  void _recenter() => setState(() {
    _zoom = 1.0;
    _pan = Offset.zero;
  });

  void _handleTap(TapUpDetails details, Size size) {
    if (!widget.engine.hasActiveBuilding) return;

    // Inverse transform from viewport to world coordinates
    final double wx = (details.localPosition.dx - size.width / 2 - _pan.dx) / _zoom + widget.engine.currentX;
    final double wy = (details.localPosition.dy - size.height / 2 - _pan.dy) / _zoom + widget.engine.currentY;

    // Find any room node on current floor within tap radius
    final roomsOnFloor = widget.engine.rooms.where((r) => r.floor == widget.engine.currentFloor).toList();
    RoomNode? tapped;
    const double tapRadius = 24.0; // World pixels (~0.85m)

    for (final room in roomsOnFloor.reversed) {
      final dist = math.sqrt(math.pow(room.x - wx, 2) + math.pow(room.y - wy, 2));
      if (dist <= tapRadius) {
        tapped = room;
        break;
      }
    }

    if (tapped != null) {
      _showRoomInspectionDialog(tapped);
    }
  }

  void _showRoomInspectionDialog(RoomNode room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Row(
          children: [
            const Icon(Icons.meeting_room, color: Color(0xFF81C784), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                room.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Room Number', room.roomNumber ?? 'N/A'),
            _buildDetailRow('Floor', room.floor),
            _buildDetailRow('Category', room.category.name.toUpperCase()),
            _buildDetailRow('Department', room.department),
            _buildDetailRow('Door Side', room.doorSide.toUpperCase()),
            _buildDetailRow('Capacity', '${room.studentCapacity} seats'),
            _buildDetailRow('Coordinates', 'X: ${room.x.round()}, Y: ${room.y.round()}'),
            if (room.altitudeMeters != null)
              _buildDetailRow('Altitude', '${room.altitudeMeters!.toStringAsFixed(1)}m (Elev: ${room.floorHeightMeters?.toStringAsFixed(1)}m)'),
            const Divider(color: Colors.white24, height: 16),
            const Text(
              'Entry Management',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can delete this tagged door/room entry if it was placed incorrectly.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.delete, size: 16, color: Colors.white),
            label: const Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              widget.engine.deleteRoom(room.id);
              widget.onRoomDeleted?.call(room);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF8B0000),
                  content: Text('Deleted room "${room.name}" from survey.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pan += details.delta;
                });
              },
              onTapUp: (details) => _handleTap(details, size),
              child: AnimatedBuilder(
                animation: widget.engine,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _SurveyorPainter(
                      engine: widget.engine,
                      zoom: _zoom,
                      pan: _pan,
                    ),
                  );
                },
              ),
            ),

            // Floating Viewport Controls (Bottom Right)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'canvas_recenter',
                    backgroundColor: const Color(0xFF1E2235),
                    foregroundColor: const Color(0xFF64B5F6),
                    tooltip: 'Recenter on Surveyor',
                    onPressed: _recenter,
                    child: const Icon(Icons.my_location, size: 18),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'canvas_zoom_in',
                    backgroundColor: const Color(0xFF1E2235),
                    foregroundColor: Colors.white,
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add, size: 18),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'canvas_zoom_out',
                    backgroundColor: const Color(0xFF1E2235),
                    foregroundColor: Colors.white,
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove, size: 18),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SurveyorPainter extends CustomPainter {
  final SlamSurveyorEngine engine;
  final double zoom;
  final Offset pan;

  _SurveyorPainter({
    required this.engine,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F111A);
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (!engine.hasActiveBuilding) {
      final span = const TextSpan(
        text: '🏢 No Building Active\nClick "+ New Building" to start surveying.',
        style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
      );
      final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    canvas.save();
    // 1. Center camera on current surveyor position + user pan & zoom
    canvas.translate(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    canvas.scale(zoom);
    canvas.translate(-engine.currentX, -engine.currentY);

    // 2. Infinite Architectural Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1D2E)
      ..strokeWidth = 1.0;

    const double gridSize = 40.0;
    const double worldBound = 2500.0;

    for (double x = -worldBound; x <= worldBound; x += gridSize) {
      canvas.drawLine(Offset(x, -worldBound), Offset(x, worldBound), gridPaint);
    }
    for (double y = -worldBound; y <= worldBound; y += gridSize) {
      canvas.drawLine(Offset(-worldBound, y), Offset(worldBound, y), gridPaint);
    }

    // 3. Draw Survey Origin Marker (400, 400)
    final originPaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(engine.originX, engine.originY), 10.0, originPaint);
    final originSpan = TextSpan(
      text: '🚩 Origin (${engine.originX.round()}, ${engine.originY.round()})',
      style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 10, fontWeight: FontWeight.bold),
    );
    final originPainter = TextPainter(text: originSpan, textDirection: TextDirection.ltr)..layout();
    originPainter.paint(canvas, Offset(engine.originX + 14, engine.originY - 6));


    // 3.5 Draw Enclosed Area Zones (Courtyards, Rooftops, Hallways)
    final zonesOnFloor = engine.zones.where((z) => z.floor == engine.currentFloor).toList();
    for (var zone in zonesOnFloor) {
      if (zone.points.length < 3) continue;

      final zonePath = Path();
      zonePath.moveTo(zone.points.first.x, zone.points.first.y);
      for (int i = 1; i < zone.points.length; i++) {
        zonePath.lineTo(zone.points[i].x, zone.points[i].y);
      }
      zonePath.close();

      // Translucent fill
      final fillPaint = Paint()
        ..color = Color(zone.category.defaultFillColorInt)
        ..style = PaintingStyle.fill;
      canvas.drawPath(zonePath, fillPaint);

      // Boundary stroke
      final strokePaint = Paint()
        ..color = Color(zone.category.defaultStrokeColorInt)
        ..strokeWidth = (zone.category == ZoneCategory.hallway) ? 3.0 : 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(zonePath, strokePaint);

      // Centroid Badge
      final centroid = zone.centroid;
      final areaBadgeSpan = TextSpan(
        text: '${zone.category.displayName}\n${zone.name} (${zone.areaSqMeters.toStringAsFixed(1)} m²)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );
      final badgePainter = TextPainter(
        text: areaBadgeSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = Rect.fromCenter(
        center: Offset(centroid.x, centroid.y),
        width: badgePainter.width + 16,
        height: badgePainter.height + 10,
      );
      final badgeBgPaint = Paint()
        ..color = const Color(0xDD141624)
        ..style = PaintingStyle.fill;
      final badgeBorderPaint = Paint()
        ..color = Color(zone.category.defaultStrokeColorInt)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), badgeBgPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), badgeBorderPaint);
      badgePainter.paint(
        canvas,
        Offset(centroid.x - badgePainter.width / 2, centroid.y - badgePainter.height / 2),
      );
    }

    // Draw Candidate Loop if detected
    if (engine.pendingLoopCandidate != null) {
      final cand = engine.pendingLoopCandidate!;
      if (cand.points.length >= 3) {
        final candPath = Path();
        candPath.moveTo(cand.points.first.x, cand.points.first.y);
        for (int i = 1; i < cand.points.length; i++) {
          candPath.lineTo(cand.points[i].x, cand.points[i].y);
        }
        candPath.close();

        final candFill = Paint()
          ..color = const Color(0x33FFD54F)
          ..style = PaintingStyle.fill;
        canvas.drawPath(candPath, candFill);

        final candStroke = Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(candPath, candStroke);
      }
    }

    // 4. Draw Existing Graph Corridor Edges on this floor
    final roomMap = {for (var r in engine.rooms) r.id: r};
    final edgePaint = Paint()
      ..color = const Color(0x3364B5F6)
      ..strokeWidth = 2.0 * engine.pixelsPerMeter
      ..strokeCap = StrokeCap.round;
    final edgeCenterline = Paint()
      ..color = const Color(0xFF64B5F6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (var edge in engine.edges) {
      final fromRoom = roomMap[edge.fromId];
      final toRoom = roomMap[edge.toId];
      if (fromRoom != null && toRoom != null && fromRoom.floor == engine.currentFloor && toRoom.floor == engine.currentFloor) {
        final p1 = Offset(fromRoom.x, fromRoom.y);
        final p2 = Offset(toRoom.x, toRoom.y);
        canvas.drawLine(p1, p2, edgePaint);
        canvas.drawLine(p1, p2, edgeCenterline);
      }
    }

    // 5. Draw Active Walked Corridor Polylines
    final points = engine.floorTrackPoints[engine.currentFloor] ?? [];
    if (points.length > 1) {
      final corridorWallPaint = Paint()
        ..color = const Color(0x3364B5F6)
        ..strokeWidth = 2.2 * engine.pixelsPerMeter
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(points.first.x, points.first.y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
      canvas.drawPath(path, corridorWallPaint);

      final centerlinePaint = Paint()
        ..color = const Color(0xFF64B5F6)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, centerlinePaint);
    }

    // 6. Draw Step Breadcrumbs & Comments
    final floorSteps = engine.stepLogs.where((s) => s.floor == engine.currentFloor).toList();
    final stepDotPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;

    for (var step in floorSteps) {
      canvas.drawCircle(Offset(step.x, step.y), 3.5, stepDotPaint);

      // Comment speech bubble marker
      if (step.comment != null && step.comment!.trim().isNotEmpty) {
        final bubblePaint = Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(step.x, step.y - 14), 8.0, bubblePaint);

        final commentSpan = TextSpan(
          text: '💬 ${step.comment}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xFFFFD54F),
          ),
        );
        final commentPainter = TextPainter(
          text: commentSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        commentPainter.paint(canvas, Offset(step.x + 10, step.y - 20));
      }
    }

    // 7. Draw Room Doors & Landmarks on current floor
    final currentFloorRooms = engine.rooms.where((r) => r.floor == engine.currentFloor).toList();
    for (var room in currentFloorRooms) {
      Color pinColor = const Color(0xFF81C784); // classroom green
      String icon = '🚪';

      if (room.category == RoomCategory.facultyOffice) {
        pinColor = const Color(0xFFFFD54F); // faculty amber
        icon = '👨‍🏫';
      } else if (room.category == RoomCategory.lab) {
        pinColor = const Color(0xFF4FC3F7); // lab cyan
        icon = '🔬';
      } else if (room.category == RoomCategory.staircase) {
        pinColor = const Color(0xFFFF8A65); // stair orange
        icon = '🪜';
      } else if (room.category == RoomCategory.elevator) {
        pinColor = const Color(0xFFBA68C8); // elevator purple
        icon = '🛗';
      } else if (room.category == RoomCategory.restroom) {
        pinColor = const Color(0xFFE57373); // restroom pink
        icon = '🚻';
      } else if (room.category == RoomCategory.deadEnd) {
        pinColor = const Color(0xFFEF5350); // dead-end wall red
        icon = '🚫';
      }

      // Draw Architectural Wall Cap for Dead Ends
      if (room.category == RoomCategory.deadEnd) {
        final wallCapPaint = Paint()
          ..color = const Color(0xFFEF5350)
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.square;
        canvas.drawLine(
          Offset(room.x - 18, room.y),
          Offset(room.x + 18, room.y),
          wallCapPaint,
        );
      }

      // Draw Door Pin
      final pinPaint = Paint()..color = pinColor;
      canvas.drawCircle(Offset(room.x, room.y), 13.0, pinPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFF0F111A)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(room.x, room.y), 13.0, borderPaint);

      // Room Label Text
      final textSpan = TextSpan(
        text: '$icon ${room.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(room.x - textPainter.width / 2, room.y - 28));
    }

    // 8. Draw Current Walking Avatar & Direction Arrow
    canvas.save();
    canvas.translate(engine.currentX, engine.currentY);
    canvas.rotate((engine.currentHeadingDeg - 90) * math.pi / 180.0);

    // Pulse outer circle
    final pulsePaint = Paint()..color = const Color(0x4481C784);
    canvas.drawCircle(Offset.zero, 20.0, pulsePaint);

    // Compass arrow pointer
    final arrowPaint = Paint()..color = const Color(0xFF81C784);
    final arrowPath = Path()
      ..moveTo(16, 0)
      ..lineTo(-10, -9)
      ..lineTo(-6, 0)
      ..lineTo(-10, 9)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SurveyorPainter oldDelegate) => true;
}
