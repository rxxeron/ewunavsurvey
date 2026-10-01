import 'package:flutter/material.dart';
import '../../models/room_node.dart';
import '../../models/faculty_member.dart';
import 'dialogs/photo_attachment_widget.dart';

class FacultyRoomModal extends StatefulWidget {
  final String doorSide;
  final Function(
    String name,
    String roomNumber,
    RoomCategory category,
    String department,
    String doorSide,
    int capacity,
    List<FacultyMember> faculty,
    double doorWidth,
    double thresholdHeight,
    String? photoPath,
    String? customCategoryName,
    int facultyCount,
    String doorType,
    String doorMaterial,
  ) onSave;

  const FacultyRoomModal({
    super.key,
    required this.doorSide,
    required this.onSave,
  });

  @override
  State<FacultyRoomModal> createState() => _FacultyRoomModalState();
}

class _FacultyRoomModalState extends State<FacultyRoomModal> {
  final _roomNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _deptController = TextEditingController(); // No default department!
  final _customTypeController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');

  RoomCategory _selectedCategory = RoomCategory.classroom;
  late String _selectedSide;
  String _doorType = 'push';
  String _doorMaterial = 'wood';
  int _facultyCount = 1;
  final List<FacultyMember> _facultyList = [];

  // Faculty entry controllers
  final _facNameController = TextEditingController();
  final _facDesignationController = TextEditingController(text: 'Assistant Professor');
  final _facEmailController = TextEditingController();
  final _facHoursController = TextEditingController();
  bool _showAddFaculty = false;
  String? _roomPhotoPath;
  
  final _doorWidthCtrl = TextEditingController(text: '0.90');
  final _thresholdHeightCtrl = TextEditingController(text: '6.0');

  @override
  void initState() {
    super.initState();
    _selectedSide = widget.doorSide;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _nameController.dispose();
    _deptController.dispose();
    _customTypeController.dispose();
    _capacityController.dispose();
    _facNameController.dispose();
    _facDesignationController.dispose();
    _facEmailController.dispose();
    _facHoursController.dispose();
    _doorWidthCtrl.dispose();
    _thresholdHeightCtrl.dispose();
    super.dispose();
  }

  void _addFacultyMember() {
    if (_facNameController.text.trim().isEmpty) return;
    setState(() {
      _facultyList.add(FacultyMember(
        name: _facNameController.text.trim(),
        designation: _facDesignationController.text.trim(),
        department: _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'General',
        email: _facEmailController.text.trim().isNotEmpty ? _facEmailController.text.trim() : null,
        counselingHours: _facHoursController.text.trim().isNotEmpty ? _facHoursController.text.trim() : null,
      ));
      _facNameController.clear();
      _facEmailController.clear();
      _facHoursController.clear();
      _showAddFaculty = false;
      if (_facultyList.length > _facultyCount) {
        _facultyCount = _facultyList.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFacultyOffice = (_selectedCategory == RoomCategory.facultyOffice);
    final bool isCustomCategory = (_selectedCategory == RoomCategory.custom);

    return Dialog(
      backgroundColor: const Color(0xFF1E2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 660),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🚪 Mark Room / Facility',
                    style: TextStyle(color: Color(0xFF64B5F6), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Room Number & Name
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _roomNumberController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Room #',
                        hintText: 'e.g. 240, 312',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Room Name / Description',
                        hintText: 'e.g. Language Lab, Exam Hall',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category & Door Side
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RoomCategory>(
                      initialValue: _selectedCategory,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: RoomCategory.classroom, child: Text('Classroom (Shared)')),
                        DropdownMenuItem(value: RoomCategory.lab, child: Text('Computer/Science Lab')),
                        DropdownMenuItem(value: RoomCategory.facultyOffice, child: Text('Faculty/Staff Office')),
                        DropdownMenuItem(value: RoomCategory.adminOffice, child: Text('Admin (Accounts, Reg)')),
                        DropdownMenuItem(value: RoomCategory.restroom, child: Text('Restroom / Washroom')),
                        DropdownMenuItem(value: RoomCategory.amenity, child: Text('Cafeteria / Library')),
                        DropdownMenuItem(value: RoomCategory.custom, child: Text('✨ Custom Landmark / Other')),
                      ],
                      onChanged: (cat) {
                        if (cat != null) setState(() => _selectedCategory = cat);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSide,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Door Position',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'left', child: Text('Door on LEFT')),
                        DropdownMenuItem(value: 'right', child: Text('Door on RIGHT')),
                        DropdownMenuItem(value: 'straight', child: Text('Door AHEAD')),
                      ],
                      onChanged: (side) {
                        if (side != null) setState(() => _selectedSide = side);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Custom Landmark Name (shown only if Custom is selected)
              if (isCustomCategory) ...[
                TextField(
                  controller: _customTypeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Custom Landmark / Room Type',
                    hintText: 'e.g. Prayer Room, Server Room, Generator, Store Room, Club Room',
                    labelStyle: TextStyle(color: Color(0xFFFFD54F)),
                    filled: true,
                    fillColor: Color(0xFF242214),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_location_alt, color: Color(0xFFFFD54F), size: 18),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Capacity & (Optional) Department only if Faculty Office
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Capacity (Seats)',
                        hintText: '40',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (isFacultyOffice) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _deptController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Department (Optional)',
                          hintText: 'e.g. CSE, EEE, BBA',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Color(0xFF141624),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Door Mechanism & Glass Option
              const Text('Door Type & Glass Option:', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildDoorChip('push', 'wood', '🚪 Push / Swing', 'Standard hinged push door'),
                  _buildDoorChip('push_glass', 'glass', '🪟 Push Glass', 'Push/swing clear glass door'),
                  _buildDoorChip('slide', 'wood', '↔️ Slide Door', 'Sliding door'),
                  _buildDoorChip('slide_glass', 'glass', '🪟↔️ Slide Glass', 'Sliding glass door (common in labs/faculty)'),
                  _buildDoorChip('automatic_glass', 'glass', '⚡ Auto Glass', 'Automatic sliding glass door'),
                  _buildDoorChip('push', 'metal', '🚪 Metal / Heavy', 'Heavy metal/security door'),
                ],
              ),
              const SizedBox(height: 12),

              // ADA Details
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _doorWidthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Door Width (m)',
                        hintText: '0.90',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _thresholdHeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Threshold (mm)',
                        hintText: '6.0',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF141624),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              PhotoAttachmentWidget(
                photoPath: _roomPhotoPath,
                onPhotoChanged: (path) => setState(() => _roomPhotoPath = path),
                label: '📸 Room Signage & Doorway Photo',
              ),
              const SizedBox(height: 16),

              // Faculty Occupancy Section (Shown for Faculty Offices)
              if (isFacultyOffice) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191B2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👨‍🏫 Faculty Occupancy',
                                style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'How many faculty occupy this room?',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          // Stepper: [-] Count [+]
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C324A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                                  onPressed: () {
                                    if (_facultyCount > 1) {
                                      setState(() => _facultyCount--);
                                    }
                                  },
                                ),
                                Text(
                                  '$_facultyCount',
                                  style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                  onPressed: () {
                                    setState(() => _facultyCount++);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detailed Profiles (${_facultyList.length})',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          TextButton.icon(
                            icon: Icon(_showAddFaculty ? Icons.close : Icons.person_add, color: const Color(0xFF81C784), size: 15),
                            label: Text(_showAddFaculty ? 'Cancel' : 'Add Teacher Details', style: const TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                            onPressed: () => setState(() => _showAddFaculty = !_showAddFaculty),
                          ),
                        ],
                      ),
                      if (_facultyList.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _facultyList.map((f) => Chip(
                            backgroundColor: const Color(0xFF2C324A),
                            label: Text('${f.name} (${f.designation})', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            onDeleted: () => setState(() => _facultyList.remove(f)),
                            deleteIconColor: Colors.redAccent,
                          )).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add Faculty Inline Form
              if (_showAddFaculty && isFacultyOffice) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141624),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _facNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Faculty Name",
                          hintText: "e.g. Dr. Md. Mozammel Huq Azad Khan",
                          labelStyle: TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _facDesignationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Designation",
                          hintText: "e.g. Professor, Chairperson, Lecturer",
                          labelStyle: TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _facEmailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Email (optional)",
                          hintText: "e.g. chair.cse@ewubd.edu",
                          labelStyle: TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _facHoursController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Counseling Hours (optional)",
                          hintText: "e.g. Sun/Tue 11:00-13:00",
                          labelStyle: TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
                        onPressed: _addFacultyMember,
                        child: const Text('Save Faculty Member', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final roomNum = _roomNumberController.text.trim();
                        final customTypeName = _customTypeController.text.trim();
                        final name = _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : (customTypeName.isNotEmpty
                                ? customTypeName
                                : (roomNum.isNotEmpty ? 'Room $roomNum' : 'Room'));
                        final cap = int.tryParse(_capacityController.text.trim()) ?? 40;
                        final dWidth = double.tryParse(_doorWidthCtrl.text.trim()) ?? 0.90;
                        final tHeight = double.tryParse(_thresholdHeightCtrl.text.trim()) ?? 6.0;

                        widget.onSave(
                          name,
                          roomNum,
                          _selectedCategory,
                          _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'General',
                          _selectedSide,
                          cap,
                          _facultyList,
                          dWidth,
                          tHeight,
                          _roomPhotoPath,
                          customTypeName.isNotEmpty ? customTypeName : null,
                          _facultyCount,
                          _doorType,
                          _doorMaterial,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Save Room Pin', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoorChip(String type, String material, String label, String tooltip) {
    final isSelected = (_doorType == type && _doorMaterial == material);
    return Tooltip(
      message: tooltip,
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
        selected: isSelected,
        selectedColor: material == 'glass' ? const Color(0xFF4FC3F7) : const Color(0xFF81C784),
        backgroundColor: const Color(0xFF141624),
        onSelected: (val) {
          if (val) {
            setState(() {
              _doorType = type;
              _doorMaterial = material;
            });
          }
        },
      ),
    );
  }
}
