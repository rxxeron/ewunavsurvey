import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';

class AddBuildingDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback? onBuildingCreated;

  const AddBuildingDialog({
    super.key,
    required this.engine,
    this.onBuildingCreated,
  });

  static Future<void> show(BuildContext context, SlamSurveyorEngine engine, {VoidCallback? onBuildingCreated}) {
    return showDialog(
      context: context,
      builder: (ctx) => AddBuildingDialog(
        engine: engine,
        onBuildingCreated: onBuildingCreated,
      ),
    );
  }

  @override
  State<AddBuildingDialog> createState() => _AddBuildingDialogState();
}

class _AddBuildingDialogState extends State<AddBuildingDialog> {
  final _nameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController(text: 'Ground Floor');
  double _lat = 23.7684;
  double _lng = 90.4258;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.domain_add, color: Color(0xFF81C784)),
          SizedBox(width: 8),
          Text(
            'New Building Survey',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Presets (or enter custom name below):',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  backgroundColor: const Color(0xFF141624),
                  label: const Text('Main Building & Block-C', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nameCtrl.text = 'Main Building & Block-C';
                      _lat = 23.7684;
                      _lng = 90.4258;
                    });
                  },
                ),
                ActionChip(
                  backgroundColor: const Color(0xFF141624),
                  label: const Text('Academic Building 1 (AB1)', style: TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nameCtrl.text = 'Academic Building 1 (AB1)';
                      _lat = 23.76763;
                      _lng = 90.42504;
                    });
                  },
                ),
                ActionChip(
                  backgroundColor: const Color(0xFF141624),
                  label: const Text('Academic Building 2 (AB2)', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nameCtrl.text = 'Academic Building 2 (AB2)';
                      _lat = 23.76856;
                      _lng = 90.42631;
                    });
                  },
                ),
                ActionChip(
                  backgroundColor: const Color(0xFF141624),
                  label: const Text('Academic Building 3 (AB3)', style: TextStyle(color: Color(0xFFBA68C8), fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nameCtrl.text = 'Academic Building 3 (AB3)';
                      _lat = 23.76725;
                      _lng = 90.42732;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Building Name',
                labelStyle: TextStyle(color: Color(0xFF64B5F6)),
                hintText: 'e.g. Academic Building 1, Library Building',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF141624),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _floorCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Starting Floor',
                labelStyle: TextStyle(color: Color(0xFF81C784)),
                hintText: 'e.g. Ground Floor, Basement, 1st Floor',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF141624),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Floors are added one by one as you survey. You can add more floors at any time.',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
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
            final name = _nameCtrl.text.trim();
            final floor = _floorCtrl.text.trim();
            if (name.isNotEmpty) {
              widget.engine.createBuilding(
                name: name,
                lat: _lat,
                lng: _lng,
                initialFloor: floor.isNotEmpty ? floor : 'Ground Floor',
              );
              Navigator.pop(context);
              widget.onBuildingCreated?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1C442E),
                  content: Text('Building "$name" created. Survey active!'),
                ),
              );
            }
          },
          child: const Text('Begin Survey', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
