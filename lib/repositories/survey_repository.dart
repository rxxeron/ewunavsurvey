import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/slam_surveyor_engine.dart';
import '../services/db_service.dart';
import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../models/area_zone.dart';
import '../models/opening.dart';
import '../models/wifi_fingerprint.dart';
import '../models/step_log_record.dart';

class SurveyRepository {
  final SlamSurveyorEngine engine;
  final DbService dbService;

  Timer? _autoBackupTimer;
  bool _isDisposed = false;

  SurveyRepository({
    required this.engine,
    required this.dbService,
  }) {
    _startAutoBackupTimer();
  }

  void _startAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isDisposed && engine.hasActiveBuilding) {
        saveCrashRecoveryBackup();
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _autoBackupTimer?.cancel();
  }

  /// Safe database execution with exponential backoff retry logic
  Future<T?> _safeDbExecute<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        if (kDebugMode) {
          print('⚠️ SurveyRepository SQLite error (attempt $attempts/$maxRetries): $e');
        }
        if (attempts >= maxRetries) {
          if (kDebugMode) {
            print('🚨 SurveyRepository operation failed after $maxRetries retries: $e');
          }
          return null;
        }
        await Future.delayed(Duration(milliseconds: 100 * (1 << attempts)));
      }
    }
    return null;
  }

  // --- Transactional Entity Mutations ---

  Future<void> saveStepLog(StepLogRecord record) async {
    await _safeDbExecute(() => dbService.saveStepLog(record));
  }

  Future<void> updateStepComment(int stepIndex, String comment) async {
    await _safeDbExecute(() => dbService.updateStepComment(stepIndex, comment));
  }

  Future<void> deleteStepLog(int stepIndex) async {
    engine.deleteStepLog(stepIndex);
    await _safeDbExecute(() => dbService.deleteStepLog(stepIndex));
  }

  Future<void> saveRoom(RoomNode room) async {
    await _safeDbExecute(() => dbService.saveRoom(room));
  }

  Future<void> deleteRoom(String id) async {
    engine.deleteRoom(id);
    await _safeDbExecute(() => dbService.deleteRoom(id));
  }

  Future<void> saveEdge(CorridorEdge edge) async {
    await _safeDbExecute(() => dbService.saveEdge(edge));
  }

  Future<void> saveZone(AreaZone zone) async {
    await _safeDbExecute(() => dbService.saveZone(zone));
  }

  Future<void> deleteZone(String id) async {
    engine.deleteZone(id);
    await _safeDbExecute(() => dbService.deleteZone(id));
  }

  Future<void> saveOpening(Opening opening) async {
    await _safeDbExecute(() => dbService.saveOpening(opening));
  }

  Future<void> saveFingerprint(WiFiFingerprint fp) async {
    await _safeDbExecute(() => dbService.saveFingerprint(fp));
  }

  // --- Offline Crash Recovery & Periodic State Snapshots ---

  Future<File?> _getBackupFile(String buildingName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitized = buildingName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      return File('${dir.path}/ewunav_backup_$sanitized.json');
    } catch (_) {
      return null;
    }
  }

  Future<String?> getLatestBackupName() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().whereType<File>().where((f) => f.path.contains('ewunav_backup_') && f.path.endsWith('.json')).toList();
      if (files.isEmpty) return null;
      
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final name = files.first.path.split('ewunav_backup_').last.replaceAll('.json', '').replaceAll('_', ' ');
      return name;
    } catch (_) {
      return null;
    }
  }

  Future<bool> loadLatestBackupIfAvailable() async {
    final latest = await getLatestBackupName();
    if (latest != null) {
      return await restoreFromCrashRecoveryBackup(latest);
    }
    return false;
  }

  /// Automatically snapshots survey state to local disk every 30s
  Future<bool> saveCrashRecoveryBackup() async {
    if (!engine.hasActiveBuilding) return false;
    try {
      final file = await _getBackupFile(engine.currentBuilding);
      if (file == null) return false;

      final snapshot = {
        'version': '1.0',
        'savedAtMs': DateTime.now().millisecondsSinceEpoch,
        'building': engine.currentBuilding,
        'currentFloor': engine.currentFloor,
        'graph': engine.exportGraphJson(),
        'stepLogs': engine.stepLogs.map((s) => s.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(snapshot), flush: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving crash recovery backup: $e');
      }
      return false;
    }
  }

  /// Check if a crash recovery backup exists for this building
  Future<bool> hasCrashRecoveryBackup(String buildingName) async {
    try {
      final file = await _getBackupFile(buildingName);
      if (file == null) return false;
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Restores in-memory survey state from disk backup
  Future<bool> restoreFromCrashRecoveryBackup(String buildingName) async {
    try {
      final file = await _getBackupFile(buildingName);
      if (file == null || !await file.exists()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['building'] == buildingName && data['stepLogs'] is List) {
        final stepList = (data['stepLogs'] as List)
            .map((s) => StepLogRecord.fromJson(s as Map<String, dynamic>))
            .toList();

        // Restore into engine
        engine.stepLogs.clear();
        engine.stepLogs.addAll(stepList);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore crash recovery backup: $e');
      }
      return false;
    }
  }

  /// Removes backup file after clean survey finalization or export
  Future<void> clearCrashRecoveryBackup(String buildingName) async {
    try {
      final file = await _getBackupFile(buildingName);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
