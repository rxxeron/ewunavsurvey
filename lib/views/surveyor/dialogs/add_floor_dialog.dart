import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';

class AddFloorDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback? onFloorAdded;

  const AddFloorDialog({
    super.key,
    required this.engine,
    this.onFloorAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    VoidCallback? onFloorAdded,
  }) {
    if (!engine.hasActiveBuilding) return Future.value();
    return showDialog(
      context: context,
      builder: (ctx) => AddFloorDialog(engine: engine, onFloorAdded: onFloorAdded),
    );
  }

  @override
  State<AddFloorDialog> createState() => _AddFloorDialogState();
}

class _AddFloorDialogState extends State<AddFloorDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Text('Add Custom Floor', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'e.g. 1st Floor, 2nd Floor, Mezzanine, Rooftop',
          hintStyle: TextStyle(color: Colors.white38),
          labelText: 'Floor Name',
          labelStyle: TextStyle(color: Color(0xFF64B5F6)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF64B5F6))),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6)),
          onPressed: () {
            final text = _ctrl.text.trim();
            if (text.isNotEmpty) {
              widget.engine.addCustomFloor(text);
              Navigator.pop(context);
              widget.onFloorAdded?.call();
            }
          },
          child: const Text('Add & Switch', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
