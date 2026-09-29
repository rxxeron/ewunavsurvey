/// Centralized ADA (Americans with Disabilities Act) accessibility constants.
/// Based on 2010 ADA Standards for Accessible Design.
class AdaConstants {
  AdaConstants._();

  /// Minimum corridor width (Section 403.5.1) — 36 inches
  static const double minCorridorWidthMeters = 0.915;

  /// Minimum door clear opening width (Section 404.2.3) — 32 inches  
  static const double minDoorClearWidthMeters = 0.815;

  /// Maximum running slope for ramps (Section 405.2) — 1:12 ratio
  static const double maxRunningSlopePercent = 8.33;

  /// Maximum cross slope (Section 403.3 / 405.3) — 1:48 ratio
  static const double maxCrossSlopePercent = 2.08;

  /// Maximum threshold height (Section 404.2.5) — 0.5 inches beveled
  static const double maxThresholdHeightMm = 13.0;

  /// Check if a running slope value violates ADA maximum
  static bool isSlopeViolation(double? slopePercent) =>
      slopePercent != null && slopePercent.abs() > maxRunningSlopePercent;

  /// Check if a cross slope value violates ADA maximum  
  static bool isCrossSlopeViolation(double? crossSlopePercent) =>
      crossSlopePercent != null && crossSlopePercent.abs() > maxCrossSlopePercent;

  /// Check if corridor width violates ADA minimum
  static bool isWidthViolation(double? widthMeters) =>
      widthMeters != null && widthMeters < minCorridorWidthMeters;

  /// Check if door clear width violates ADA minimum
  static bool isDoorWidthViolation(double? clearWidthMeters) =>
      clearWidthMeters != null && clearWidthMeters < minDoorClearWidthMeters;

  /// Check if threshold height violates ADA maximum
  static bool isThresholdViolation(double? thresholdHeightMm) =>
      thresholdHeightMm != null && thresholdHeightMm > maxThresholdHeightMm;
}
