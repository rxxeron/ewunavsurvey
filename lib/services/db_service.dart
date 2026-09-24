import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../models/wifi_fingerprint.dart';
import '../models/step_log_record.dart';

class DbService {
  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    if (kIsWeb) return null; // Web fallback
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'ewunav_survey.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE rooms (
              id TEXT PRIMARY KEY,
              roomNumber TEXT,
              name TEXT,
              floor TEXT,
              category TEXT,
              department TEXT,
              x REAL,
              y REAL,
              doorSide TEXT,
              studentCapacity INTEGER,
              isAccessible INTEGER,
              facultyMembers TEXT,
              notes TEXT,
              latitude REAL,
              longitude REAL,
              altitudeMeters REAL,
              floorHeightMeters REAL
            )
          ''');

          await db.execute('''
            CREATE TABLE edges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fromId TEXT,
              toId TEXT,
              distanceMeters REAL,
              type TEXT,
              isAccessible INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE wifi_fingerprints (
              id TEXT PRIMARY KEY,
              floor TEXT,
              x REAL,
              y REAL,
              timestampMs INTEGER,
              accessPoints TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE step_logs (
              stepIndex INTEGER PRIMARY KEY,
              timestampMs INTEGER,
              floor TEXT,
              x REAL,
              y REAL,
              headingDeg REAL,
              strideMeters REAL,
              comment TEXT,
              latitude REAL,
              longitude REAL,
              altitudeMeters REAL,
              floorHeightMeters REAL,
              gpsAccuracyMeters REAL,
              wifiSignals TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute('ALTER TABLE rooms ADD COLUMN latitude REAL');
              await db.execute('ALTER TABLE rooms ADD COLUMN longitude REAL');
              await db.execute('ALTER TABLE rooms ADD COLUMN altitudeMeters REAL');
              await db.execute('ALTER TABLE rooms ADD COLUMN floorHeightMeters REAL');
              await db.execute('ALTER TABLE step_logs ADD COLUMN latitude REAL');
              await db.execute('ALTER TABLE step_logs ADD COLUMN longitude REAL');
              await db.execute('ALTER TABLE step_logs ADD COLUMN altitudeMeters REAL');
              await db.execute('ALTER TABLE step_logs ADD COLUMN floorHeightMeters REAL');
              await db.execute('ALTER TABLE step_logs ADD COLUMN gpsAccuracyMeters REAL');
            } catch (e) {
              debugPrint('DB migration notice: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Database init error: $e');
      return null;
    }
  }

  Future<String> getDatabaseFilePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'ewunav_survey.db');
  }

  Future<void> saveRoom(RoomNode room) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'rooms',
      {
        'id': room.id,
        'roomNumber': room.roomNumber,
        'name': room.name,
        'floor': room.floor,
        'category': room.category.name,
        'department': room.department,
        'x': room.x,
        'y': room.y,
        'doorSide': room.doorSide,
        'studentCapacity': room.studentCapacity,
        'isAccessible': room.isAccessible ? 1 : 0,
        'facultyMembers': jsonEncode(room.facultyMembers.map((f) => f.toJson()).toList()),
        'notes': room.notes,
        'latitude': room.latitude,
        'longitude': room.longitude,
        'altitudeMeters': room.altitudeMeters,
        'floorHeightMeters': room.floorHeightMeters,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveEdge(CorridorEdge edge) async {
    final db = await database;
    if (db == null) return;
    await db.insert('edges', {
      'fromId': edge.fromId,
      'toId': edge.toId,
      'distanceMeters': edge.distanceMeters,
      'type': edge.type,
      'isAccessible': edge.isAccessible ? 1 : 0,
    });
  }

  Future<void> saveFingerprint(WiFiFingerprint fp) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'wifi_fingerprints',
      {
        'id': fp.id,
        'floor': fp.floor,
        'x': fp.x,
        'y': fp.y,
        'timestampMs': fp.timestampMs,
        'accessPoints': jsonEncode(fp.accessPoints.map((a) => a.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveStepLog(StepLogRecord record) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'step_logs',
      {
        'stepIndex': record.stepIndex,
        'timestampMs': record.timestampMs,
        'floor': record.floor,
        'x': record.x,
        'y': record.y,
        'headingDeg': record.headingDeg,
        'strideMeters': record.strideMeters,
        'comment': record.comment,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'altitudeMeters': record.altitudeMeters,
        'floorHeightMeters': record.floorHeightMeters,
        'gpsAccuracyMeters': record.gpsAccuracyMeters,
        'wifiSignals': jsonEncode(record.wifiSignals.map((w) => w.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStepComment(int stepIndex, String comment) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'step_logs',
      {'comment': comment},
      where: 'stepIndex = ?',
      whereArgs: [stepIndex],
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
    await db.delete('edges', where: 'fromId = ? OR toId = ?', whereArgs: [id, id]);
  }

  Future<void> deleteStepLog(int stepIndex) async {
    final db = await database;
    if (db == null) return;
    await db.delete('step_logs', where: 'stepIndex = ?', whereArgs: [stepIndex]);
  }

  Future<void> clearAllSurveyData() async {
    final db = await database;
    if (db == null) return;
    await db.delete('rooms');
    await db.delete('edges');
    await db.delete('wifi_fingerprints');
    await db.delete('step_logs');
  }

  Future<List<StepLogRecord>> getAllStepLogs() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('step_logs', orderBy: 'stepIndex ASC');
    return rows.map((r) {
      final wifiRaw = r['wifiSignals'] as String?;
      List<dynamic> parsedSignals = [];
      if (wifiRaw != null && wifiRaw.isNotEmpty) {
        try {
          parsedSignals = jsonDecode(wifiRaw) as List<dynamic>;
        } catch (_) {}
      }
      return StepLogRecord(
        stepIndex: r['stepIndex'] as int,
        timestampMs: r['timestampMs'] as int,
        floor: r['floor'] as String,
        x: (r['x'] as num).toDouble(),
        y: (r['y'] as num).toDouble(),
        headingDeg: (r['headingDeg'] as num).toDouble(),
        strideMeters: (r['strideMeters'] as num).toDouble(),
        comment: r['comment'] as String?,
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        altitudeMeters: (r['altitudeMeters'] as num?)?.toDouble(),
        floorHeightMeters: (r['floorHeightMeters'] as num?)?.toDouble(),
        gpsAccuracyMeters: (r['gpsAccuracyMeters'] as num?)?.toDouble(),
        wifiSignals: parsedSignals
            .map((s) => EwuWiFiSignal.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }

  /// Exports raw sensor, step trajectory, comments, and Wi-Fi signatures
  Future<String> exportRawDataJson() async {
    final steps = await getAllStepLogs();
    final db = await database;
    List<Map<String, dynamic>> fps = [];
    if (db != null) {
      fps = await db.query('wifi_fingerprints');
    }

    final rawPayload = {
      'datasetType': 'EWUNav-Raw-Survey',
      'exportedAtMs': DateTime.now().millisecondsSinceEpoch,
      'totalSteps': steps.length,
      'steps': steps.map((s) => s.toJson()).toList(),
      'rawWifiFingerprints': fps,
    };
    return const JsonEncoder.withIndent('  ').convert(rawPayload);
  }
}
