import 'package:flutter/material.dart';
import '../../services/slam_surveyor_engine.dart';
import 'dialogs/add_floor_dialog.dart';

class FloorSelectorBar extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback onFloorChanged;

  const FloorSelectorBar({
    super.key,
    required this.engine,
    required this.onFloorChanged,
  });

  void _confirmDeleteFloor(BuildContext context, String floorName) {
    if (engine.availableFloors.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only floor in this building.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text('Delete $floorName?', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "$floorName" from ${engine.currentBuilding}? All rooms and steps on this floor will be deleted.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              engine.deleteFloor(floorName);
              Navigator.pop(ctx);
              onFloorChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$floorName".')),
              );
            },
            child: const Text('Delete Floor', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableFloors = engine.availableFloors;

    return Container(
      height: 44,
      color: const Color(0xFF141624),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: availableFloors.length + 1,
        itemBuilder: (context, index) {
          if (index == availableFloors.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: ActionChip(
                avatar: const Icon(Icons.add, size: 14, color: Color(0xFF81C784)),
                label: const Text('Add Floor', style: TextStyle(color: Color(0xFF81C784), fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1E2235),
                side: const BorderSide(color: Color(0xFF81C784), width: 0.8),
                onPressed: () => AddFloorDialog.show(context, engine: engine, onFloorAdded: onFloorChanged),
              ),
            );
          }
          final f = availableFloors[index];
          final isSelected = (f == engine.currentFloor);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: InkWell(
              onLongPress: availableFloors.length > 1 ? () => _confirmDeleteFloor(context, f) : null,
              borderRadius: BorderRadius.circular(8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
                    if (availableFloors.length > 1 && isSelected) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _confirmDeleteFloor(context, f),
                        child: const Icon(Icons.close, size: 13, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF64B5F6),
                backgroundColor: const Color(0xFF1E2235),
                onSelected: (selected) {
                  if (selected) {
                    engine.setFloor(f);
                    onFloorChanged();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
