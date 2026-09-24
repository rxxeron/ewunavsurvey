import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/services/pdr_engine.dart';

void main() {
  test('PDR step detection registers steps on vertical acceleration cycles', () async {
    final pdr = PdrEngine();
    int detectedSteps = 0;
    pdr.stepStream.listen((event) {
      detectedSteps = event.stepCount;
    });

    int timeMs = 1000;
    // Simulate 3 realistic walking step cycles at 50 Hz (20ms per sample)
    for (int step = 0; step < 3; step++) {
      // Foot lift (acceleration rises above gravity for ~120ms)
      for (int i = 0; i < 8; i++) {
        pdr.processAccelerometerSample(0.0, 0.0, 13.0, timeMs);
        timeMs += 20;
      }
      // Foot landing (impact and valley for ~160ms)
      for (int i = 0; i < 8; i++) {
        pdr.processAccelerometerSample(0.0, 0.0, 6.5, timeMs);
        timeMs += 20;
      }
      timeMs += 200; // refractory period
    }

    await Future.delayed(const Duration(milliseconds: 20));

    expect(detectedSteps, greaterThanOrEqualTo(1));
    expect(pdr.totalDistanceMeters, greaterThan(0.0));
  });

  test('PDR manual step records stride correctly', () {
    final pdr = PdrEngine();
    pdr.recordManualStep(0.75);
    pdr.recordManualStep(0.75);

    expect(pdr.stepCount, 2);
    expect(pdr.totalDistanceMeters, 1.5);
  });
}
