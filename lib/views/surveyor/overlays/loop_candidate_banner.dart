import 'package:flutter/material.dart';
import '../../../services/slam_surveyor_engine.dart';

class LoopCandidateBanner extends StatelessWidget {
  final SlamSurveyorEngine engine;
  final VoidCallback onEnclosePressed;
  final VoidCallback onDismissPressed;

  const LoopCandidateBanner({
    super.key,
    required this.engine,
    required this.onEnclosePressed,
    required this.onDismissPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cand = engine.pendingLoopCandidate;
    if (cand == null) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xEE1E2235),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x44FFD54F), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.all_inclusive, color: Color(0xFFFFD54F), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Closed Loop Detected!',
                    style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    'Enclose as Courtyard, Rooftop, or Hallway (${cand.areaSqMeters.toStringAsFixed(0)} m²)',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onEnclosePressed,
              child: const Text('Enclose Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismissPressed,
            ),
          ],
        ),
      ),
    );
  }
}
