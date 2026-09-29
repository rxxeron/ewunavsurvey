# EWUNav Campus Surveyor — Comprehensive Project Audit Report

**Project:** `e:\EWUNav\ewunav` (`ewunavsurvey`)  
**Date:** 2026-09-29  
**Audit Team:** 6 autonomous agents auditing in parallel  
**Codebase:** 46 Dart files in `lib/`, 4 test files, ~8,500 LOC  

---

## Executive Health Dashboard

| Domain | Critical | High | Medium | Low | Score |
|:---|:---:|:---:|:---:|:---:|:---:|
| 🏗️ Architecture & Organization | 1 | 4 | 5 | 5 | ⚠️ **C+** |
| 🧪 Test Coverage | — | — | — | — | ❌ **D** (13 tests / 19 source files) |
| ♿ ADA Compliance Enforcement | 5 | 4 | 3 | 1 | ❌ **F** |
| 📦 Data Model & Serialization | 5 | 4 | 3 | 1 | ❌ **D-** |
| 🐛 Code Quality & Bugs | 4 | 6 | 5 | 3 | ❌ **D** |
| 📝 Documentation | — | — | — | — | ❌ **F** (<15% dartdoc) |
| **TOTALS** | **15** | **18** | **16** | **10** | |

> [!CAUTION]
> **15 critical issues** were found across the codebase. The most severe are a **SQLite schema mismatch** that crashes on clean installs, **routing engine null assertion crashes**, and **wheelchair routing that ignores corridor widths, door widths, and threshold heights entirely**.

---

## 🔴 CRITICAL FINDINGS (Must Fix — App Crashes or Safety Hazards)

### C-01: SQLite Database Schema Mismatch (Crash on Clean Install)
- **File:** [db_service.dart](file:///e:/EWUNav/ewunav/lib/services/db_service.dart#L28-L31)
- **Agent:** Architecture, Code Quality, Data Model (all three flagged independently)
- **Issue:** Database version is `2`, but `onCreate` omits the `openings` table, `amenities` table, and ADA columns on `edges` (`widthMeters`, `runningSlopePercent`, `crossSlopePercent`, `surfaceType`, `hasTactilePaving`). These exist only inside `if (oldVersion < 3)` in `onUpgrade`, which never runs on fresh installs.
- **Impact:** Any call to `saveOpening()` or `saveEdge()` with ADA properties crashes with `SqliteException: no such column`.
- **Fix:** Set `version: 3`, update `onCreate` to include all tables/columns, align `onUpgrade` for monotonic migrations 1→2→3.

### C-02: Routing Engine Null Assertion Crash on Multi-Step Routes
- **File:** [routing_engine.dart](file:///e:/EWUNav/ewunav/lib/services/routing_engine.dart#L134-L135)
- **Agent:** Code Quality
- **Issue:** `nodeMap` is built only from `engine.rooms` (RoomNode objects). Dijkstra path IDs include corridor step nodes (`node_Floor_X_Y`) which have no entry in `nodeMap`. `nodeMap[id]!` throws `Null check operator used on a null value`.
- **Impact:** Every route that traverses hallway steps crashes.
- **Fix:** Synthesize lightweight waypoint nodes for corridor step IDs, or store all nodes in `nodeMap`.

### C-03: GeoJSON Export Crash on Portal Edges
- **File:** [export_manager.dart](file:///e:/EWUNav/ewunav/lib/services/export_manager.dart#L82-L85)
- **Agent:** Code Quality, Data Model
- **Issue:** `edge.fromId.split('_')[2]` is parsed as `double`. For vertical portal edges (`portal_Stairs_stair_Ground_Floor`), part `[2]` is `'stair'`. `double.parse('stair')` throws `FormatException`.
- **Impact:** Any export containing portal edges crashes the entire export pipeline.
- **Fix:** Validate with `double.tryParse()` and look up coordinates from the node map.

### C-04: Coverage Heatmap Crash on Negative Coordinates
- **File:** [coverage_heatmap.dart](file:///e:/EWUNav/ewunav/lib/views/surveyor/overlays/coverage_heatmap.dart#L36-L38)
- **Agent:** Code Quality
- **Issue:** Grid key `'${gridX}_${gridY}'` with negatives produces `'-1_-2'`. Splitting by `'_'` yields `['', '1', '', '2']`. `int.parse("")` crashes the `CustomPainter`.
- **Impact:** Canvas crashes when survey extends beyond origin.
- **Fix:** Use a non-hyphen delimiter (`:`) or structured keys.

### C-05: Wheelchair Routing Ignores Corridor Width
- **File:** [routing_engine.dart](file:///e:/EWUNav/ewunav/lib/services/routing_engine.dart#L99-L102)
- **Agent:** ADA Compliance
- **Issue:** `edge.widthMeters` is **never checked**. A 0.5m impassable corridor is included in wheelchair routes.
- **Impact:** Wheelchair users could be routed through physically impassable corridors.
- **Fix:** Add `if (edge.widthMeters != null && edge.widthMeters! < 0.915) continue;` to the wheelchair accessibility filter.

### C-06: Wheelchair Routing Ignores Door Width & Thresholds
- **File:** [routing_engine.dart](file:///e:/EWUNav/ewunav/lib/services/routing_engine.dart#L99-L102)
- **Agent:** ADA Compliance
- **Issue:** `Opening` model is completely disconnected from the routing graph. Door clear widths (<0.815m) and threshold heights (>13mm) are never evaluated during route calculation.
- **Impact:** Wheelchair users could be routed through doorways they cannot physically pass.
- **Fix:** Embed `doorWidthMeters` and `thresholdHeightMm` on door-type `CorridorEdge`s and filter in Dijkstra.

### C-07: Negative Slopes Bypass ADA Check
- **File:** [routing_engine.dart](file:///e:/EWUNav/ewunav/lib/services/routing_engine.dart#L101)
- **Agent:** ADA Compliance
- **Issue:** `edge.runningSlopePercent! > 8.33` only blocks positive slopes. A descending -10% slope passes the check (`-10 > 8.33` = false).
- **Fix:** Use `.abs() > 8.33`.

### C-08: Primary Door Creation Bypasses All ADA Auditing
- **File:** [faculty_room_modal.dart](file:///e:/EWUNav/ewunav/lib/views/surveyor/faculty_room_modal.dart)
- **Agent:** ADA Compliance
- **Issue:** `FacultyRoomModal` (triggered by "Door LEFT"/"Door RIGHT") collects zero ADA data — no width, no threshold, no accessibility toggle. All doors default to `isAccessible = true`.
- **Impact:** 100% of doors mapped via the primary surveying workflow bypass ADA auditing.

### C-09: Missing `openings` & `amenities` Collections in BuildingSurveyData
- **File:** [slam_surveyor_engine.dart](file:///e:/EWUNav/ewunav/lib/services/slam_surveyor_engine.dart#L44-L81)
- **Agent:** Data Model
- **Issue:** `BuildingSurveyData` has no `List<Opening>` or `List<Amenity>`. Models exist, DB tables exist (when schema is correct), but the active survey never holds them.
- **Impact:** Openings/amenities saved to SQLite are orphaned from the survey lifecycle and export pipeline.

### C-10: 6 of 8 Required IMDF Feature Types Missing
- **File:** [export_manager.dart](file:///e:/EWUNav/ewunav/lib/services/export_manager.dart#L12-L69)
- **Agent:** Data Model
- **Issue:** IMDF export only generates `venue.geojson` and `level.geojson`. Missing: `building.geojson`, `unit.geojson`, `opening.geojson`, `amenity.geojson`, `anchor.geojson`, `occupant.geojson`, and `manifest.json`.

### C-11: All Door Edges Silently Dropped from GeoJSON Export
- **File:** [export_manager.dart](file:///e:/EWUNav/ewunav/lib/services/export_manager.dart#L79-L86)
- **Agent:** Data Model
- **Issue:** Door edge `toId: 'room_<timestamp>_<x>'` has only 3 parts. The `toParts.length >= 4` check fails, silently dropping every room-to-corridor connection.

### C-12: Inverted Default Accessibility in 3 Model `fromJson` Methods
- **File:** [opening.dart](file:///e:/EWUNav/ewunav/lib/models/opening.dart#L51), [amenity.dart](file:///e:/EWUNav/ewunav/lib/models/amenity.dart#L48), [corridor_edge.dart](file:///e:/EWUNav/ewunav/lib/models/corridor_edge.dart#L47)
- **Agent:** Data Model
- **Issue:** Constructor defaults `isAccessible = true`, but `fromJson` evaluates `json['isAccessible'] == true` which returns `false` when the key is null/missing. Deserializing an entity with omitted accessibility flips it from accessible to inaccessible.

### C-13: `area_zones` Table Never Created on DB Upgrade
- **File:** [db_service.dart](file:///e:/EWUNav/ewunav/lib/services/db_service.dart#L160-L181)
- **Agent:** Code Quality
- **Issue:** `CREATE TABLE IF NOT EXISTS area_zones` is nested inside the `catch` block of `ALTER TABLE rooms`. If the ALTER succeeds, the area_zones table is never created.

### C-14: No BuildingSurveyData Persistence (Data Loss on Restart)
- **File:** [slam_surveyor_engine.dart](file:///e:/EWUNav/ewunav/lib/services/slam_surveyor_engine.dart#L44-L81)
- **Agent:** Data Model
- **Issue:** `BuildingSurveyData` has no `toJson()`/`fromJson()` and no database table. When the app restarts, `_buildingSurveys` is lost from memory.

### C-15: GPS Override Destroys Indoor Dead-Reckoning Coordinates
- **File:** [geospatial_service.dart](file:///e:/EWUNav/ewunav/lib/services/geospatial_service.dart#L151-L162)
- **Agent:** Code Quality
- **Issue:** If GPS accuracy ≤ 8.0m, `calculatePosition` returns the device's static GPS lat/lng for every step/room, overriding all canvas-based dead-reckoning.

---

## 🟠 HIGH SEVERITY FINDINGS

| ID | Domain | File | Issue Summary |
|:---|:---|:---|:---|
| H-01 | ADA | `routing_engine.dart` | Cross slope (`crossSlopePercent > 2.08%`) never checked |
| H-02 | ADA | `routing_engine.dart` | `RoomNode.isAccessible` never verified during Dijkstra |
| H-03 | ADA | `corridor_properties_dialog.dart` | Dialog only updates the last 0.75m edge segment, not the full corridor run |
| H-04 | ADA | `export_manager.dart` | GeoJSON export drops `widthMeters`, slopes, surface type, tactile paving |
| H-05 | Code | `slam_surveyor_engine.dart` | Stream subscription to `pdrEngine.stepStream` never cancelled; no `dispose()` |
| H-06 | Code | `faculty_room_modal.dart` | 8 undisposed `TextEditingController` instances leak memory |
| H-07 | Code | `portal_transfer_modal.dart` | 2 undisposed controllers |
| H-08 | Code | `loop_closure_optimizer.dart` | Loop closure corrections never persisted to SQLite |
| H-09 | Code | `pdr_engine.dart` | Weinberg dynamic stride permanently bypassed (dead code) |
| H-10 | Code | `db_service.dart` | 6+ empty `catch (_)` blocks silently swallow errors |
| H-11 | Data | `venue.geojson` | Uses `Point` geometry (IMDF requires `Polygon`/`MultiPolygon`) |
| H-12 | Data | `level.geojson` | Invalid empty `coordinates: []` (RFC 7946 violation) |
| H-13 | Data | `opening.dart`, `amenity.dart` | Untyped dynamic property access without `as String` casts |
| H-14 | Data | `wifi_fingerprint.dart` | `accessPoints` list throws `TypeError` if null |
| H-15 | Data | `corridor_edge.dart` | Asymmetric `from`/`to` vs `fromId`/`toId` keys |
| H-16 | Arch | `slam_surveyor_engine.dart` | 1,080 lines — monolithic God Object |
| H-17 | Arch | `surveyor_screen.dart` | 697 lines — views directly invoke SQLite CRUD |
| H-18 | Code | `db_service.dart` | Database initialization race condition with concurrent access |

---

## 🟡 MEDIUM SEVERITY FINDINGS

| ID | Domain | Issue Summary |
|:---|:---|:---|
| M-01 | ADA | ADA constants duplicated as magic numbers (no centralized `ada_constants.dart`) |
| M-02 | ADA | `DoorType.revolving` selectable without ADA violation warning |
| M-03 | ADA | IMDF export omits `footpath.geojson` and `opening.geojson` |
| M-04 | Code | Dead photo data: `_photoPath` ignored in corridor, door, and room dialogs |
| M-05 | Code | `NavigationScreen` fully built but never routed/reachable from app |
| M-06 | Code | `Amenity` class + enum defined but never used anywhere |
| M-07 | Code | `ThumbActionBar.onWalkStraight` callback never invoked |
| M-08 | Code | `SlamSurveyorEngine._showHeatmap` duplicates canvas-local state |
| M-09 | Code | Async Wi-Fi scan race: undo before scan completes corrupts state |
| M-10 | Code | `CompassFusionService.getSnappedDiagonalHeading()` never called |
| M-11 | Arch | 5 domain models embedded inside service files (not in `models/`) |
| M-12 | Arch | `pubspec.yaml` — `flutter_compass` and `environment_sensors` unused |
| M-13 | Arch | Inconsistent import style (relative vs `package:ewunavsurvey/`) |
| M-14 | Data | Scale mismatch between engine runtime and export `pixelsPerMeter` |
| M-15 | Data | `RoomNode.fromJson` crashes on SQLite integer booleans |
| M-16 | Docs | `LoopClosureOptimizer` doc claims "Gauss-Newton" but implements linear weighting |

---

## 🧪 Test Coverage Analysis

### Current State: 13 Tests Across 4 Files

```
test/
├── widget_test.dart        (2 tests — basic UI smoke)
├── pdr_test.dart            (2 tests — basic step cycle)
├── area_zone_test.dart      (5 tests — polygon math, JSON)
└── compass_fusion_test.dart (4 tests — heading snapping)
```

### Coverage Matrix

| Source File | Tests | Pure Dart? | Priority |
|:---|:---:|:---:|:---:|
| `slam_surveyor_engine.dart` | 0 direct | ✅ Yes | **Critical** |
| `loop_closure_optimizer.dart` | 0 | ✅ Yes | **Critical** |
| `db_service.dart` | 0 | Conditional (`sqflite_ffi`) | **Critical** |
| `geospatial_service.dart` | 0 | ✅ Yes | **Critical** |
| `routing_engine.dart` | 1 (existing) | ✅ Yes | **Critical** |
| `pdr_engine.dart` | 2 (weak assertions) | ✅ Yes | **Critical** |
| `compass_fusion_service.dart` | 0 service | ✅ Yes | **High** |
| `wifi_scanner_service.dart` | 0 | ✅ Yes (sim mode) | **High** |
| `corridor_edge.dart` | 0 | ✅ Yes | **High** |
| `room_node.dart` | 0 | ✅ Yes | **High** |
| `step_log_record.dart` | 0 | ✅ Yes | **High** |
| `wifi_fingerprint.dart` | 0 | ✅ Yes | **High** |
| `export_manager.dart` | 0 | Conditional | **Medium** |
| `survey_report_generator.dart` | 0 | ✅ Yes | **Medium** |
| `opening.dart` | 0 | ✅ Yes | **Medium** |
| `amenity.dart` | 0 | ✅ Yes | **Medium** |
| `faculty_member.dart` | 0 | ✅ Yes | **Low** |
| `survey_config.dart` | 0 | ✅ Yes | **Low** |

### Test Quality Issues
- **`pdr_test.dart`**: Weak assertion `greaterThanOrEqualTo(1)` when 3 steps simulated — a broken detector dropping 2/3 steps still passes
- **Missing negative tests**: No tests for empty inputs, null values, boundary conditions, refractory periods, or error states
- **No folder hierarchy**: All tests in root `test/` instead of mirroring `lib/` structure

---

## 📝 Documentation Status

| Area | Status | Detail |
|:---|:---:|:---|
| `ewunav/README.md` | ❌ Boilerplate | Default Flutter template — zero project info |
| Root `README.md` | ⚠️ Partial | Covers web tools only, omits Flutter app entirely |
| `CHANGELOG.md` | ❌ Missing | Does not exist |
| `docs/` directory | ❌ Missing | Does not exist |
| Dartdoc coverage | ❌ <15% | Only `HeadingCalculator` is fully documented |
| DB schema migrations | ❌ Undocumented | 3 versions exist with zero migration notes |
| API contracts | ❌ Missing | No input/output/error docs on any service |
| Misleading comments | ⚠️ Found | `LoopClosureOptimizer` claims Gauss-Newton; `PdrEngine` claims dynamic Weinberg (permanently bypassed) |

---

## 🏗️ Architecture Summary

### File Size Violations (>500 lines)

| File | Lines | Issue |
|:---|:---:|:---|
| `slam_surveyor_engine.dart` | **1,080** | God Object — survey lifecycle, PDR, loops, persistence, portals |
| `surveyor_screen.dart` | **697** | UI + direct DB calls + 14 dialog launchers |
| `surveyor_canvas.dart` | **595** | Viewport + 360-line monolithic CustomPainter |
| `db_service.dart` | **542** | 7 entity types in one flat class |

### Unused Dependencies
- `flutter_compass: ^0.8.1` — never imported (redundant with `sensors_plus`)
- `environment_sensors: ^0.3.0` — never imported
- `test: ^1.31.1` (dev) — redundant with `flutter_test`

### Naming Conventions: ✅ 100% Compliant
- All 46 files: `snake_case.dart` ✅
- All classes/enums: `PascalCase` ✅
- All variables: `camelCase` ✅

---

## 🎯 Prioritized Remediation Roadmap

### Phase 1: Stop the Bleeding (Critical Crashes)
1. Fix `db_service.dart` — bump to version 3, align `onCreate` with full schema, fix `area_zones` catch-block nesting
2. Fix `routing_engine.dart` — synthesize waypoint nodes for corridor steps to prevent null assertion crashes
3. Fix `export_manager.dart` — use `double.tryParse()` and handle portal/door edge ID formats
4. Fix `coverage_heatmap.dart` — use `:` delimiter for negative-safe grid keys

### Phase 2: ADA Safety (Wheelchair Routing)
5. Create `lib/constants/ada_constants.dart` — centralize all ADA thresholds
6. Harden `RoutingEngine` wheelchair filter: check `widthMeters`, `crossSlopePercent`, use `.abs()` for slopes, verify `RoomNode.isAccessible`
7. Connect `Opening` model to routing graph (embed door attributes on door-type edges)
8. Add ADA fields to `FacultyRoomModal` (door width, threshold height)

### Phase 3: Data Integrity
9. Fix inverted `isAccessible` defaults in `Opening`, `Amenity`, `CorridorEdge` `fromJson`
10. Add `openings` and `amenities` lists to `BuildingSurveyData`
11. Include all ADA attributes in GeoJSON export properties
12. Add `BuildingSurveyData` persistence (DB table + `toJson`/`fromJson`)

### Phase 4: Memory & Lifecycle
13. Add `dispose()` to `SlamSurveyorEngine` — cancel step stream subscription
14. Dispose all `TextEditingController`s in `FacultyRoomModal` (8), `PortalTransferModal` (2)
15. Convert `DeadEndDialog` to `StatefulWidget` for controller lifecycle

### Phase 5: Test Coverage
16. Add pure Dart tests for `RoutingEngine` (corridor traversal, ADA filtering, disconnected graphs)
17. Add pure Dart tests for `LoopClosureOptimizer` (drift threshold, coordinate adjustment)
18. Add pure Dart tests for `GeospatialService` (Cartesian→geodetic projection math)
19. Strengthen `pdr_test.dart` assertions (exact step count, refractory rejection, boundary tests)
20. Add JSON round-trip tests for `CorridorEdge`, `RoomNode`, `StepLogRecord`, `Opening`

### Phase 6: Architecture & Docs
21. Extract `BuildingSurveyData`, `SurveyCorridorPoint`, `AreaLoopCandidate` to `lib/models/`
22. Introduce `SurveyRepository` pattern — eliminate direct `DbService` from views
23. Rewrite `ewunav/README.md` with project overview, setup, architecture, and build commands
24. Create `CHANGELOG.md` documenting DB schema versions and feature milestones
25. Remove unused dependencies (`flutter_compass`, `environment_sensors`)

---

> [!IMPORTANT]
> **Phases 1–2 are safety-critical** and should be addressed before any field deployment. The database crash (C-01) affects every new installation, and the wheelchair routing gaps (C-05 through C-08) could direct users into physically hazardous situations.
