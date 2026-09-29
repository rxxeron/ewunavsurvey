import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class DeadEndDialog extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;

  const DeadEndDialog({
    super.key,
    required this.engine,
    required this.dbService,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
  }) {
    if (!engine.hasActiveBuilding) return Future.value();
    return showDialog(
      context: context,
      builder: (ctx) => DeadEndDialog(engine: engine, dbService: dbService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteCtrl = TextEditingController();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.block, color: Color(0xFFEF5350), size: 22),
          SizedBox(width: 8),
          Text(
            'Tag Corridor Dead End',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marks this position as a physical corridor termination / wall boundary. This prevents pathfinding routes from trying to pass through this wall and draws an architectural end cap.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. South Wall, Locked Fire Exit, End of Hallway A',
              hintStyle: TextStyle(color: Colors.white38),
              labelText: 'Optional Barrier Description',
              labelStyle: TextStyle(color: Color(0xFF64B5F6)),
              filled: true,
              fillColor: Color(0xFF141624),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
          onPressed: () {
            final deadEndNode = engine.tagDeadEnd(note: noteCtrl.text.trim());
            dbService.saveRoom(deadEndNode);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF491212),
                content: Text('Dead-end wall boundary placed! Use 🔄 U-Turn to walk back.'),
              ),
            );
          },
          child: const Text('Place Wall Cap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
