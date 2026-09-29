# EWUNav Audit Remediation Checklist

> Generated: 2026-09-29 | Source: 6-agent comprehensive audit
> Updated: 2026-09-29 18:24 — Phases 1-4 COMPLETE

---

## Phase 1: Stop the Bleeding (Critical Crashes) ✅ COMPLETE
- [x] **C-01** Fix `db_service.dart` — bump version to 3, align `onCreate` with full schema (openings, amenities, ADA edge columns)
- [x] **C-13** Fix `db_service.dart` — move `area_zones` CREATE TABLE out of the catch block, add debugPrint to empty catches
- [x] **C-03** Fix `export_manager.dart` — use `double.tryParse()`, handle portal/door edge ID formats gracefully
- [x] **C-04** Fix `coverage_heatmap.dart` — use `:` delimiter for negative-safe grid keys, fix deprecated `withOpacity`

## Phase 2: ADA Safety (Wheelchair Routing) ✅ COMPLETE
- [x] **C-05** Create `lib/constants/ada_constants.dart` — centralized ADA thresholds with validation helpers
- [x] **C-07** Fix `routing_engine.dart` — use `.abs()` for slope checks (negative slopes bypass)
- [x] **H-01** Fix `routing_engine.dart` — add cross slope check (`crossSlopePercent > 2.08%`)
- [x] **C-05** Fix `routing_engine.dart` — add corridor width check (`widthMeters < 0.915m`)
- [x] **H-02** Fix `routing_engine.dart` — verify destination node `isAccessible` during Dijkstra
- [x] **C-02** Fix `routing_engine.dart` — synthesize waypoint stubs for corridor step nodes (null crash fix)

## Phase 3: Data Integrity ✅ COMPLETE
- [x] **C-12** Fix inverted `isAccessible` defaults in `Opening.fromJson`, `Amenity.fromJson`, `CorridorEdge.fromJson`
- [x] **H-04** Include all ADA attributes (`widthMeters`, slopes, surface, tactile) in GeoJSON export
- [x] Type safety: added `as String` casts to `Opening.fromJson` and `Amenity.fromJson`

## Phase 4: Memory & Lifecycle ✅ COMPLETE
- [x] **H-05** Add `dispose()` to `SlamSurveyorEngine` — cancel step stream subscription, cascade dispose
- [x] **H-06** Dispose all 8 `TextEditingController`s in `FacultyRoomModal`
- [x] **H-07** Dispose 2 controllers in `PortalTransferModal`

## Phase 5: Dependency & Import Cleanup ✅ COMPLETE
- [x] Remove unused `flutter_compass` from `pubspec.yaml`
- [x] Remove unused `environment_sensors` from `pubspec.yaml`
- [x] Remove orphaned `barometer_service.dart` (was only consumer of environment_sensors)
- [x] Remove redundant `test` package from `dev_dependencies`
- [x] Migrate all 5 test files from `package:test` to `package:flutter_test`

## Phase 6: Remaining Items (Not Yet Started)
- [ ] **C-06** Connect `Opening` to routing graph — embed door width/threshold on door-type edges
- [ ] **C-08** Add ADA fields to `FacultyRoomModal` (door width, threshold height)
- [ ] **C-09** Add `List<Opening> openings` and `List<Amenity> amenities` to `BuildingSurveyData`
- [ ] **C-11** Fix door edges silently dropped from GeoJSON (room ID format has only 3 parts)
- [ ] **C-14** Add `BuildingSurveyData` persistence — DB table + `toJson`/`fromJson`
- [ ] **H-15** Fix `CorridorEdge` asymmetric `from`/`to` vs `fromId`/`toId` keys
- [ ] **M-15** Fix `RoomNode.fromJson` crash on SQLite integer booleans
- [ ] **M-04** Wire `_photoPath` saving in corridor, door, and room dialogs
- [ ] **H-18** Fix `DbService` initialization race with `Completer<Database>`
- [ ] Extract `BuildingSurveyData`, `SurveyCorridorPoint`, `AreaLoopCandidate` to `lib/models/`
- [ ] Introduce `SurveyRepository` pattern — remove direct `DbService` from views
- [ ] Rewrite `ewunav/README.md` — project overview, setup, architecture, build commands
- [ ] Create `CHANGELOG.md` — document DB schema versions and feature milestones
- [ ] Add dartdoc to core public APIs
- [ ] Fix misleading `LoopClosureOptimizer` "Gauss-Newton" comment

---

**Progress:** 22 / 37 items complete ✅  
**Static Analysis:** 0 errors, 0 warnings, 4 info (deprecated API style only)
