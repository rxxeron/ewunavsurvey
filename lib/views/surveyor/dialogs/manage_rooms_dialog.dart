import 'package:flutter/material.dart';
import '../../../models/room_node.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class ManageRoomsDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final VoidCallback onRoomModified;

  const ManageRoomsDialog({
    super.key,
    required this.engine,
    required this.dbService,
    required this.onRoomModified,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    required VoidCallback onRoomModified,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ManageRoomsDialog(
        engine: engine,
        dbService: dbService,
        onRoomModified: onRoomModified,
      ),
    );
  }

  @override
  State<ManageRoomsDialog> createState() => _ManageRoomsDialogState();
}

class _ManageRoomsDialogState extends State<ManageRoomsDialog> {
  String _filter = '';
  bool _currentFloorOnly = true;

  IconData _iconForCategory(RoomCategory cat) {
    switch (cat) {
      case RoomCategory.classroom:
        return Icons.class_;
      case RoomCategory.lab:
      case RoomCategory.laboratory:
        return Icons.science;
      case RoomCategory.facultyOffice:
      case RoomCategory.office:
        return Icons.person_pin;
      case RoomCategory.adminOffice:
        return Icons.business;
      case RoomCategory.staircase:
      case RoomCategory.stairs:
        return Icons.stairs;
      case RoomCategory.elevator:
        return Icons.elevator;
      case RoomCategory.restroom:
      case RoomCategory.restroomMale:
      case RoomCategory.restroomFemale:
        return Icons.wc;
      case RoomCategory.deadEnd:
        return Icons.block;
      case RoomCategory.amenity:
      case RoomCategory.cafeteria:
      case RoomCategory.library:
        return Icons.local_cafe;
      default:
        return Icons.meeting_room;
    }
  }

  Color _colorForCategory(RoomCategory cat) {
    switch (cat) {
      case RoomCategory.classroom:
        return const Color(0xFF81C784);
      case RoomCategory.lab:
      case RoomCategory.laboratory:
        return const Color(0xFF4FC3F7);
      case RoomCategory.facultyOffice:
        return const Color(0xFFFFD54F);
      case RoomCategory.adminOffice:
        return const Color(0xFF64B5F6);
      case RoomCategory.staircase:
        return const Color(0xFFFF8A65);
      case RoomCategory.elevator:
        return const Color(0xFFBA68C8);
      case RoomCategory.restroom:
      case RoomCategory.restroomMale:
      case RoomCategory.restroomFemale:
        return const Color(0xFFE57373);
      case RoomCategory.deadEnd:
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFFB74D);
    }
  }

  void _confirmDeleteSingleRoom(RoomNode room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            const Text('Delete Room?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${room.name}" (${room.floor})?\nIts door pin and graph connection will be removed.',
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
              widget.engine.deleteRoom(room.id);
              widget.dbService.deleteRoom(room.id);
              Navigator.pop(ctx);
              setState(() {});
              widget.onRoomModified();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF8B0000),
                  content: Text('Deleted "${room.name}".'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRooms = widget.engine.rooms;
    final currentFloor = widget.engine.currentFloor;
    final filtered = allRooms.where((r) {
      if (_currentFloorOnly && r.floor != currentFloor) return false;
      if (_filter.isNotEmpty) {
        final query = _filter.toLowerCase();
        final matchesName = r.name.toLowerCase().contains(query);
        final matchesNum = (r.roomNumber ?? '').toLowerCase().contains(query);
        final matchesCat = r.category.name.toLowerCase().contains(query);
        return matchesName || matchesNum || matchesCat;
      }
      return true;
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF191B2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: Color(0xFF64B5F6), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '📋 Manage Rooms & Landmarks (${filtered.length})',
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar & Floor Scope Toggle
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search room number, name, or type...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                      filled: true,
                      fillColor: Color(0xFF141624),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                    onChanged: (val) => setState(() => _filter = val.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_currentFloorOnly ? '$currentFloor only' : 'All Floors', style: const TextStyle(fontSize: 11)),
                  selected: _currentFloorOnly,
                  selectedColor: const Color(0xFF1E3A5F),
                  checkmarkColor: const Color(0xFF64B5F6),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: _currentFloorOnly ? const Color(0xFF64B5F6) : Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) => setState(() => _currentFloorOnly = val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rooms List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            _filter.isNotEmpty
                                ? 'No matching rooms found.'
                                : 'No rooms tagged on $currentFloor.\nUse "Door LEFT/RIGHT" or "Restroom" to add one.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final room = filtered[index];
                        final catColor = _colorForCategory(room.category);
                        final catIcon = _iconForCategory(room.category);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2235),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: catColor.withValues(alpha: 0.2),
                                radius: 18,
                                child: Icon(catIcon, color: catColor, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          room.name,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (room.roomNumber != null && room.roomNumber != room.name) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2C324A),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '#${room.roomNumber}',
                                              style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '${room.floor} • ${room.doorSide.toUpperCase()}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        if (room.liftCount > 1) ...[
                                          const SizedBox(width: 6),
                                          Text('• ${room.liftCount} Lifts', style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                        if (room.facultyCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Text('• ${room.facultyCount} Teachers', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Delete Single Room Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                tooltip: 'Delete this room entry',
                                onPressed: () => _confirmDeleteSingleRoom(room),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tip: Tap the 🗑️ icon next to any room to delete it.',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF64B5F6))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
