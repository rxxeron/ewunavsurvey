import 'package:flutter/material.dart';
import '../../../models/corridor_edge.dart';
import '../../../services/slam_surveyor_engine.dart';
import '../../../services/db_service.dart';
import 'photo_attachment_widget.dart';

class CorridorPropertiesDialog extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final CorridorEdge? targetEdge;
  final VoidCallback? onPropertiesUpdated;

  const CorridorPropertiesDialog({
    super.key,
    required this.engine,
    required this.dbService,
    this.targetEdge,
    this.onPropertiesUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required SlamSurveyorEngine engine,
    required DbService dbService,
    CorridorEdge? targetEdge,
    VoidCallback? onPropertiesUpdated,
  }) {
    if (!engine.hasActiveBuilding) return Future.value();
    return showDialog(
      context: context,
      builder: (ctx) => CorridorPropertiesDialog(
        engine: engine,
        dbService: dbService,
        targetEdge: targetEdge,
        onPropertiesUpdated: onPropertiesUpdated,
      ),
    );
  }

  @override
  State<CorridorPropertiesDialog> createState() => _CorridorPropertiesDialogState();
}

class _CorridorPropertiesDialogState extends State<CorridorPropertiesDialog> {
  late final TextEditingController _widthCtrl;
  late final TextEditingController _runningSlopeCtrl;
  late final TextEditingController _crossSlopeCtrl;
  String _selectedSurface = 'tile';
  bool _hasTactilePaving = false;
  bool _isAccessible = true;

  final List<String> _surfaces = ['tile', 'concrete', 'carpet', 'vinyl', 'pavers', 'wood'];

  @override
  void initState() {
    super.initState();
    final edge = widget.targetEdge ?? (widget.engine.edges.isNotEmpty ? widget.engine.edges.last : null);
    _widthCtrl = TextEditingController(text: (edge?.widthMeters ?? 1.8).toStringAsFixed(1));
    _runningSlopeCtrl = TextEditingController(text: (edge?.runningSlopePercent ?? 0.0).toStringAsFixed(1));
    _crossSlopeCtrl = TextEditingController(text: (edge?.crossSlopePercent ?? 0.0).toStringAsFixed(1));
    _selectedSurface = edge?.surfaceType ?? 'tile';
    _hasTactilePaving = edge?.hasTactilePaving ?? false;
    _isAccessible = edge?.isAccessible ?? true;
  }

  String? _photoPath;

  @override
  void dispose() {
    _widthCtrl.dispose();
    _runningSlopeCtrl.dispose();
    _crossSlopeCtrl.dispose();
    super.dispose();
  }

  Widget _buildPresetWidthChip(String label, double meters) {
    final current = double.tryParse(_widthCtrl.text);
    final isSelected = current != null && (current - meters).abs() < 0.05;

    return ActionChip(
      backgroundColor: isSelected ? const Color(0xFF64B5F6) : const Color(0xFF141624),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () {
        setState(() {
          _widthCtrl.text = meters.toStringAsFixed(2);
        });
      },
    );
  }

  void _openWidthMeasurementSheet(BuildContext context) {
    int startSteps = widget.engine.pdrEngine.stepCount;
    int currentSteps = 0;
    bool isMeasuring = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final stride = widget.engine.pdrEngine.strideLengthMeters;
          final measuredWidth = currentSteps * stride;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.straighten, color: Color(0xFF81C784)),
                      SizedBox(width: 8),
                      Text('Perpendicular Width Measurement',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Stand against one wall of the corridor.\n2. Tap Start, then walk straight across to the opposite wall.\n3. Tap Finish to calculate the clear corridor width.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141624),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('$currentSteps Steps',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Calculated Width: ${measuredWidth.toStringAsFixed(2)} meters',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('(Using calibrated stride: ${stride.toStringAsFixed(2)}m)',
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!isMeasuring)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81C784),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Walking', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setSheetState(() {
                                isMeasuring = true;
                                startSteps = widget.engine.pdrEngine.stepCount;
                                currentSteps = 0;
                              });
                            },
                          ),
                        )
                      else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64B5F6),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.check),
                            label: const Text('Finish Wall-to-Wall', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final total = widget.engine.pdrEngine.stepCount - startSteps;
                              setSheetState(() {
                                isMeasuring = false;
                                currentSteps = total > 0 ? total : 2;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (currentSteps > 0) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(42),
                      ),
                      onPressed: () {
                        setState(() {
                          _widthCtrl.text = measuredWidth.toStringAsFixed(2);
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('Apply ${measuredWidth.toStringAsFixed(2)}m Width'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = double.tryParse(_widthCtrl.text) ?? 1.8;
    final runSlope = double.tryParse(_runningSlopeCtrl.text) ?? 0.0;
    final crossSlope = double.tryParse(_crossSlopeCtrl.text) ?? 0.0;

    final hasWidthViolation = width < 0.915; // ADA min 0.915m (36 inches)
    final hasRunSlopeViolation = runSlope > 8.33; // ADA max 8.33% (1:12 ramp)
    final hasCrossSlopeViolation = crossSlope > 2.08; // ADA max 2.08% (1:48)

    final hasAdaViolations = hasWidthViolation || hasRunSlopeViolation || hasCrossSlopeViolation;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2235),
      title: const Row(
        children: [
          Icon(Icons.accessible, color: Color(0xFF64B5F6), size: 22),
          SizedBox(width: 8),
          Text('Corridor & Ramp ADA Properties', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify architectural dimensions & accessibility standards for this walkway.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 12),

            // ADA Status Banner
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
                      hasAdaViolations
                          ? 'ADA Non-Compliant Walkway'
                          : 'ADA Compliant Walkway / Ramp',
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

            // Width Field
            TextField(
              controller: _widthCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Clear Corridor Width (meters)',
                labelStyle: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12),
                hintText: 'e.g. 1.8',
                helperText: hasWidthViolation ? '⚠️ Under ADA min (0.915m / 36 in)' : 'ADA Minimum: 0.915m',
                helperStyle: TextStyle(color: hasWidthViolation ? Colors.orangeAccent : Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF141624),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.straighten, color: Color(0xFF81C784)),
                  tooltip: 'Measure Width by Walking',
                  onPressed: () => _openWidthMeasurementSheet(context),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildPresetWidthChip('0.92m (ADA Min)', 0.92),
                _buildPresetWidthChip('1.50m (2-Wheelchair)', 1.50),
                _buildPresetWidthChip('1.80m (Standard)', 1.80),
                _buildPresetWidthChip('2.40m (Wide)', 2.40),
              ],
            ),
            const SizedBox(height: 12),

            // Running Slope Field
            TextField(
              controller: _runningSlopeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Running Slope / Ramp Grade (%)',
                labelStyle: const TextStyle(color: Color(0xFF81C784), fontSize: 12),
                hintText: 'e.g. 0.0 (flat) or 5.0 (ramp)',
                helperText: hasRunSlopeViolation ? '🚨 Exceeds ADA max 8.33% (1:12 slope)' : 'ADA Max: 8.33%',
                helperStyle: TextStyle(color: hasRunSlopeViolation ? Colors.redAccent : Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF141624),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Cross Slope Field
            TextField(
              controller: _crossSlopeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Cross Slope / Lateral Incline (%)',
                labelStyle: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                hintText: 'e.g. 1.0',
                helperText: hasCrossSlopeViolation ? '🚨 Exceeds ADA max 2.08% (1:48 slope)' : 'ADA Max: 2.08%',
                helperStyle: TextStyle(color: hasCrossSlopeViolation ? Colors.redAccent : Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF141624),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Surface Type Selector
            const Text('Floor Surface Material:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _surfaces.map((s) {
                final isSel = s == _selectedSurface;
                return ChoiceChip(
                  label: Text(s.toUpperCase(), style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: const Color(0xFF64B5F6),
                  backgroundColor: const Color(0xFF141624),
                  onSelected: (val) {
                    if (val) setState(() => _selectedSurface = s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            PhotoAttachmentWidget(
              photoPath: _photoPath,
              onPhotoChanged: (path) => setState(() => _photoPath = path),
              label: '📸 Corridor / Ramp Photo Audit',
            ),
            const SizedBox(height: 10),

            // Tactile paving and accessible switches
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tactile Ground Surface Indicator (TGSI)', style: TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: const Text('Raised tiles for visually impaired navigation', style: TextStyle(color: Colors.white38, fontSize: 10)),
              value: _hasTactilePaving,
              activeThumbColor: const Color(0xFF81C784),
              onChanged: (val) => setState(() => _hasTactilePaving = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wheelchair Accessible Route', style: TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: const Text('Flag this path as suitable for wheelchair navigation', style: TextStyle(color: Colors.white38, fontSize: 10)),
              value: _isAccessible && !hasAdaViolations,
              activeThumbColor: const Color(0xFF64B5F6),
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
            final w = double.tryParse(_widthCtrl.text) ?? 1.8;
            final rs = double.tryParse(_runningSlopeCtrl.text) ?? 0.0;
            final cs = double.tryParse(_crossSlopeCtrl.text) ?? 0.0;
            final autoAccessible = !hasAdaViolations && _isAccessible;

            // Apply to targetEdge or all recent edges on this floor
            final edge = widget.targetEdge ?? (widget.engine.edges.isNotEmpty ? widget.engine.edges.last : null);
            if (edge != null) {
              final updated = CorridorEdge(
                fromId: edge.fromId,
                toId: edge.toId,
                distanceMeters: edge.distanceMeters,
                type: edge.type,
                isAccessible: autoAccessible,
                widthMeters: w,
                runningSlopePercent: rs,
                crossSlopePercent: cs,
                surfaceType: _selectedSurface,
                hasTactilePaving: _hasTactilePaving,
                passCount: edge.passCount,
              );

              final idx = widget.engine.edges.indexOf(edge);
              if (idx != -1) {
                widget.engine.edges[idx] = updated;
              }
              widget.dbService.saveCorridorEdge(updated);
            }

            Navigator.pop(context);
            widget.onPropertiesUpdated?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF1C442E),
                content: Text('Walkway ADA properties saved successfully!'),
              ),
            );
          },
          child: const Text('Apply Properties', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
