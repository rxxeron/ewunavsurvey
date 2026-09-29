import 'package:flutter/material.dart';

class PortalTransferModal extends StatefulWidget {
  final String currentFloor;
  final List<String> availableFloors;
  final double currentX;
  final double currentY;
  final double currentElevation;
  final Function(String name, String type) onTagOnly;
  final Function(String name, String type, String targetFloor) onTransfer;

  const PortalTransferModal({
    super.key,
    required this.currentFloor,
    required this.availableFloors,
    this.currentX = 400.0,
    this.currentY = 400.0,
    this.currentElevation = 0.0,
    required this.onTagOnly,
    required this.onTransfer,
  });

  @override
  State<PortalTransferModal> createState() => _PortalTransferModalState();
}

class _PortalTransferModalState extends State<PortalTransferModal> {
  final _nameController = TextEditingController(text: 'Staircase A');
  final _customFloorController = TextEditingController();
  String _portalType = 'stair';
  bool _createNewFloor = false;
  late String _targetFloor;

  @override
  void initState() {
    super.initState();
    final otherFloors = widget.availableFloors.where((f) => f != widget.currentFloor).toList();
    if (otherFloors.isNotEmpty) {
      _targetFloor = otherFloors.first;
    } else {
      _createNewFloor = true;
      _targetFloor = '1st Floor';
      _customFloorController.text = '1st Floor';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customFloorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherFloors = widget.availableFloors.where((f) => f != widget.currentFloor).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_portalType == 'stair' ? Icons.stairs : Icons.elevator, color: const Color(0xFFFF8A65), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _portalType == 'stair' ? '🪜 Staircase Survey' : '🛗 Elevator Survey',
                    style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141624),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Location: (${widget.currentX.round()}, ${widget.currentY.round()})', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('Floor: ${widget.currentFloor} (${widget.currentElevation >= 0 ? "+" : ""}${widget.currentElevation.toStringAsFixed(1)}m)',
                        style: const TextStyle(color: Color(0xFF81C784), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Portal Name',
                  hintText: 'e.g. Staircase A (East), Main Lift Lobby',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF141624),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _portalType,
                dropdownColor: const Color(0xFF1E2235),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF141624),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'stair', child: Text('Staircase 🪜')),
                  DropdownMenuItem(value: 'lift', child: Text('Elevator / Lift 🛗')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _portalType = val);
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
              const SizedBox(height: 6),
              const Text(
                'Destination Floor (Climb & Transfer)',
                style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (otherFloors.isNotEmpty && !_createNewFloor) ...[
                DropdownButtonFormField<String>(
                  initialValue: _targetFloor,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Existing Floor',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF141624),
                    border: OutlineInputBorder(),
                  ),
                  items: otherFloors.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _targetFloor = val);
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF81C784)),
                    label: const Text('Or create new floor', style: TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                    onPressed: () => setState(() => _createNewFloor = true),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _customFloorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Destination Floor Name',
                    hintText: 'e.g. 1st Floor, 2nd Floor, Rooftop',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF141624),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (otherFloors.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: const Text('Choose existing floor', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 11)),
                      onPressed: () => setState(() => _createNewFloor = false),
                    ),
                  ),
              ],

              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFD54F),
                        side: const BorderSide(color: Color(0xFFFFD54F)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        widget.onTagOnly(
                          _nameController.text.trim(),
                          _portalType,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Tag Here Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final destination = _createNewFloor
                            ? (_customFloorController.text.trim().isNotEmpty
                                ? _customFloorController.text.trim()
                                : '1st Floor')
                            : _targetFloor;
                        widget.onTransfer(
                          _nameController.text.trim(),
                          _portalType,
                          destination,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Climb & Link 3D', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
