import 'package:flutter_test/flutter_test.dart';
import 'package:ewunavsurvey/models/ble_fingerprint.dart';

void main() {
  group('BleBeaconSignal & BleFingerprint Path Loss & Serialization', () {
    test('Calculates exact 1.0 meter distance when RSSI equals txPower', () {
      final beacon = BleBeaconSignal(
        macAddress: 'AA:BB:CC:11:22:33',
        uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        major: 10,
        minor: 1,
        rssi: -59,
        txPower: -59,
        timestampMs: 1720000000,
      );

      expect(beacon.estimatedDistanceMeters, closeTo(1.0, 0.001));
    });

    test('Calculates 10.0 meters when signal experiences 22 dBm path loss attenuation', () {
      final beacon = BleBeaconSignal(
        macAddress: 'AA:BB:CC:11:22:33',
        rssi: -81,
        txPower: -59,
        timestampMs: 1720000000,
      );

      // ( -59 - (-81) ) / ( 10 * 2.2 ) = 22 / 22 = 1.0 => 10^1 = 10 meters
      expect(beacon.estimatedDistanceMeters, closeTo(10.0, 0.01));
    });

    test('BleFingerprint JSON serialization round trip', () {
      final original = BleFingerprint(
        id: 'fp_ble_01',
        floor: 'Ground Floor',
        x: 120.0,
        y: 250.0,
        timestampMs: 1720000000,
        beacons: [
          BleBeaconSignal(
            macAddress: 'C1:D2:E3:01:02:03',
            uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
            major: 100,
            minor: 4,
            rssi: -65,
            txPower: -59,
            timestampMs: 1720000000,
          ),
        ],
      );

      final json = original.toJson();
      final restored = BleFingerprint.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.floor, original.floor);
      expect(restored.x, 120.0);
      expect(restored.y, 250.0);
      expect(restored.beacons.length, 1);
      expect(restored.beacons.first.macAddress, 'C1:D2:E3:01:02:03');
      expect(restored.beacons.first.major, 100);
      expect(restored.beacons.first.minor, 4);
      expect(restored.beacons.first.rssi, -65);
    });
  });
}
