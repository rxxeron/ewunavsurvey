import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/compass_fusion_service.dart';

class AzimuthAlignmentDialog extends StatefulWidget {
  const AzimuthAlignmentDialog({super.key});

  @override
  State<AzimuthAlignmentDialog> createState() => _AzimuthAlignmentDialogState();
}

class _AzimuthAlignmentDialogState extends State<AzimuthAlignmentDialog> {
  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<SlamSurveyorEngine>(context);
    final compass = engine.compassFusion;
    final double currentHeading = engine.currentHeadingDeg;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.explore, color: Color(0xFF4FC3F7), size: 22),
          SizedBox(width: 8),
          Text(
            'Building Azimuth & Alignment',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Align your phone parallel to the longest main corridor or outer wall of this building. Then tap Set Baseline.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141624),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT HEADING', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${currentHeading.toStringAsFixed(1)}°',
                        style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('SAVED BASELINE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${compass.buildingBaselineDeg.toStringAsFixed(1)}°',
                        style: const TextStyle(color: Color(0xFF81C784), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Set Baseline (Building Axis)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  engine.saveAzimuth(currentHeading);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1C442E),
                      content: Text('Building baseline set to ${currentHeading.toStringAsFixed(1)}°'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Hallway Turn Snapping Mode:',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select how physical walking angles snap to the digital blueprint.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Manhattan (90°)'),
                  selected: compass.snapMode == HeadingSnapMode.manhattan90,
                  selectedColor: const Color(0xFF81C784),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: compass.snapMode == HeadingSnapMode.manhattan90 ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => compass.snapMode = HeadingSnapMode.manhattan90);
                  },
                ),
                ChoiceChip(
                  label: const Text('Diagonal (45°)'),
                  selected: compass.snapMode == HeadingSnapMode.diagonal45,
                  selectedColor: const Color(0xFFFFD54F),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: compass.snapMode == HeadingSnapMode.diagonal45 ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => compass.snapMode = HeadingSnapMode.diagonal45);
                  },
                ),
                ChoiceChip(
                  label: const Text('Free Heading'),
                  selected: compass.snapMode == HeadingSnapMode.freeAngle,
                  selectedColor: const Color(0xFFBA68C8),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: compass.snapMode == HeadingSnapMode.freeAngle ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => compass.snapMode = HeadingSnapMode.freeAngle);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
