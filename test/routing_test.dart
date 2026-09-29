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
}
