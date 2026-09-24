import 'package:flutter/material.dart';
import '../../models/room_node.dart';
import '../../services/slam_surveyor_engine.dart';
import '../../services/routing_engine.dart';

class NavigationScreen extends StatefulWidget {
  final SlamSurveyorEngine engine;

  const NavigationScreen({super.key, required this.engine});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  RoomNode? _selectedDestination;
  RoomNode? _selectedStart;
  RoutingResult? _currentRoute;
  VerticalPreference _verticalPreference = VerticalPreference.fastest;

  void _calculatePath() {
    if (_selectedStart == null || _selectedDestination == null) return;

    final router = RoutingEngine(
      nodes: widget.engine.rooms,
      edges: widget.engine.edges,
    );

    final res = router.calculateRoute(
      startNodeId: _selectedStart!.id,
      endNodeId: _selectedDestination!.id,
      preference: _verticalPreference,
    );

    setState(() {
      _currentRoute = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allRooms = widget.engine.rooms;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141624),
        title: const Text('🧭 EWUNav - Campus Navigator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Search & Route Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E2235),
            child: Column(
              children: [
                // Start Location Picker
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFF81C784), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RoomNode>(
                          value: _selectedStart,
                          hint: const Text('From: Where are you?', style: TextStyle(color: Colors.white70)),
                          dropdownColor: const Color(0xFF1E2235),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: allRooms.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('${r.name} (${r.floor})'),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStart = val;
                              _calculatePath();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),

                // Destination Location Picker
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFE57373), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RoomNode>(
                          value: _selectedDestination,
                          hint: const Text('To: Where do you want to go?', style: TextStyle(color: Colors.white70)),
                          dropdownColor: const Color(0xFF1E2235),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: allRooms.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('${r.name} (${r.floor})'),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDestination = val;
                              _calculatePath();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Accessibility & Vertical Preference Segmented Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Preference:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SegmentedButton<VerticalPreference>(
                      segments: const [
                        ButtonSegment(value: VerticalPreference.fastest, label: Text('⚡ Fastest')),
                        ButtonSegment(value: VerticalPreference.preferStairs, label: Text('🪜 Stairs')),
                        ButtonSegment(value: VerticalPreference.preferElevator, label: Text('🛗 Lift')),
                      ],
                      selected: {_verticalPreference},
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      onSelectionChanged: (val) {
                        setState(() {
                          _verticalPreference = val.first;
                          _calculatePath();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Route Directions / Faculty Inspector
          Expanded(
            child: _currentRoute != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C442E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📍 Total: ${_currentRoute!.totalDistanceMeters.toStringAsFixed(1)} meters',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '👣 ~${_currentRoute!.estimatedSteps} steps',
                              style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Faculty Card (if destination has teachers)
                      if (_selectedDestination != null && _selectedDestination!.facultyMembers.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C324A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('👨‍🏫 Faculty Occupants in this Room:', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              ..._selectedDestination!.facultyMembers.map((f) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• ${f.name} — ${f.designation} (${f.department})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Turn-by-Turn Steps
                      const Text('Turn-by-Turn Directions:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._currentRoute!.segments.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final seg = entry.value;
                        return Card(
                          color: const Color(0xFF1A1C2B),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF64B5F6),
                              radius: 14,
                              child: Text('${idx + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            title: Text(seg.instruction, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text('${seg.distanceMeters.toStringAsFixed(1)}m', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ),
                        );
                      }),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore_outlined, color: Colors.white24, size: 54),
                        const SizedBox(height: 12),
                        Text(
                          allRooms.isEmpty
                              ? 'No rooms mapped yet!\nSwitch to "Surveyor Mode" to walk and map the building.'
                              : 'Select your Start and Destination to see route directions.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
