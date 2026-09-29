import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/room_node.dart';
import 'package:ewunavsurvey/models/corridor_edge.dart';
import 'package:ewunavsurvey/services/routing_engine.dart';

void main() {
  test('Multi-floor routing engine calculates correct shortest path across floors', () {
    final nodes = [
      RoomNode(
        id: 'gf_gate',
        name: 'Main Gate',
        floor: 'Ground Floor',
        category: RoomCategory.entrance,
        x: 100, y: 100,
      ),
      RoomNode(
        id: 'gf_lift',
        name: 'Ground Lift',
        floor: 'Ground Floor',
        category: RoomCategory.elevator,
        x: 150, y: 100,
      ),
      RoomNode(
        id: 'f2_lift',
        name: '2nd Floor Lift',
        floor: '2nd Floor',
        category: RoomCategory.elevator,
        x: 150, y: 100,
      ),
      RoomNode(
        id: 'f2_room_240',
        name: 'Room 240',
        floor: '2nd Floor',
        category: RoomCategory.classroom,
        x: 220, y: 100,
      ),
    ];

    final edges = [
      CorridorEdge(fromId: 'gf_gate', toId: 'gf_lift', distanceMeters: 20.0),
      CorridorEdge(fromId: 'gf_lift', toId: 'f2_lift', distanceMeters: 8.4, type: 'lift_vertical'),
      CorridorEdge(fromId: 'f2_lift', toId: 'f2_room_240', distanceMeters: 15.0),
    ];

    final router = RoutingEngine(nodes: nodes, edges: edges);
    final result = router.calculateRoute(
      startNodeId: 'gf_gate',
      endNodeId: 'f2_room_240',
      preference: VerticalPreference.preferElevator,
    );

    expect(result, isNotNull);
    expect(result!.pathNodes.length, 4);
    expect(result.pathNodes.first.id, 'gf_gate');
    expect(result.totalDistanceMeters, closeTo(43.4, 0.01));
    expect(result.segments.length, 3);
    expect(result.segments[0].distanceMeters, 20.0);
    expect(result.segments[1].distanceMeters, 8.4);
    expect(result.segments[2].distanceMeters, 15.0);
  });

  test('Wheelchair accessible routing strictly avoids stairs and slopes > 8.33%', () {
    final nodes = [
      RoomNode(id: 'start', name: 'Start', floor: 'Floor 1', category: RoomCategory.entrance, x: 0, y: 0),
      RoomNode(id: 'stair_node', name: 'Stairs', floor: 'Floor 1', category: RoomCategory.stairs, x: 10, y: 0),
      RoomNode(id: 'ramp_steep', name: 'Steep Ramp', floor: 'Floor 1', category: RoomCategory.corridor, x: 20, y: 10),
      RoomNode(id: 'ramp_ada', name: 'ADA Ramp', floor: 'Floor 1', category: RoomCategory.corridor, x: 20, y: -10),
      RoomNode(id: 'destination', name: 'Destination', floor: 'Floor 1', category: RoomCategory.classroom, x: 30, y: 0),
    ];

    final edges = [
      // Route 1 via stairs: total distance 10 + 10 = 20m (fastest, but stairs)
      CorridorEdge(fromId: 'start', toId: 'stair_node', distanceMeters: 10.0, type: 'stair_vertical'),
      CorridorEdge(fromId: 'stair_node', toId: 'destination', distanceMeters: 10.0, type: 'corridor'),

      // Route 2 via steep ramp: total distance 12 + 12 = 24m (running slope 10% > 8.33% ADA max)
      CorridorEdge(fromId: 'start', toId: 'ramp_steep', distanceMeters: 12.0, type: 'corridor', runningSlopePercent: 10.0),
      CorridorEdge(fromId: 'ramp_steep', toId: 'destination', distanceMeters: 12.0, type: 'corridor'),

      // Route 3 via compliant ADA ramp: total distance 15 + 15 = 30m (running slope 5% <= 8.33% ADA compliant)
      CorridorEdge(fromId: 'start', toId: 'ramp_ada', distanceMeters: 15.0, type: 'corridor', runningSlopePercent: 5.0, isAccessible: true),
      CorridorEdge(fromId: 'ramp_ada', toId: 'destination', distanceMeters: 15.0, type: 'corridor', isAccessible: true),
    ];

    final router = RoutingEngine(nodes: nodes, edges: edges);

    // Standard routing takes stairs (shortest 20m)
    final normalRoute = router.calculateRoute(
      startNodeId: 'start',
      endNodeId: 'destination',
      preference: VerticalPreference.preferStairs,
    );
    expect(normalRoute, isNotNull);
    expect(normalRoute!.pathNodes.map((n) => n.id).toList(), ['start', 'stair_node', 'destination']);

    // Wheelchair routing bypasses stairs AND steep ramp, choosing ADA ramp (30m)
    final wheelchairRoute = router.calculateRoute(
      startNodeId: 'start',
      endNodeId: 'destination',
      preference: VerticalPreference.wheelchairAccessible,
    );
    expect(wheelchairRoute, isNotNull);
    expect(wheelchairRoute!.pathNodes.map((n) => n.id).toList(), ['start', 'ramp_ada', 'destination']);
    expect(wheelchairRoute.totalDistanceMeters, closeTo(30.0, 0.01));
  });
}
