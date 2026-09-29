import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';

class StrideCalibrationDialog extends StatefulWidget {
  const StrideCalibrationDialog({super.key});

  @override
  State<StrideCalibrationDialog> createState() => _StrideCalibrationDialogState();
}

class _StrideCalibrationDialogState extends State<StrideCalibrationDialog> {
  bool _isCalibrating = false;
  int _startSteps = 0;
  double _startDistance = 0.0;
  final double _knownDistanceM = 10.0; // 10 meters default

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<SlamSurveyorEngine>(context, listen: false);
    final pdr = engine.pdrEngine; // Assuming getter exists or accessible

    return AlertDialog(
      title: const Text('Stride Calibration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Walk a known straight distance (e.g., 10 meters) to calibrate your personal stride length model (Weinberg K-factor).',
          ),
          const SizedBox(height: 16),
          if (!_isCalibrating)
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start 10m Walk'),
              onPressed: () {
                setState(() {
                  _isCalibrating = true;
                  _startSteps = pdr.stepCount;
                  _startDistance = pdr.totalDistanceMeters;
                });
              },
            )
          else
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Walking... Tap when you reach 10 meters.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop & Calibrate'),
                  onPressed: () async {
                    final int stepsTaken = pdr.stepCount - _startSteps;
                    if (stepsTaken < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not enough steps to calibrate.')),
                      );
                      setState(() => _isCalibrating = false);
                      return;
                    }
                    
                    // Simple approximation: we adjust K based on actual vs estimated distance
                    final double distanceWalked = pdr.totalDistanceMeters - _startDistance;
                    final double ratio = _knownDistanceM / math.max(0.1, distanceWalked);
                    final double newK = pdr.weinbergK * ratio;
                    await engine.saveKFactor(newK);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calibrated! New K-Factor: ${newK.toStringAsFixed(3)}')),
                      );
                      setState(() => _isCalibrating = false);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
