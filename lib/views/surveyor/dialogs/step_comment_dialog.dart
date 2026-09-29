import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';

class StepCommentDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;

  const StepCommentDialog({
    super.key,
    required this.engine,
    required this.dbService,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
  }) {
    if (!engine.hasActiveBuilding) return Future.value();
    return showDialog(
      context: context,
      builder: (ctx) => StepCommentDialog(engine: engine, dbService: dbService),
    );
  }

  @override
  State<StepCommentDialog> createState() => _StepCommentDialogState();
}

class _StepCommentDialogState extends State<StepCommentDialog> {
  final _commentCtrl = TextEditingController();
  final _quickChips = const [
    '🚰 Water Cooler',
    '📋 Notice Board',
    '🚻 Restroom Entrance',
    '🚧 Construction Barrier',
    '🪟 Glass Partition',
    '🚨 Fire Extinguisher',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Text('💬 Add Step Comment / Field Note', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _commentCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Glass door to cafeteria, Water cooler on left',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF141624),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            const Text('Quick Field Tags:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickChips.map((tag) => ActionChip(
                backgroundColor: const Color(0xFF141624),
                side: const BorderSide(color: Colors.white24),
                label: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () {
                  setState(() {
                    if (_commentCtrl.text.isEmpty) {
                      _commentCtrl.text = tag;
                    } else {
                      _commentCtrl.text = '${_commentCtrl.text}, $tag';
                    }
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
          onPressed: () {
            final text = _commentCtrl.text.trim();
            if (text.isNotEmpty) {
              widget.engine.addCommentToCurrentStep(text);
              if (widget.engine.stepLogs.isNotEmpty) {
                final last = widget.engine.stepLogs.last;
                widget.dbService.updateStepComment(last.stepIndex, text);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: Color(0xFF1C442E), content: Text('Comment saved to step log!')),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save Note', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
