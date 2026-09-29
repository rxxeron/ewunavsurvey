import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';
import 'package:ewunavsurvey/services/export_manager.dart';
import 'package:share_plus/share_plus.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;

  void _exportAndShare(BuildContext context, Future<dynamic> Function(ExportManager) exportFunc) async {
    setState(() => _isExporting = true);
    final engine = Provider.of<SlamSurveyorEngine>(context, listen: false);
    final manager = ExportManager(engine: engine);
    
    try {
      final file = await exportFunc(manager);
      if (file != null) {
        if (context.mounted) {
          SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'EWUNav Survey Export'));
          Navigator.of(context).pop();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed or no active building')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Survey Data'),
      content: _isExporting
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('IMDF Archive (.zip)'),
                  subtitle: const Text('OGC Indoor Mapping Data Format'),
                  onTap: () => _exportAndShare(context, (m) => m.exportIMDFArchive()),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('GeoJSON (.geojson)'),
                  subtitle: const Text('Corridor edges and accessible routes'),
                  onTap: () => _exportAndShare(context, (m) => m.exportGeoJSON()),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
