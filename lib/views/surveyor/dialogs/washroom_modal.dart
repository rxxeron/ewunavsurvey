import 'package:flutter/material.dart';
import '../../../models/room_node.dart';

class WashroomModal extends StatefulWidget {
  final String defaultSide;
  final Function(String name, RoomCategory category, String doorSide, bool isAccessible) onSave;

  const WashroomModal({
    super.key,
    this.defaultSide = 'left',
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    String defaultSide = 'left',
    required Function(String name, RoomCategory category, String doorSide, bool isAccessible) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => WashroomModal(
        defaultSide: defaultSide,
        onSave: onSave,
      ),
    );
  }

  @override
  State<WashroomModal> createState() => _WashroomModalState();
}

class _WashroomModalState extends State<WashroomModal> {
  RoomCategory _selectedType = RoomCategory.restroom;
  late String _doorSide;
  final _nameController = TextEditingController();
  bool _isAccessible = true;

  @override
  void initState() {
    super.initState();
    _doorSide = widget.defaultSide;
    _nameController.text = 'Restroom / Washroom';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectCategory(RoomCategory cat, String defaultName) {
    setState(() {
      _selectedType = cat;
      _nameController.text = defaultName;
      if (cat == RoomCategory.restroom) {
        _isAccessible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wc, color: Color(0xFFE57373), size: 24),
                    SizedBox(width: 8),
                    Text(
                      '🚻 Mark Washroom',
                      style: TextStyle(color: Color(0xFF64B5F6), fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select Washroom Type:',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 4 Quick Selection Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Text('🚹'),
                  label: const Text('Male Washroom'),
                  selected: _selectedType == RoomCategory.restroomMale,
                  selectedColor: const Color(0xFF64B5F6),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: _selectedType == RoomCategory.restroomMale ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) _selectCategory(RoomCategory.restroomMale, 'Male Washroom');
                  },
                ),
                ChoiceChip(
                  avatar: const Text('🚺'),
                  label: const Text('Female Washroom'),
                  selected: _selectedType == RoomCategory.restroomFemale,
                  selectedColor: const Color(0xFFF48FB1),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: _selectedType == RoomCategory.restroomFemale ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) _selectCategory(RoomCategory.restroomFemale, 'Female Washroom');
                  },
                ),
                ChoiceChip(
                  avatar: const Text('🚻'),
                  label: const Text('Common / All-Gender'),
                  selected: _selectedType == RoomCategory.restroom,
                  selectedColor: const Color(0xFFFFD54F),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: _selectedType == RoomCategory.restroom ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) _selectCategory(RoomCategory.restroom, 'Restroom');
                  },
                ),
                ChoiceChip(
                  avatar: const Text('♿'),
                  label: const Text('Accessible Washroom'),
                  selected: _isAccessible && _nameController.text.contains('Accessible'),
                  selectedColor: const Color(0xFF81C784),
                  backgroundColor: const Color(0xFF141624),
                  labelStyle: TextStyle(
                    color: _isAccessible && _nameController.text.contains('Accessible') ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      _isAccessible = true;
                      _selectCategory(RoomCategory.restroom, 'Accessible Washroom');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Washroom Name / Label
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Washroom Name / Label',
                hintText: 'e.g. Male Washroom (West), Faculty Washroom',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF141624),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Door Position
            DropdownButtonFormField<String>(
              initialValue: _doorSide,
              dropdownColor: const Color(0xFF1E2235),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Door Position along hallway',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF141624),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'left', child: Text('Door on my LEFT')),
                DropdownMenuItem(value: 'right', child: Text('Door on my RIGHT')),
                DropdownMenuItem(value: 'straight', child: Text('Door directly AHEAD')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _doorSide = val);
              },
            ),
            const SizedBox(height: 8),

            // Wheelchair Accessible Toggle
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('♿ Wheelchair Accessible Doorway', style: TextStyle(color: Colors.white70, fontSize: 12)),
              value: _isAccessible,
              activeColor: const Color(0xFF81C784),
              onChanged: (val) => setState(() => _isAccessible = val ?? true),
            ),
            const SizedBox(height: 12),

            // Save Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE57373),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      final name = _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : 'Washroom';
                      widget.onSave(name, _selectedType, _doorSide, _isAccessible);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Washroom', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
