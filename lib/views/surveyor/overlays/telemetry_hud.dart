import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../models/step_log_record.dart';

class TelemetryHud extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final StepLogRecord? latestStep;

  const TelemetryHud({
    super.key,
    required this.engine,
    this.latestStep,
  });

  @override
  Widget build(BuildContext context) {
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
              'Steps: ${engine.pdrEngine.stepCount} | Dist: ${engine.pdrEngine.totalDistanceMeters.toStringAsFixed(1)}m | Heading: ${engine.currentHeadingDeg.round()}°',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Lat: ${(latestStep?.latitude ?? engine.currentBuildingLat).toStringAsFixed(6)}° | '
              'Lng: ${(latestStep?.longitude ?? engine.currentBuildingLng).toStringAsFixed(6)}° | '
              'H: ${(latestStep?.floorHeightMeters ?? 0.0).toStringAsFixed(1)}m (Alt: ${(latestStep?.altitudeMeters ?? 7.5).toStringAsFixed(1)}m)',
              style: const TextStyle(color: Color(0xFF81C784), fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
