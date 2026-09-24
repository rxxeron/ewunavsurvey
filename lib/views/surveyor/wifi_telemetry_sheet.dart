import 'package:flutter/material.dart';
import '../../models/wifi_fingerprint.dart';

class WiFiTelemetrySheet extends StatelessWidget {
  final List<WiFiFingerprint> fingerprints;
  final VoidCallback onManualScan;

  const WiFiTelemetrySheet({
    super.key,
    required this.fingerprints,
    required this.onManualScan,
  });

  @override
  Widget build(BuildContext context) {
    final latestFp = fingerprints.isNotEmpty ? fingerprints.last : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2235),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wifi, color: Color(0xFF64B5F6)),
                  const SizedBox(width: 8),
                  Text(
                    '📶 Wi-Fi Signal Telemetry (${fingerprints.length} Scans)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF81C784)),
                onPressed: onManualScan,
                tooltip: 'Scan Now',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latestFp != null) ...[
            Text(
              'Coordinate: (${latestFp.x.round()}, ${latestFp.y.round()}) on ${latestFp.floor}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                itemCount: latestFp.accessPoints.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final ap = latestFp.accessPoints[index];
                  // Color code by signal strength (green > -60, yellow > -75, red < -75)
                  Color sigColor = const Color(0xFF81C784);
                  if (ap.level < -75) {
                    sigColor = const Color(0xFFE57373);
                  } else if (ap.level < -60) {
                    sigColor = const Color(0xFFFFD54F);
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.router, color: sigColor, size: 20),
                    title: Text(ap.ssid, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('BSSID: ${ap.bssid} • ${ap.frequency} MHz', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: Text(
                      '${ap.level} dBm',
                      style: TextStyle(color: sigColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No Wi-Fi fingerprints captured yet. Walk or tap Scan.', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
