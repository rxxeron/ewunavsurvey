import 'package:flutter/material.dart';
import '../../../models/opening.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';
import 'photo_attachment_widget.dart';

class DoorPropertiesDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final String? openingId;
  final String? unitId;
  final void Function(Opening opening)? onSaved;

  const DoorPropertiesDialog({
    super.key,
    required this.engine,
    required this.dbService,
    this.openingId,
    this.unitId,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    String? openingId,
    String? unitId,
    void Function(Opening opening)? onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DoorPropertiesDialog(
        engine: engine,
        dbService: dbService,
        openingId: openingId,
        unitId: unitId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<DoorPropertiesDialog> createState() => _DoorPropertiesDialogState();
}

class _DoorPropertiesDialogState extends State<DoorPropertiesDialog> {
  DoorType _doorType = DoorType.hinged;
  AccessControl _accessControl = AccessControl.open;
  final _widthCtrl = TextEditingController(text: '0.90'); // 90cm default (ADA min 0.815m)
  final _thresholdCtrl = TextEditingController(text: '6.0'); // 6mm default (ADA max 13mm)
  bool _isEmergencyExit = false;
  bool _isAccessible = true;
  String? _photoPath;

  @override
  void dispose() {
    _widthCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = double.tryParse(_widthCtrl.text) ?? 0.90;
    final threshold = double.tryParse(_thresholdCtrl.text) ?? 6.0;

    final hasWidthViolation = width < 0.815; // ADA min 0.815m (32 inches)
    final hasThresholdViolation = threshold > 13.0; // ADA max 13mm
    final hasAdaViolations = hasWidthViolation || hasThresholdViolation;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.sensor_door, color: Color(0xFF81C784), size: 22),
          SizedBox(width: 8),
          Text('Door & Opening ADA Audit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ADA Compliance Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasAdaViolations ? const Color(0xFF3B1515) : const Color(0xFF142B1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasAdaViolations ? Colors.redAccent : const Color(0xFF81C784)),
              ),
              child: Row(
                children: [
                  Icon(
                    hasAdaViolations ? Icons.warning_amber : Icons.check_circle,
                    color: hasAdaViolations ? Colors.redAccent : const Color(0xFF81C784),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasAdaViolations ? 'ADA Inaccessible Opening' : 'ADA Compliant Opening',
                      style: TextStyle(
                        color: hasAdaViolations ? Colors.redAccent : const Color(0xFF81C784),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Door Operation Type
            const Text('Door Operation Mechanism:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: DoorType.values.map((t) {
                final isSel = t == _doorType;
                return ChoiceChip(
                  label: Text(t.name.toUpperCase(), style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: const Color(0xFF81C784),
                  backgroundColor: const Color(0xFF141624),
                  onSelected: (val) {
                    if (val) setState(() => _doorType = t);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Access Control
            const Text('Access Control:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: AccessControl.values.map((a) {
                final isSel = a == _accessControl;
                return ChoiceChip(
                  label: Text(a.name.toUpperCase(), style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: const Color(0xFF64B5F6),
                  backgroundColor: const Color(0xFF141624),
                  onSelected: (val) {
                    if (val) setState(() => _accessControl = a);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Clear Width
            TextField(
              controller: _widthCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Clear Opening Width (meters)',
                labelStyle: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12),
                hintText: 'e.g. 0.90',
                helperText: hasWidthViolation ? '🚨 Under ADA minimum (0.815m / 32 in)' : 'ADA Minimum: 0.815m',
                helperStyle: TextStyle(color: hasWidthViolation ? Colors.redAccent : Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF141624),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Threshold Height
            TextField(
              controller: _thresholdCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Door Threshold Raised Height (mm)',
                labelStyle: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                hintText: 'e.g. 6.0',
                helperText: hasThresholdViolation ? '🚨 Exceeds ADA maximum 13mm (0.5 in)' : 'ADA Maximum: 13.0 mm beveled',
                helperStyle: TextStyle(color: hasThresholdViolation ? Colors.redAccent : Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF141624),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            PhotoAttachmentWidget(
              photoPath: _photoPath,
              onPhotoChanged: (path) => setState(() => _photoPath = path),
              label: '📸 Doorway / Signage Photo Audit',
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Designated Emergency Fire Exit', style: TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: const Text('Outward swinging emergency egress portal', style: TextStyle(color: Colors.white38, fontSize: 10)),
              value: _isEmergencyExit,
              activeThumbColor: Colors.redAccent,
              onChanged: (val) => setState(() => _isEmergencyExit = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ADA Wheelchair Accessible', style: TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: const Text('Passable without steps or tight obstacles', style: TextStyle(color: Colors.white38, fontSize: 10)),
              value: _isAccessible && !hasAdaViolations,
              activeThumbColor: const Color(0xFF81C784),
              onChanged: hasAdaViolations ? null : (val) => setState(() => _isAccessible = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
          onPressed: () {
            final w = double.tryParse(_widthCtrl.text) ?? 0.90;
            final th = double.tryParse(_thresholdCtrl.text) ?? 6.0;
            final autoAccessible = !hasAdaViolations && _isAccessible;

            final opening = Opening(
              id: widget.openingId ?? 'op_${DateTime.now().millisecondsSinceEpoch}',
              levelId: widget.engine.currentFloor,
              unitIdA: widget.unitId ?? 'corridor_active',
              unitIdB: widget.unitId ?? 'room_active',
              doorType: _doorType,
              accessControl: _accessControl,
              clearWidthMeters: w,
              thresholdHeightMm: th,
              isAccessible: autoAccessible,
              isEmergencyExit: _isEmergencyExit,
              photoPath: _photoPath,
            );

            widget.dbService.saveOpening(opening);
            widget.onSaved?.call(opening);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF1C442E),
                content: Text('Door opening audit saved to database!'),
              ),
            );
          },
          child: const Text('Save Door Audit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
