import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class SchemaViewerSheet extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final VoidCallback? onEntriesModified;

  const SchemaViewerSheet({
    super.key,
    required this.engine,
    required this.dbService,
    this.onEntriesModified,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    VoidCallback? onEntriesModified,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141624),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SchemaViewerSheet(
        engine: engine,
        dbService: dbService,
        onEntriesModified: onEntriesModified,
      ),
    );
  }

  @override
  State<SchemaViewerSheet> createState() => _SchemaViewerSheetState();
}

class _SchemaViewerSheetState extends State<SchemaViewerSheet> {
  int _activeTab = 0; // 0: Blueprint, 1: Raw Steps, 2: Delete Entries

  @override
  Widget build(BuildContext context) {
    final data = widget.engine.exportGraphJson();
    final rawStepsData = {
      'building': widget.engine.currentBuilding,
      'totalSteps': widget.engine.stepLogs.length,
      'steps': widget.engine.stepLogs.map((s) => s.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      _activeTab == 0 ? data : rawStepsData,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Blueprint Graph JSON'),
                      selected: _activeTab == 0,
                      selectedColor: const Color(0xFF64B5F6),
                      backgroundColor: const Color(0xFF1E2235),
                      labelStyle: TextStyle(
                        color: _activeTab == 0 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (val) => setState(() => _activeTab = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Raw Steps & Wi-Fi'),
                      selected: _activeTab == 1,
                      selectedColor: const Color(0xFF81C784),
                      backgroundColor: const Color(0xFF1E2235),
                      labelStyle: TextStyle(
                        color: _activeTab == 1 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (val) => setState(() => _activeTab = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🗑️ Delete Entries'),
                      selected: _activeTab == 2,
                      selectedColor: Colors.redAccent,
                      backgroundColor: const Color(0xFF1E2235),
                      labelStyle: TextStyle(
                        color: _activeTab == 2 ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (val) => setState(() => _activeTab = 2),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF64B5F6)),
                  tooltip: 'Copy JSON',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied JSON to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _activeTab == 2
                  ? ListView(
                      controller: scrollCtrl,
                      children: [
                        const Text(
                          'Manage & Delete Survey Entries',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the red trash icon to permanently remove any wrongly placed room or step entry.',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Area Zones & Courtyards (${widget.engine.zones.length})',
                          style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Divider(color: Colors.white12),
                        if (widget.engine.zones.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No area zones enclosed yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          )
                        else
                          ...widget.engine.zones.map((z) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(6)),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.crop_square, color: Color(0xFFFFD54F), size: 18),
                                  title: Text('${z.name} (${z.category.displayName})',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${z.floor} • Area: ${z.areaSqMeters.toStringAsFixed(1)} m² • ${z.points.length} vertices',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    tooltip: 'Delete this zone',
                                    onPressed: () {
                                      widget.engine.deleteZone(z.id);
                                      widget.dbService.deleteZone(z.id);
                                      setState(() {});
                                      widget.onEntriesModified?.call();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Deleted zone "${z.name}"')),
                                      );
                                    },
                                  ),
                                ),
                              )),
                        const SizedBox(height: 16),
                        Text(
                          'Tagged Rooms (${widget.engine.rooms.length})',
                          style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Divider(color: Colors.white12),
                        if (widget.engine.rooms.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No rooms tagged yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          )
                        else
                          ...widget.engine.rooms.map((r) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(6)),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.meeting_room, color: Color(0xFF81C784), size: 18),
                                  title: Text(
                                    '${r.name} (${(r.roomNumber != null && r.roomNumber!.isNotEmpty) ? r.roomNumber : "No #"})',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('${r.floor} • Side: ${r.doorSide} • (${r.x.round()}, ${r.y.round()})',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    tooltip: 'Delete this room entry',
                                    onPressed: () {
                                      widget.engine.deleteRoom(r.id);
                                      widget.dbService.deleteRoom(r.id);
                                      setState(() {});
                                      widget.onEntriesModified?.call();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Deleted room "${r.name}"')),
                                      );
                                    },
                                  ),
                                ),
                              )),
                        const SizedBox(height: 16),
                        Text(
                          'Step Logs (${widget.engine.stepLogs.length})',
                          style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Divider(color: Colors.white12),
                        if (widget.engine.stepLogs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No steps recorded yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          )
                        else
                          ...widget.engine.stepLogs.reversed.take(20).map((s) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(6)),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.directions_walk, color: Color(0xFF64B5F6), size: 16),
                                  title: Text(
                                    'Step #${s.stepIndex} • ${s.floor} • Heading: ${s.headingDeg.round()}°',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    '(${s.x.round()}, ${s.y.round()}) ${s.comment != null && s.comment!.isNotEmpty ? "• Note: ${s.comment}" : ""}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                    tooltip: 'Delete this step',
                                    onPressed: () {
                                      widget.engine.deleteStepLog(s.stepIndex);
                                      widget.dbService.deleteStepLog(s.stepIndex);
                                      setState(() {});
                                      widget.onEntriesModified?.call();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Deleted step #${s.stepIndex}')),
                                      );
                                    },
                                  ),
                                ),
                              )),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F111A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        child: SelectableText(
                          jsonStr,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFA6ADC8)),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
