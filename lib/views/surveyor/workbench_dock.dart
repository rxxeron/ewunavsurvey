import 'package:flutter/material.dart';
import '../../services/slam_surveyor_engine.dart';
import '../../services/db_service.dart';

class WorkbenchDock extends StatefulWidget {
  final SlamSurveyorEngine engine;
  final DbService dbService;
  final VoidCallback onToggleRecording;
  final VoidCallback? onPauseAndSave;
  final VoidCallback onCompleteFloor;
  final void Function(String doorSide) onOpenRoomModal;
  final void Function(String portalType) onOpenPortalModal;
  final VoidCallback? onOpenWashroom;
  final VoidCallback? onManageRooms;
  final VoidCallback? onOpen3D;
  final VoidCallback onDeadEnd;
  final VoidCallback onAddComment;
  final VoidCallback onStepModified;
  final VoidCallback onCorridorProperties;
  final VoidCallback onDoorAudit;

  const WorkbenchDock({
    super.key,
    required this.engine,
    required this.dbService,
    required this.onToggleRecording,
    this.onPauseAndSave,
    required this.onCompleteFloor,
    required this.onOpenRoomModal,
    required this.onOpenPortalModal,
    this.onOpenWashroom,
    this.onManageRooms,
    this.onOpen3D,
    required this.onDeadEnd,
    required this.onAddComment,
    required this.onStepModified,
    required this.onCorridorProperties,
    required this.onDoorAudit,
  });

  @override
  State<WorkbenchDock> createState() => _WorkbenchDockState();
}

class _WorkbenchDockState extends State<WorkbenchDock> {
  Widget _buildWorkbenchCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;

    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Color(0xFF141622),
        border: Border(left: BorderSide(color: Color(0xFF2C324A))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 3D View and Room List Header Row
          Row(
            children: [
              if (widget.onOpen3D != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2840),
                      side: const BorderSide(color: Color(0xFF64B5F6)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.view_in_ar, size: 16, color: Color(0xFF64B5F6)),
                    label: const Text('🏢 3D Building', style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: widget.onOpen3D,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.onManageRooms != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2235),
                      side: const BorderSide(color: Color(0xFFFFD54F)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.list_alt, size: 16, color: Color(0xFFFFD54F)),
                    label: const Text('📋 Manage Rooms', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: widget.onManageRooms,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Card 0: Active Survey Session Lifecycle & Database Save
          _buildWorkbenchCard(
            '⏱️ Active Survey Session',
            Column(
              children: [
                if (engine.isRecording) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B402B),
                      side: const BorderSide(color: Color(0xFF81C784)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.pause_circle_filled, color: Color(0xFFFFB74D), size: 18),
                    label: const Text('⏸️ Pause & 💾 Save Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      if (widget.onPauseAndSave != null) {
                        widget.onPauseAndSave!();
                      } else {
                        widget.onToggleRecording();
                      }
                    },
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF163824),
                            side: const BorderSide(color: Color(0xFF81C784)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.play_circle_fill, color: Color(0xFF81C784), size: 16),
                          label: const Text('▶️ Resume Walk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: widget.onToggleRecording,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB74D),
                            side: const BorderSide(color: Color(0xFFFFB74D)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text('💾 Save Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: widget.onPauseAndSave,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card 1: Walking Controls & Undo
          _buildWorkbenchCard(
            '👣 Physical Movement',
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      engine.pdrEngine.isHardwareActive ? Icons.directions_walk : Icons.touch_app,
                      size: 14,
                      color: engine.pdrEngine.isHardwareActive ? const Color(0xFF81C784) : const Color(0xFF64B5F6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        engine.pdrEngine.isHardwareActive
                            ? 'Pedometer: ACTIVE (walking auto-records steps)'
                            : 'Pedometer: Standby (Use buttons or walk on phone)',
                        style: TextStyle(
                          fontSize: 10,
                          color: engine.pdrEngine.isHardwareActive ? const Color(0xFF81C784) : Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: engine.isRecording ? const Color(0xFF143020) : const Color(0xFF33200D),
                          side: BorderSide(color: engine.isRecording ? const Color(0xFF81C784) : const Color(0xFFFFB74D)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: Icon(
                          engine.isRecording ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 16,
                          color: engine.isRecording ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                        ),
                        label: Text(
                          engine.isRecording ? '🟢 Recording' : '🟠 Paused',
                          style: TextStyle(
                            color: engine.isRecording ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: widget.onToggleRecording,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        side: const BorderSide(color: Color(0xFF64B5F6)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF64B5F6)),
                      label: const Text('Complete', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: widget.onCompleteFloor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.directions_walk, color: Color(0xFF64B5F6), size: 18),
                        label: const Text('👣 Step (0.75m)', style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          engine.manualStep(0.75);
                          widget.onStepModified();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C442E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.fast_forward, color: Color(0xFF81C784), size: 18),
                        label: const Text('🚶 5 Steps (3.8m)', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          engine.manualStep(3.75);
                          widget.onStepModified();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD54F), side: const BorderSide(color: Color(0xFFFFD54F))),
                        onPressed: () {
                          engine.turn(-90);
                          widget.onStepModified();
                        },
                        child: const Text('↰ Left 90°', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD54F), side: const BorderSide(color: Color(0xFFFFD54F))),
                        onPressed: () {
                          engine.turn(90);
                          widget.onStepModified();
                        },
                        child: const Text('Right 90° ↱', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      onPressed: () {
                        engine.turn(180);
                        widget.onStepModified();
                      },
                      child: const Text('🔄 U-Turn', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.undo, size: 16),
                        label: const Text('⎌ Undo / Delete Last Step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (engine.stepLogs.isNotEmpty) {
                            final last = engine.stepLogs.last;
                            engine.undo();
                            widget.dbService.deleteStepLog(last.stepIndex);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Undid and deleted previous step.')),
                            );
                          } else {
                            engine.undo();
                          }
                          widget.onStepModified();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card 2: Tag Rooms & Portals
          _buildWorkbenchCard(
            '🚪 Tag Rooms & Vertical Portals',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E), padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF81C784)),
                        label: const Text('Door LEFT', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => widget.onOpenRoomModal('left'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C442E), padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF81C784)),
                        label: const Text('Door RIGHT', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => widget.onOpenRoomModal('right'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF8A65), side: const BorderSide(color: Color(0xFFFF8A65))),
                        icon: const Icon(Icons.stairs, size: 16),
                        label: const Text('🪜 Stair', style: TextStyle(fontSize: 12)),
                        onPressed: () => widget.onOpenPortalModal('stair'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFBA68C8), side: const BorderSide(color: Color(0xFFBA68C8))),
                        icon: const Icon(Icons.elevator, size: 16),
                        label: const Text('🛗 Lift', style: TextStyle(fontSize: 12)),
                        onPressed: () => widget.onOpenPortalModal('lift'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.onOpenWashroom != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE57373),
                            side: const BorderSide(color: Color(0xFFE57373)),
                          ),
                          icon: const Icon(Icons.wc, size: 16),
                          label: const Text('🚻 Washroom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: widget.onOpenWashroom,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF5350),
                          side: const BorderSide(color: Color(0xFFEF5350)),
                        ),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('🚫 Dead End Wall', style: TextStyle(fontSize: 12)),
                        onPressed: widget.onDeadEnd,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64B5F6),
                          side: const BorderSide(color: Color(0xFF64B5F6)),
                        ),
                        icon: const Icon(Icons.accessible, size: 16),
                        label: const Text('♿ Walkway ADA', style: TextStyle(fontSize: 11)),
                        onPressed: widget.onCorridorProperties,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF81C784),
                          side: const BorderSide(color: Color(0xFF81C784)),
                        ),
                        icon: const Icon(Icons.sensor_door, size: 16),
                        label: const Text('🚪 Door Audit', style: TextStyle(fontSize: 11)),
                        onPressed: widget.onDoorAudit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card 3: Step Field Notes & Comments
          _buildWorkbenchCard(
            '💬 Field Notes & Annotations',
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D3212), side: const BorderSide(color: Color(0xFFFFD54F)), padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.comment, color: Color(0xFFFFD54F), size: 18),
              label: const Text('Add Note at Current Step', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: widget.onAddComment,
            ),
          ),

          // Card 4: Live Wi-Fi Telemetry
          _buildWorkbenchCard(
            '📶 Wi-Fi Signal Telemetry',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: engine.wifiScanner.isHardwareSupported ? const Color(0xFF1C442E) : const Color(0xFF332A15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        engine.wifiScanner.isHardwareSupported ? Icons.check_circle : Icons.info_outline,
                        size: 12,
                        color: engine.wifiScanner.isHardwareSupported ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          engine.wifiScanner.isHardwareSupported
                              ? 'Mode: Live Android Wi-Fi Adapter'
                              : 'Mode: Web Sandbox (Real chips scan on Android)',
                          style: TextStyle(
                            fontSize: 10,
                            color: engine.wifiScanner.isHardwareSupported ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fingerprints: ${engine.fingerprints.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF64B5F6)),
                      label: const Text('Scan Now', style: TextStyle(fontSize: 11, color: Color(0xFF64B5F6))),
                      onPressed: () {
                        engine.wifiScanner.scanAtLocation(
                          floor: engine.currentFloor,
                          x: engine.currentX,
                          y: engine.currentY,
                        );
                        widget.onStepModified();
                      },
                    ),
                  ],
                ),
                if (!engine.wifiScanner.isHardwareSupported)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simulate APs for Web testing:', style: TextStyle(color: Colors.white60, fontSize: 10)),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: engine.wifiScanner.enableWebSimulation,
                            activeThumbColor: const Color(0xFF64B5F6),
                            onChanged: (val) {
                              setState(() {
                                engine.wifiScanner.enableWebSimulation = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                if (engine.fingerprints.isNotEmpty && engine.fingerprints.last.accessPoints.isNotEmpty) ...[
                  for (var ap in engine.fingerprints.last.accessPoints.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📡 ${ap.ssid}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${ap.level} dBm', style: TextStyle(color: ap.level > -70 ? const Color(0xFF81C784) : const Color(0xFFFFD54F), fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('0 access points logged. Wi-Fi scans live on Android.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
