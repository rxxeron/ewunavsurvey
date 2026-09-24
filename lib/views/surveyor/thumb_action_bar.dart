import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThumbActionBar extends StatelessWidget {
  final VoidCallback onDoorLeft;
  final VoidCallback onDoorRight;
  final VoidCallback onTurnLeft;
  final VoidCallback onTurnRight;
  final VoidCallback onWalkStraight;
  final VoidCallback onManualStep;
  final VoidCallback onMarkStair;
  final VoidCallback onMarkLift;
  final VoidCallback onAddComment;
  final VoidCallback onUTurn;
  final VoidCallback onUndo;

  const ThumbActionBar({
    super.key,
    required this.onDoorLeft,
    required this.onDoorRight,
    required this.onTurnLeft,
    required this.onTurnRight,
    required this.onWalkStraight,
    required this.onManualStep,
    required this.onMarkStair,
    required this.onMarkLift,
    required this.onAddComment,
    required this.onUTurn,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141624),
        border: Border(top: BorderSide(color: Color(0xFF2C324A))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Fast Door Marking Thumb Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C442E),
                    foregroundColor: const Color(0xFF81C784),
                    side: const BorderSide(color: Color(0xFF81C784)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('🚪 Door LEFT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDoorLeft();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C442E),
                    foregroundColor: const Color(0xFF81C784),
                    side: const BorderSide(color: Color(0xFF81C784)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Door RIGHT 🚪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDoorRight();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Turn Corner & Walking Controls
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    side: const BorderSide(color: Color(0xFFFFD54F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onTurnLeft();
                  },
                  child: const Text('↰ Left 90°', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    foregroundColor: const Color(0xFF64B5F6),
                    side: const BorderSide(color: Color(0xFF64B5F6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onManualStep();
                  },
                  child: const Text('👣 Step (0.75m)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    side: const BorderSide(color: Color(0xFFFFD54F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onTurnRight();
                  },
                  child: const Text('Right 90° ↱', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3: Vertical Portals & Quick Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8A65)),
                  icon: const Icon(Icons.stairs, size: 16),
                  label: const Text('🪜 Stair', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onMarkStair();
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA68C8)),
                  icon: const Icon(Icons.elevator, size: 16),
                  label: const Text('🛗 Lift', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onMarkLift();
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD54F)),
                  icon: const Icon(Icons.comment, size: 16),
                  label: const Text('💬 Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAddComment();
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('🔄 U-Turn', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onUTurn();
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('↩️ Undo', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onUndo();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
