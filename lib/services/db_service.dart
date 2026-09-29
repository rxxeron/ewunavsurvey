import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/room_node.dart';
import '../models/corridor_edge.dart';
import '../models/wifi_fingerprint.dart';
import '../models/step_log_record.dart';
import '../models/faculty_member.dart';
import '../models/area_zone.dart';
import '../models/opening.dart';

class DbService {
  static Database? _database;
  static Completer<Database?>? _initCompleter;

  Future<Database?> get database {
    if (_database != null) return Future.value(_database);
    if (kIsWeb) return Future.value(null);
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<Database?>();
    _initDatabase().then((db) {
      _database = db;
      _initCompleter!.complete(db);
    }).catchError((e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
    });
    
    return _initCompleter!.future;
  }

  Future<Database?> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'ewunav_survey.db');
      return await openDatabase(
        path,
        version: 4,
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
              floorHeightMeters REAL,
              photoPath TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE edges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fromId TEXT,
              toId TEXT,
              distanceMeters REAL,
              type TEXT,
              isAccessible INTEGER,
              widthMeters REAL,
              runningSlopePercent REAL,
              crossSlopePercent REAL,
              surfaceType TEXT,
              hasTactilePaving INTEGER DEFAULT 0,
              passCount INTEGER DEFAULT 1,
              photoPath TEXT
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
            CREATE TABLE area_zones (
              id TEXT PRIMARY KEY,
              floor TEXT,
              name TEXT,
              category TEXT,
              points TEXT,
              areaSqMeters REAL,
              colorHex TEXT,
              notes TEXT,
              boundaryNodeIds TEXT
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

          await db.execute('''
            CREATE TABLE IF NOT EXISTS openings(
              id TEXT PRIMARY KEY,
              levelId TEXT,
              unitIdA TEXT,
              unitIdB TEXT,
              doorType TEXT,
              accessControl TEXT,
              clearWidthMeters REAL,
              thresholdHeightMm REAL,
              isAccessible INTEGER,
              isEmergencyExit INTEGER,
              photoPath TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS amenities(
              id TEXT PRIMARY KEY,
              levelId TEXT,
              unitId TEXT,
              category TEXT,
              name TEXT,
              x REAL,
              y REAL,
              isAccessible INTEGER
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 4) {
            try {
              await db.execute('ALTER TABLE rooms ADD COLUMN photoPath TEXT');
              await db.execute('ALTER TABLE edges ADD COLUMN photoPath TEXT');
              await db.execute('ALTER TABLE openings ADD COLUMN photoPath TEXT');
            } catch (e) {
              debugPrint('DB photoPath migration notice: $e');
            }
          }
          if (oldVersion < 3) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS openings(
            id TEXT PRIMARY KEY,
            levelId TEXT,
            unitIdA TEXT,
            unitIdB TEXT,
            doorType TEXT,
            accessControl TEXT,
            clearWidthMeters REAL,
            thresholdHeightMm REAL,
            isAccessible INTEGER,
            isEmergencyExit INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS amenities(
            id TEXT PRIMARY KEY,
            levelId TEXT,
            unitId TEXT,
            category TEXT,
            name TEXT,
            x REAL,
            y REAL,
            isAccessible INTEGER
          )
        ''');
        
        try {
          await db.execute('ALTER TABLE edges ADD COLUMN widthMeters REAL');
          await db.execute('ALTER TABLE edges ADD COLUMN runningSlopePercent REAL');
          await db.execute('ALTER TABLE edges ADD COLUMN crossSlopePercent REAL');
          await db.execute('ALTER TABLE edges ADD COLUMN surfaceType TEXT');
          await db.execute('ALTER TABLE edges ADD COLUMN hasTactilePaving INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE edges ADD COLUMN passCount INTEGER DEFAULT 1');
        } catch (e) {
          debugPrint('DB edges migration notice: $e');
        }
      }
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

            try {
              await db.execute('''
                CREATE TABLE IF NOT EXISTS area_zones (
                  id TEXT PRIMARY KEY,
                  floor TEXT,
                  name TEXT,
                  category TEXT,
                  points TEXT,
                  areaSqMeters REAL,
                  colorHex TEXT,
                  notes TEXT,
                  boundaryNodeIds TEXT
                )
              ''');
            } catch (e) {
              debugPrint('DB zone migration notice: $e');
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
        'photoPath': room.photoPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveEdge(CorridorEdge edge) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'edges',
      {
        'fromId': edge.fromId,
        'toId': edge.toId,
        'distanceMeters': edge.distanceMeters,
        'type': edge.type,
        'isAccessible': edge.isAccessible ? 1 : 0,
        'widthMeters': edge.widthMeters,
        'runningSlopePercent': edge.runningSlopePercent,
        'crossSlopePercent': edge.crossSlopePercent,
        'surfaceType': edge.surfaceType,
        'hasTactilePaving': edge.hasTactilePaving ? 1 : 0,
        'passCount': edge.passCount,
        'photoPath': edge.photoPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveCorridorEdge(CorridorEdge edge) => saveEdge(edge);

  Future<void> saveOpening(Opening opening) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'openings',
      {
        'id': opening.id,
        'levelId': opening.levelId,
        'unitIdA': opening.unitIdA,
        'unitIdB': opening.unitIdB,
        'doorType': opening.doorType.name,
        'accessControl': opening.accessControl.name,
        'clearWidthMeters': opening.clearWidthMeters,
        'thresholdHeightMm': opening.thresholdHeightMm,
        'isAccessible': opening.isAccessible ? 1 : 0,
        'isEmergencyExit': opening.isEmergencyExit ? 1 : 0,
        'photoPath': opening.photoPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  
  Future<void> saveZone(AreaZone zone) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'area_zones',
      {
        'id': zone.id,
        'floor': zone.floor,
        'name': zone.name,
        'category': zone.category.name,
        'points': jsonEncode(zone.points.map((p) => p.toJson()).toList()),
        'areaSqMeters': zone.areaSqMeters,
        'colorHex': zone.colorHex,
        'notes': zone.notes,
        'boundaryNodeIds': jsonEncode(zone.boundaryNodeIds),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteZone(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('area_zones', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AreaZone>> getZonesForFloor(String floor) async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('area_zones', where: 'floor = ?', whereArgs: [floor]);
    return rows.map<AreaZone>((r) => _parseZoneRow(r)).toList();
  }

  Future<List<AreaZone>> getAllZones() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('area_zones');
    return rows.map<AreaZone>((r) => _parseZoneRow(r)).toList();
  }

  AreaZone _parseZoneRow(Map<String, dynamic> r) {
    List<ZonePoint> points = [];
    final pointsRaw = r['points'] as String?;
    if (pointsRaw != null && pointsRaw.isNotEmpty) {
      try {
        final list = jsonDecode(pointsRaw) as List<dynamic>;
        points = list.map((p) => ZonePoint.fromJson(p as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    List<String> nodeIds = [];
    final nodeIdsRaw = r['boundaryNodeIds'] as String?;
    if (nodeIdsRaw != null && nodeIdsRaw.isNotEmpty) {
      try {
        final list = jsonDecode(nodeIdsRaw) as List<dynamic>;
        nodeIds = list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return AreaZone(
      id: r['id'] as String,
      floor: r['floor'] as String,
      name: r['name'] as String,
      category: ZoneCategory.values.firstWhere(
        (c) => c.name == (r['category'] as String?),
        orElse: () => ZoneCategory.openSpace,
      ),
      points: points,
      areaSqMeters: (r['areaSqMeters'] as num?)?.toDouble() ?? 0.0,
      colorHex: r['colorHex'] as String?,
      notes: r['notes'] as String?,
      boundaryNodeIds: nodeIds,
    );
  }

  Future<void> clearAllSurveyData() async {
    final db = await database;
    if (db == null) return;
    await db.delete('rooms');
    await db.delete('edges');
    await db.delete('wifi_fingerprints');
    await db.delete('step_logs');
    await db.delete('area_zones');
  }

  Future<void> deleteFloorData(String floor) async {
    final db = await database;
    if (db == null) return;
    
    final roomRows = await db.query('rooms', columns: ['id'], where: 'floor = ?', whereArgs: [floor]);
    final roomIds = roomRows.map((r) => r['id'] as String).toList();
    
    await db.delete('rooms', where: 'floor = ?', whereArgs: [floor]);
    for (final id in roomIds) {
      await db.delete('edges', where: 'fromId = ? OR toId = ?', whereArgs: [id, id]);
    }
    await db.delete('wifi_fingerprints', where: 'floor = ?', whereArgs: [floor]);
    await db.delete('step_logs', where: 'floor = ?', whereArgs: [floor]);
    await db.delete('area_zones', where: 'floor = ?', whereArgs: [floor]);
  }

  Future<List<RoomNode>> getAllRooms() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('rooms');
    return rows.map<RoomNode>((r) {
      final facultyRaw = r['facultyMembers'] as String?;
      List<FacultyMember> faculty = [];
      if (facultyRaw != null && facultyRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(facultyRaw) as List<dynamic>;
          faculty = decoded.map((f) => FacultyMember.fromJson(f as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      return RoomNode(
        id: r['id'] as String,
        roomNumber: r['roomNumber'] as String?,
        name: r['name'] as String,
        floor: r['floor'] as String,
        category: RoomCategory.values.firstWhere(
          (c) => c.name == (r['category'] as String?),
          orElse: () => RoomCategory.classroom,
        ),
        department: r['department'] as String? ?? 'General',
        x: (r['x'] as num).toDouble(),
        y: (r['y'] as num).toDouble(),
        doorSide: r['doorSide'] as String? ?? 'left',
        studentCapacity: (r['studentCapacity'] as num?)?.toInt() ?? 40,
        isAccessible: (r['isAccessible'] as int?) == 1,
        facultyMembers: faculty,
        notes: r['notes'] as String?,
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        altitudeMeters: (r['altitudeMeters'] as num?)?.toDouble(),
        floorHeightMeters: (r['floorHeightMeters'] as num?)?.toDouble(),
        photoPath: r['photoPath'] as String?,
      );
    }).toList();
  }

  Future<List<CorridorEdge>> getAllEdges() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('edges');
    return rows.map<CorridorEdge>((r) => CorridorEdge.fromJson(r)).toList();
  }

  Future<List<StepLogRecord>> getAllStepLogs() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('step_logs', orderBy: 'stepIndex ASC');
    return rows.map<StepLogRecord>((r) {
      final wifiRaw = r['wifiSignals'] as String?;
      List<dynamic> parsedSignals = [];
      if (wifiRaw != null && wifiRaw.isNotEmpty) {
        try {
          parsedSignals = jsonDecode(wifiRaw) as List<dynamic>;
        } catch (_) {}
      }
      return StepLogRecord(
        stepIndex: (r['stepIndex'] as num).toInt(),
        timestampMs: (r['timestampMs'] as num).toInt(),
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
      final rawFps = await db.query('wifi_fingerprints');
      fps = rawFps.map((row) {
        final m = Map<String, dynamic>.from(row);
        if (m['accessPoints'] is String) {
          try {
            m['accessPoints'] = jsonDecode(m['accessPoints'] as String);
          } catch (_) {}
        }
        return m;
      }).toList();
    }

    final rawPayload = {
      'datasetType': 'EWUNav-Raw-Survey',
      'exportedAtMs': DateTime.now().millisecondsSinceEpoch,
      'totalSteps': steps.length,
      'steps': steps.map((s) => s.toJson()).toList(),
      'rawWifiFingerprints': fps,
      'areaZones': (await getAllZones()).map((z) => z.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(rawPayload);
  }
}
