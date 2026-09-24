import '../models/room_node.dart';
import '../models/corridor_edge.dart';

enum VerticalPreference {
  fastest,
  preferStairs,
  preferElevator,
}

class RouteSegment {
  final RoomNode fromNode;
  final RoomNode toNode;
  final double distanceMeters;
  final String instruction;

  RouteSegment({
    required this.fromNode,
    required this.toNode,
    required this.distanceMeters,
    required this.instruction,
  });
}

class RoutingResult {
  final List<RoomNode> pathNodes;
  final List<RouteSegment> segments;
  final double totalDistanceMeters;
  final int estimatedSteps;

  RoutingResult({
    required this.pathNodes,
    required this.segments,
    required this.totalDistanceMeters,
    required this.estimatedSteps,
  });
}

class RoutingEngine {
  final List<RoomNode> nodes;
  final List<CorridorEdge> edges;

  RoutingEngine({required this.nodes, required this.edges});

  RoutingResult? calculateRoute({
    required String startNodeId,
    required String endNodeId,
    VerticalPreference preference = VerticalPreference.fastest,
  }) {
    final Map<String, double> distances = {};
    final Map<String, String> previous = {};
    final Set<String> unvisited = {};

    for (var n in nodes) {
      distances[n.id] = double.infinity;
      unvisited.add(n.id);
    }
    distances[startNodeId] = 0.0;

    // Adjacency list
    final Map<String, List<CorridorEdge>> adj = {};
    for (var e in edges) {
      adj.putIfAbsent(e.fromId, () => []).add(e);
      adj.putIfAbsent(e.toId, () => []).add(CorridorEdge(
        fromId: e.toId,
        toId: e.fromId,
        distanceMeters: e.distanceMeters,
        type: e.type,
        isAccessible: e.isAccessible,
      ));
    }

    while (unvisited.isNotEmpty) {
      String? current;
      double minD = double.infinity;

      for (var id in unvisited) {
        if (distances[id]! < minD) {
          minD = distances[id]!;
          current = id;
        }
      }

      if (current == null || current == endNodeId || minD == double.infinity) {
        break;
      }

      unvisited.remove(current);

      final neighbors = adj[current] ?? [];
      for (var edge in neighbors) {
        if (!unvisited.contains(edge.toId)) continue;

        double edgeWeight = edge.distanceMeters;

        // Apply accessibility and vertical preference weights
        if (preference == VerticalPreference.preferElevator && edge.type == 'stair_vertical') {
          edgeWeight += 50.0; // penalize stairs
        } else if (preference == VerticalPreference.preferStairs && edge.type == 'lift_vertical') {
          edgeWeight += 25.0; // penalize elevator wait
        }

        final double alt = distances[current]! + edgeWeight;
        if (alt < distances[edge.toId]!) {
          distances[edge.toId] = alt;
          previous[edge.toId] = current;
        }
      }
    }

    // Reconstruct path
    final List<String> pathIds = [];
    String? curr = endNodeId;
    while (curr != null && previous.containsKey(curr)) {
      pathIds.insert(0, curr);
      curr = previous[curr];
    }
    if (curr == startNodeId) {
      pathIds.insert(0, startNodeId);
    } else if (startNodeId != endNodeId) {
      return null; // No path found
    }

    final nodeMap = {for (var n in nodes) n.id: n};
    final List<RoomNode> pathNodes = pathIds.map((id) => nodeMap[id]!).toList();

    // Synthesize turn-by-turn guidance segments
    final List<RouteSegment> segments = [];
    double totalDist = 0.0;

    for (int i = 0; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];
      final dist = (from.floor != to.floor) ? 4.2 : 5.0; // estimate if edge metric
      totalDist += dist;

      String instruction = 'Walk straight toward ${to.name}';
      if (from.floor != to.floor) {
        instruction = 'Take ${to.category == RoomCategory.elevator ? "Elevator" : "Stairs"} to ${to.floor}';
      }

      segments.add(RouteSegment(
        fromNode: from,
        toNode: to,
        distanceMeters: dist,
        instruction: instruction,
      ));
    }

    return RoutingResult(
      pathNodes: pathNodes,
      segments: segments,
      totalDistanceMeters: totalDist,
      estimatedSteps: (totalDist / 0.75).round(),
    );
  }
}
