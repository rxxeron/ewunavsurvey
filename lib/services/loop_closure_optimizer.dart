import 'dart:math' as math;
import 'slam_surveyor_engine.dart';

class LoopClosureOptimizer {
  /// Closes a loop between the current position and a target landmark or starting point.
  /// Uses simple linear interpolation weight distribution to correct drift over the walked path segment.
  static bool optimizeLoop({
    required SlamSurveyorEngine engine,
    required double targetX,
    required double targetY,
  }) {
    final List<SurveyCorridorPoint>? points = engine.floorTrackPoints[engine.currentFloor];
    if (points == null || points.length < 4) {
      return false; // Not enough points to form a loop
    }

    final double endX = engine.currentX;
    final double endY = engine.currentY;

    // Residual error vector
    final double deltaX = targetX - endX;
    final double deltaY = targetY - endY;
    final double driftDistance = math.sqrt(deltaX * deltaX + deltaY * deltaY);

    // If drift is within reasonable bounds (e.g. < 15 meters)
    if (driftDistance > 15.0 * engine.pixelsPerMeter) {
      return false; // Error too large to be an automatic loop closure
    }

    final int n = points.length;
    // Snapshot of original coordinates for nearest-vertex projection
    final List<math.Point<double>> orig = points.map((p) => math.Point(p.x, p.y)).toList();

    // 1. Linearly distribute drift error across all path vertices
    for (int i = 0; i < n; i++) {
      final double weight = (i / (n - 1));
      final double adjustedX = points[i].x + (deltaX * weight);
      final double adjustedY = points[i].y + (deltaY * weight);

      points[i] = SurveyCorridorPoint(
        x: adjustedX,
        y: adjustedY,
        floor: points[i].floor,
        headingDeg: points[i].headingDeg,
      );
    }

    // 2. Adjust step log coordinates on this floor to match corrected trajectory
    final stepLogs = engine.stepLogs;
    for (int s = 0; s < stepLogs.length; s++) {
      final step = stepLogs[s];
      if (step.floor == engine.currentFloor) {
        int bestIdx = 0;
        double bestDist = double.infinity;
        for (int i = 0; i < orig.length; i++) {
          final d = orig[i].distanceTo(math.Point(step.x, step.y));
          if (d < bestDist) {
            bestDist = d;
            bestIdx = i;
          }
        }
        final double weight = bestIdx / (n - 1);
        stepLogs[s] = step.copyWith(
          x: step.x + (deltaX * weight),
          y: step.y + (deltaY * weight),
        );
      }
    }

    // 3. Adjust room vertex coordinates on this floor
    for (final room in engine.rooms) {
      if (room.floor == engine.currentFloor) {
        int bestIdx = 0;
        double bestDist = double.infinity;
        for (int i = 0; i < orig.length; i++) {
          final d = orig[i].distanceTo(math.Point(room.x, room.y));
          if (d < bestDist) {
            bestDist = d;
            bestIdx = i;
          }
        }
        final double weight = bestIdx / (n - 1);
        room.x += (deltaX * weight);
        room.y += (deltaY * weight);
      }
    }

    // Set current surveyor position strictly to target coordinate
    engine.currentX = targetX;
    engine.currentY = targetY;
    engine.notifyEngineUpdate();
    return true;
  }
}
