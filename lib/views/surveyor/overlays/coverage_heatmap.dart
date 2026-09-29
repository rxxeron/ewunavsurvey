import 'package:flutter/material.dart';
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';

class CoverageHeatmapPainter extends CustomPainter {
  final SlamSurveyorEngine engine;

  CoverageHeatmapPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    if (!engine.hasActiveBuilding || engine.activeSurvey == null) return;
    final survey = engine.activeSurvey!;
    
    // Grid size 2m x 2m
    final double cellSize = 2.0 * engine.config.pixelsPerMeter;
    
    // Simple count of edges crossing a cell
    final Map<String, int> cellPassCounts = {};
    for (final e in survey.edges) {
      if (e.fromId.startsWith('node_${survey.currentFloor}')) {
        final parts = e.fromId.split('_');
        if (parts.length >= 4) {
          double x = double.parse(parts[2]);
          double y = double.parse(parts[3]);
          int gridX = (x / cellSize).floor();
          int gridY = (y / cellSize).floor();
          String key = '$gridX:$gridY';
          cellPassCounts[key] = (cellPassCounts[key] ?? 0) + e.passCount;
        }
      }
    }

    final Paint paint = Paint()..style = PaintingStyle.fill;
    
    for (final entry in cellPassCounts.entries) {
      final parts = entry.key.split(':');
      final int gridX = int.parse(parts[0]);
      final int gridY = int.parse(parts[1]);
      final int passes = entry.value;
      
      if (passes == 1) {
        paint.color = Colors.orange.withValues(alpha: 0.4);
      } else if (passes >= 2 && passes <= 3) {
        paint.color = Colors.yellow.withValues(alpha: 0.4);
      } else if (passes >= 4) {
        paint.color = Colors.green.withValues(alpha: 0.4);
      }
      
      canvas.drawRect(
        Rect.fromLTWH(gridX * cellSize, gridY * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CoverageHeatmapPainter oldDelegate) => true;
}
