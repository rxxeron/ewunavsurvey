import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';

class CompleteFloorDialog extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback onFinalizeExport;

  const CompleteFloorDialog({
    super.key,
    required this.engine,
    required this.onFinalizeExport,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required VoidCallback onFinalizeExport,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CompleteFloorDialog(
        engine: engine,
        onFinalizeExport: onFinalizeExport,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floor = engine.currentFloor;
    final floorRooms = engine.rooms.where((r) => r.floor == floor).length;
    final floorSteps = engine.stepLogs.where((s) => s.floor == floor).length;
    final floorMeters = floorSteps * engine.pdrEngine.strideLengthMeters;
    final floorFingerprints = engine.fingerprints.where((f) => f.floor == floor).length;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF81C784), size: 24),
          SizedBox(width: 8),
          Text(
            'Complete Floor Survey',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Floor: $floor (${engine.currentBuilding})',
            style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('👣 Total Steps', '$floorSteps steps'),
          _buildDetailRow('📏 Walked Distance', '${floorMeters.toStringAsFixed(1)} meters'),
          _buildDetailRow('🚪 Tagged Landmarks', '$floorRooms rooms/portals'),
          _buildDetailRow('📶 Wi-Fi Fingerprints', '$floorFingerprints scans'),
          const Divider(color: Colors.white24, height: 16),
          const Text(
            'Survey status will be paused and all graph edges verified for this floor.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Surveying', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
          icon: const Icon(Icons.lock, size: 16, color: Colors.black),
          label: const Text('Finalize & Export', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () {
            engine.pauseRecording();
            Navigator.pop(context);
            onFinalizeExport();
          },
        ),
      ],
    );
  }
}
