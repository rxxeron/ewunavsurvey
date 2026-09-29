/// Heading snap modes and coordinate math for indoor corridor alignment.
enum HeadingSnapMode {
  manhattan90, // 0, 90, 180, 270 (Default orthogonal)
  diagonal45,  // 0, 45, 90, 135, 180, 225, 270, 315
  freeAngle,   // Continuous free-space heading without snapping
}

/// Pure mathematical calculation engine for indoor heading quantization and baseline transformation.
class HeadingCalculator {
  /// Snaps a raw angle to the appropriate axis given the mode and building baseline.
  static double snapHeading(double rawDeg, HeadingSnapMode mode, {double baselineDeg = 0.0}) {
    switch (mode) {
      case HeadingSnapMode.manhattan90:
        final relativeAngle = (rawDeg - baselineDeg + 360) % 360;
        final quadrant = (relativeAngle / 90.0).round() % 4;
        return (baselineDeg + quadrant * 90.0 + 360) % 360;
      case HeadingSnapMode.diagonal45:
        final relativeAngle = (rawDeg - baselineDeg + 360) % 360;
        final octant = (relativeAngle / 45.0).round() % 8;
        return (baselineDeg + octant * 45.0 + 360) % 360;
      case HeadingSnapMode.freeAngle:
        return (rawDeg % 360 + 360) % 360;
    }
  }

  /// Calculates relative angle with respect to building baseline
  static double getRelativeHeading(double headingDeg, double baselineDeg) {
    return (headingDeg - baselineDeg + 360) % 360;
  }
}
