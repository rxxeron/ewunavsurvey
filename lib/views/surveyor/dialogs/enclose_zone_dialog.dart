import 'package:flutter/material.dart';
import '../../../models/area_zone.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class EncloseZoneDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final VoidCallback? onZoneSaved;

  const EncloseZoneDialog({
    super.key,
    required this.engine,
    required this.dbService,
    this.onZoneSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    VoidCallback? onZoneSaved,
  }) {
    final candidate = engine.pendingLoopCandidate;
    final trackPoints = engine.floorTrackPoints[engine.currentFloor] ?? [];

    if ((candidate == null || candidate.points.length < 3) && trackPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 3 points/steps to enclose an area!')),
      );
      return Future.value();
    }

    return showDialog(
      context: context,
      builder: (ctx) => EncloseZoneDialog(
        engine: engine,
        dbService: dbService,
        onZoneSaved: onZoneSaved,
      ),
    );
  }

  @override
  State<EncloseZoneDialog> createState() => _EncloseZoneDialogState();
}

class _EncloseZoneDialogState extends State<EncloseZoneDialog> {
  late final List<ZonePoint> _zonePoints;
  late final double _area;
  ZoneCategory _selectedCategory = ZoneCategory.courtyard;
  late final TextEditingController _nameCtrl;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final candidate = widget.engine.pendingLoopCandidate;
    final trackPoints = widget.engine.floorTrackPoints[widget.engine.currentFloor] ?? [];

    if (candidate != null && candidate.points.length >= 3) {
      _zonePoints = candidate.points;
      _area = candidate.areaSqMeters;
    } else {
      _zonePoints = trackPoints.map((p) => ZonePoint(p.x, p.y)).toList();
      _area = AreaZone.calculateArea(_zonePoints, widget.engine.pixelsPerMeter);
    }

    _nameCtrl = TextEditingController(text: 'Central Courtyard');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.landscape, color: Color(0xFF81C784), size: 22),
          SizedBox(width: 8),
          Text('Enclose Space / Area', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF141624),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CALCULATED AREA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${_area.toStringAsFixed(1)} m²', style: const TextStyle(color: Color(0xFF81C784), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('PERIMETER POINTS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${_zonePoints.length} vertices', style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select Space / Zone Type:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ZoneCategory.values.map((cat) {
                final isSel = (cat == _selectedCategory);
                return ChoiceChip(
                  label: Text(cat.displayName, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11)),
                  selected: isSel,
                  selectedColor: const Color(0xFF81C784),
                  backgroundColor: const Color(0xFF141624),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat;
                        if (cat == ZoneCategory.courtyard) _nameCtrl.text = 'Central Courtyard';
                        if (cat == ZoneCategory.rooftop) _nameCtrl.text = 'Rooftop Terrace';
                        if (cat == ZoneCategory.hallway) _nameCtrl.text = 'Main Hallway';
                        if (cat == ZoneCategory.lobby) _nameCtrl.text = 'Reception Lobby';
                        if (cat == ZoneCategory.cafeteria) _nameCtrl.text = 'Campus Cafeteria';
                        if (cat == ZoneCategory.auditorium) _nameCtrl.text = 'Main Auditorium';
                        if (cat == ZoneCategory.openSpace) _nameCtrl.text = 'Open Plaza';
                        if (cat == ZoneCategory.voidAtrium) _nameCtrl.text = 'Central Atrium Void (No-Walk)';
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF81C784))),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Field Notes (optional)',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF81C784))),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.engine.dismissPendingLoop();
            Navigator.pop(context);
          },
          child: const Text('Dismiss', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
          icon: const Icon(Icons.check, size: 16, color: Colors.black),
          label: const Text('Save Zone', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () {
            final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : _selectedCategory.displayName;
            AreaZone zone;
            if (widget.engine.pendingLoopCandidate != null) {
              zone = widget.engine.enclosePendingLoop(
                name: name,
                category: _selectedCategory,
                notes: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
              );
            } else {
              zone = widget.engine.createManualZone(
                name: name,
                category: _selectedCategory,
                points: _zonePoints,
                notes: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
              );
            }
            widget.dbService.saveZone(zone);
            Navigator.pop(context);
            widget.onZoneSaved?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1B4D2E),
                content: Text('Saved "${zone.name}" (${zone.areaSqMeters.toStringAsFixed(1)} m²)'),
              ),
            );
          },
        ),
      ],
    );
  }
}
