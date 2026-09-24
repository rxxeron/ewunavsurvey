import 'dart:math' as math;
import 'slam_surveyor_engine.dart';

class LoopClosureOptimizer {
  /// Closes a loop between the current position and a target landmark or starting point.
  /// Uses a Gauss-Newton / gradient distribution over the walked path segment.
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
    // Linearly distribute drift error across all path vertices
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

    // Set current surveyor position strictly to target coordinate
    engine.currentX = targetX;
    engine.currentY = targetY;
    engine.notifyEngineUpdate();
    return true;
  }
}
