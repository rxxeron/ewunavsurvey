import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';
import '../../../services/survey_report_generator.dart';

class ExportSummaryDialog extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;

  const ExportSummaryDialog({
    super.key,
    required this.engine,
    required this.dbService,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
  }) async {
    final processedGraph = engine.exportGraphJson();
    final processedJson = const JsonEncoder.withIndent('  ').convert(processedGraph);
    final rawJson = await dbService.exportRawDataJson();
    final dbPath = await dbService.getDatabaseFilePath();

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('💾 Survey Database Export', style: TextStyle(color: Color(0xFF64B5F6))),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Building: ${engine.currentBuilding}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Rooms Tagged: ${engine.rooms.length}', style: const TextStyle(color: Colors.white70)),
              Text('Area Zones Enclosed: ${engine.zones.length}', style: const TextStyle(color: Colors.white70)),
              Text('Corridor Edges: ${engine.edges.length}', style: const TextStyle(color: Colors.white70)),
              Text('Wi-Fi Fingerprints: ${engine.fingerprints.length}', style: const TextStyle(color: Colors.white70)),
              Text('Step Logs Recorded: ${engine.stepLogs.length}', style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24, height: 16),
              const Text('📁 Raw SQLite Database File:', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold)),
              SelectableText(dbPath, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                      icon: const Icon(Icons.copy, size: 14, color: Color(0xFF64B5F6)),
                      label: const Text('Processed Graph', style: TextStyle(fontSize: 11, color: Color(0xFF64B5F6))),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: processedJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied processed campus_graph.json to clipboard!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E)),
                      icon: const Icon(Icons.copy, size: 14, color: Color(0xFF81C784)),
                      label: const Text('Raw Steps JSON', style: TextStyle(fontSize: 11, color: Color(0xFF81C784))),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied raw step logs & Wi-Fi JSON to clipboard!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2250)),
                  icon: const Icon(Icons.description, size: 14, color: Color(0xFFBA68C8)),
                  label: const Text('📋 Copy Full Audit Report (Markdown)', style: TextStyle(fontSize: 11, color: Color(0xFFBA68C8), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final report = SurveyReportGenerator(engine: engine).generateMarkdownReport();
                    Clipboard.setData(ClipboardData(text: report));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied Executive Audit Report to clipboard!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
