import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../constants/ada_constants.dart';
import '../models/opening.dart';

enum VerticalPreference {
  fastest,
  preferStairs,
  preferElevator,
  wheelchairAccessible,
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
  final List<Opening> openings;

  RoutingEngine({required this.nodes, required this.edges, this.openings = const []});

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

    // Also register corridor step nodes from edges
    for (var e in edges) {
      if (!distances.containsKey(e.fromId)) {
        distances[e.fromId] = double.infinity;
        unvisited.add(e.fromId);
      }
      if (!distances.containsKey(e.toId)) {
        distances[e.toId] = double.infinity;
        unvisited.add(e.toId);
      }
    }
    
    // Register nodes from openings
    for (var o in openings) {
      if (!distances.containsKey(o.unitIdA)) {
        distances[o.unitIdA] = double.infinity;
        unvisited.add(o.unitIdA);
      }
      if (!distances.containsKey(o.unitIdB)) {
        distances[o.unitIdB] = double.infinity;
        unvisited.add(o.unitIdB);
      }
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
        runningSlopePercent: e.runningSlopePercent,
        crossSlopePercent: e.crossSlopePercent,
        widthMeters: e.widthMeters,
        hasTactilePaving: e.hasTactilePaving,
      ));
    }
    
    for (var o in openings) {
      // Synthesize an edge for the opening
      final isDoorAccessible = o.isAccessible && 
          !AdaConstants.isDoorWidthViolation(o.clearWidthMeters) && 
          !AdaConstants.isThresholdViolation(o.thresholdHeightMm);
          
      final openingEdge = CorridorEdge(
        fromId: o.unitIdA,
        toId: o.unitIdB,
        distanceMeters: 1.0,
        type: 'door',
        isAccessible: isDoorAccessible,
      );
      adj.putIfAbsent(o.unitIdA, () => []).add(openingEdge);
      adj.putIfAbsent(o.unitIdB, () => []).add(CorridorEdge(
        fromId: o.unitIdB,
        toId: o.unitIdA,
        distanceMeters: 1.0,
        type: 'door',
        isAccessible: isDoorAccessible,
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

        // Strict ADA filter for wheelchair accessible routes
        if (preference == VerticalPreference.wheelchairAccessible) {
          if (!edge.isAccessible || edge.type == 'stair_vertical') continue;
          if (edge.type != 'door') {
            if (AdaConstants.isSlopeViolation(edge.runningSlopePercent)) continue;
            if (AdaConstants.isCrossSlopeViolation(edge.crossSlopePercent)) continue;
            if (AdaConstants.isWidthViolation(edge.widthMeters)) continue;
          }
        }

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
    final List<RoomNode> pathNodes = pathIds.map((id) {
      if (nodeMap.containsKey(id)) return nodeMap[id]!;
      // Synthesize a waypoint stub for corridor step nodes
      final parts = id.split('_');
      final double x = parts.length >= 3 ? (double.tryParse(parts[parts.length - 2]) ?? 0) : 0;
      final double y = parts.length >= 4 ? (double.tryParse(parts[parts.length - 1]) ?? 0) : 0;
      final String floor = parts.length >= 2 ? parts[1] : '';
      return RoomNode(
        id: id,
        name: 'Waypoint',
        floor: floor,
        category: RoomCategory.corridor,
        x: x,
        y: y,
      );
    }).toList();

    // Synthesize turn-by-turn guidance segments
    final List<RouteSegment> segments = [];
    double totalDist = 0.0;

    for (int i = 0; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];
      
      double dist = (from.floor != to.floor) ? 4.2 : 5.0;
      final matching = edges.where((e) =>
          (e.fromId == from.id && e.toId == to.id) ||
          (e.fromId == to.id && e.toId == from.id));
      if (matching.isNotEmpty) {
        dist = matching.first.distanceMeters;
      }
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
