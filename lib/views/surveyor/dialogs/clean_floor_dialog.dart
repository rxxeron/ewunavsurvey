import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class CleanFloorDialog extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final VoidCallback onCleared;

  const CleanFloorDialog({
    super.key,
    required this.engine,
    required this.dbService,
    required this.onCleared,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    required VoidCallback onCleared,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CleanFloorDialog(
        engine: engine,
        dbService: dbService,
        onCleared: onCleared,
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFloor = engine.currentFloor;
    final floorRooms = engine.rooms.where((r) => r.floor == currentFloor).toList();
    final floorSteps = engine.stepLogs.where((s) => s.floor == currentFloor).length;

    return Dialog(
      backgroundColor: const Color(0xFF191B2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cleaning_services, color: Color(0xFFFFD54F), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '🧹 Clean $currentFloor',
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF141624),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('$floorSteps', style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Steps Recorded', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${floorRooms.length}', style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Tagged Rooms', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Cleaning Scope (Active Floor Only):',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Option 1: Clear Walked Paths only
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white12),
              ),
              tileColor: const Color(0xFF1E2235),
              leading: const Icon(Icons.timeline, color: Color(0xFF64B5F6)),
              title: const Text('Clear Walked Paths & Steps Only', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Wipes footsteps and hallway lines for this floor. Keeps tagged room doors intact.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                _confirmAction(
                  context,
                  title: 'Clear Paths on $currentFloor?',
                  description: 'This will erase walked lines and step logs for "$currentFloor". Room doors will remain.',
                  onConfirm: () {
                    engine.clearFloorPaths(currentFloor);
                    Navigator.pop(context);
                    onCleared();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cleared walked paths on $currentFloor.')),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),

            // Option 2: Delete Rooms only
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white12),
              ),
              tileColor: const Color(0xFF1E2235),
              leading: const Icon(Icons.meeting_room, color: Color(0xFFFF8A65)),
              title: const Text('Delete All Rooms on this Floor Only', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Removes all room pins and landmarks on this floor. Keeps walked corridor paths.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                _confirmAction(
                  context,
                  title: 'Delete Rooms on $currentFloor?',
                  description: 'This will delete all ${floorRooms.length} room/portal entries on "$currentFloor". Corridors will remain.',
                  onConfirm: () {
                    for (final r in floorRooms) {
                      dbService.deleteRoom(r.id);
                    }
                    engine.clearFloorRooms(currentFloor);
                    Navigator.pop(context);
                    onCleared();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted all rooms on $currentFloor.')),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),

            // Option 3: Reset Entire Floor
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.redAccent, width: 0.8),
              ),
              tileColor: const Color(0xFF2C191E),
              leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
              title: Text('Reset $currentFloor Completely', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Clears both paths and rooms for this floor only. Other floors remain untouched.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                _confirmAction(
                  context,
                  title: 'Reset $currentFloor Completely?',
                  description: 'All paths, steps, and rooms on "$currentFloor" will be deleted. All other floors and buildings will be preserved.',
                  onConfirm: () {
                    for (final r in floorRooms) {
                      dbService.deleteRoom(r.id);
                    }
                    engine.resetFloor(currentFloor);
                    Navigator.pop(context);
                    onCleared();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF8B0000),
                        content: Text('Reset all data on $currentFloor.'),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white60)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
