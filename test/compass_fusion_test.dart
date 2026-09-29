import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/heading_snap_mode.dart';

void main() {
  group('HeadingCalculator & HeadingSnapMode Snapping & Baseline Math', () {
    test('Manhattan 90° snapping quantizes angles to nearest orthogonal cardinal (0, 90, 180, 270)', () {
      expect(HeadingCalculator.snapHeading(0.0, HeadingSnapMode.manhattan90), 0.0);
      expect(HeadingCalculator.snapHeading(15.0, HeadingSnapMode.manhattan90), 0.0);
      expect(HeadingCalculator.snapHeading(345.0, HeadingSnapMode.manhattan90), 0.0);

      expect(HeadingCalculator.snapHeading(78.0, HeadingSnapMode.manhattan90), 90.0);
      expect(HeadingCalculator.snapHeading(112.0, HeadingSnapMode.manhattan90), 90.0);

      expect(HeadingCalculator.snapHeading(160.0, HeadingSnapMode.manhattan90), 180.0);
      expect(HeadingCalculator.snapHeading(210.0, HeadingSnapMode.manhattan90), 180.0);

      expect(HeadingCalculator.snapHeading(250.0, HeadingSnapMode.manhattan90), 270.0);
      expect(HeadingCalculator.snapHeading(300.0, HeadingSnapMode.manhattan90), 270.0);
    });

    test('Diagonal 45° snapping quantizes angles to 8-way octants (0, 45, 90, 135, 180, 225, 270, 315)', () {
      expect(HeadingCalculator.snapHeading(12.0, HeadingSnapMode.diagonal45), 0.0);
      expect(HeadingCalculator.snapHeading(38.0, HeadingSnapMode.diagonal45), 45.0);
      expect(HeadingCalculator.snapHeading(52.0, HeadingSnapMode.diagonal45), 45.0);
      expect(HeadingCalculator.snapHeading(88.0, HeadingSnapMode.diagonal45), 90.0);
      expect(HeadingCalculator.snapHeading(140.0, HeadingSnapMode.diagonal45), 135.0);
      expect(HeadingCalculator.snapHeading(175.0, HeadingSnapMode.diagonal45), 180.0);
      expect(HeadingCalculator.snapHeading(220.0, HeadingSnapMode.diagonal45), 225.0);
      expect(HeadingCalculator.snapHeading(272.0, HeadingSnapMode.diagonal45), 270.0);
      expect(HeadingCalculator.snapHeading(318.0, HeadingSnapMode.diagonal45), 315.0);
      expect(HeadingCalculator.snapHeading(350.0, HeadingSnapMode.diagonal45), 0.0);
    });

    test('Free-Angle mode preserves exact fractional degrees without snapping', () {
      expect(HeadingCalculator.snapHeading(17.42, HeadingSnapMode.freeAngle), closeTo(17.42, 0.001));
      expect(HeadingCalculator.snapHeading(123.7, HeadingSnapMode.freeAngle), closeTo(123.7, 0.001));
      expect(HeadingCalculator.snapHeading(341.9, HeadingSnapMode.freeAngle), closeTo(341.9, 0.001));
    });

    test('Building baseline offset rotates grid relative heading properly', () {
      const baseline = 30.0;

      // If phone faces 30° True North, relative building heading is 0°
      expect(HeadingCalculator.getRelativeHeading(30.0, baseline), closeTo(0.0, 0.001));

      // If phone faces 120° True North, relative building heading is 90°
      expect(HeadingCalculator.getRelativeHeading(120.0, baseline), closeTo(90.0, 0.001));

      // If phone faces 10° True North, relative building heading is 340° (-20° + 360)
      expect(HeadingCalculator.getRelativeHeading(10.0, baseline), closeTo(340.0, 0.001));

      // Snapping with baseline offset
      expect(HeadingCalculator.snapHeading(35.0, HeadingSnapMode.manhattan90, baselineDeg: baseline), 30.0);
      expect(HeadingCalculator.snapHeading(122.0, HeadingSnapMode.manhattan90, baselineDeg: baseline), 120.0);
    });
  });
}
