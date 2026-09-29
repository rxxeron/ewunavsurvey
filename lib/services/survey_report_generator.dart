import 'slam_surveyor_engine.dart';
import '../models/room_node.dart';

/// Comprehensive generator for Indoor Survey Executive & Technical Audit Reports.
class SurveyReportGenerator {
  final SlamSurveyorEngine engine;

  SurveyReportGenerator({required this.engine});

  /// Generates a structured Markdown report
  String generateMarkdownReport() {
    final building = engine.currentBuilding;
    final floors = engine.availableFloors;
    final rooms = engine.rooms;
    final edges = engine.edges;
    final zones = engine.zones;
    final fingerprints = engine.fingerprints;
    final steps = engine.stepLogs;
    final azimuth = engine.compassFusion.buildingBaselineDeg;

    // Corridor metrics
    double totalDistanceM = 0;
    int adaCompliantEdges = 0;
    int tactilePavingEdges = 0;
    int violationsCount = 0;

    for (var e in edges) {
      totalDistanceM += e.distanceMeters;
      final bool widthViolation = (e.widthMeters != null && e.widthMeters! < 0.915);
      final bool slopeViolation = (e.runningSlopePercent != null && e.runningSlopePercent! > 8.33);
      if (widthViolation || slopeViolation) {
        violationsCount++;
      } else {
        adaCompliantEdges++;
      }
      if (e.hasTactilePaving) tactilePavingEdges++;
    }

    final double adaRate = edges.isNotEmpty ? (adaCompliantEdges / edges.length) * 100 : 100.0;

    // Room categories
    final Map<RoomCategory, int> categoryCounts = {};
    for (var r in rooms) {
      categoryCounts[r.category] = (categoryCounts[r.category] ?? 0) + 1;
    }

    // Zone areas
    double totalEnclosedAreaSqM = 0;
    for (var z in zones) {
      totalEnclosedAreaSqM += z.areaSqMeters;
    }

    // Wi-Fi Access points
    final Set<String> uniqueBssids = {};
    for (var fp in fingerprints) {
      for (var ap in fp.accessPoints) {
        uniqueBssids.add(ap.bssid);
      }
    }

    final now = DateTime.now().toIso8601String().split('T').first;

    final buffer = StringBuffer();
    buffer.writeln('# 🏛️ EWUNav Indoor Survey Audit Report');
    buffer.writeln('**Building:** $building  ');
    buffer.writeln('**Audit Date:** $now  ');
    buffer.writeln('**Baseline Azimuth:** ${azimuth.toStringAsFixed(1)}° True North  ');
    buffer.writeln('**Surveyed Floors (${floors.length}):** ${floors.join(', ')}  ');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## 📊 Key Architectural Metrics');
    buffer.writeln('| Metric | Count / Measurement | Standard |');
    buffer.writeln('|---|---|---|');
    buffer.writeln('| **Total Walkway Distance** | ${totalDistanceM.toStringAsFixed(1)} meters | Centerline SLAM |');
    buffer.writeln('| **Enclosed Planar Area** | ${totalEnclosedAreaSqM.toStringAsFixed(1)} m² | Gauss Shoelace Formula |');
    buffer.writeln('| **Rooms & Units Surveyed** | ${rooms.length} | OGC IMDF v1.0.0 |');
    buffer.writeln('| **Corridor Path Segments** | ${edges.length} | Directed / Undirected |');
    buffer.writeln('| **PDR Footsteps Calibrated** | ${steps.length} | Dynamic Weinberg Model |');
    buffer.writeln('| **RF Fingerprint Nodes** | ${fingerprints.length} | Wi-Fi Signal Grid |');
    buffer.writeln('| **Unique Wi-Fi Radios (BSSID)** | ${uniqueBssids.length} | IEEE 802.11 b/g/n/ac/ax |');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## ♿ ADA Accessibility & Universal Design Audit');
    buffer.writeln('- **ADA Compliant Corridors:** $adaCompliantEdges / ${edges.length} (${adaRate.toStringAsFixed(1)}%)');
    buffer.writeln('- **Corridors with Tactile Ground Indicators (TGSI):** $tactilePavingEdges');
    buffer.writeln('- **ADA Non-Compliant Narrow/Steep Path Flags:** $violationsCount');
    buffer.writeln('- **Wheelchair Routing Status:** ${violationsCount == 0 ? '✅ 100% Fully Accessible' : '⚠️ Has Inaccessible Obstacles'}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## 🏢 Space Breakdown by Category');
    if (categoryCounts.isEmpty) {
      buffer.writeln('_No categorized rooms recorded yet._');
    } else {
      buffer.writeln('| Room / POI Category | Count |');
      buffer.writeln('|---|---|');
      categoryCounts.forEach((cat, count) {
        buffer.writeln('| ${cat.name} | $count |');
      });
    }
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Generated automatically by **EWUNav Autonomous Indoor Mapping Engine**');

    return buffer.toString();
  }
}
