# EWUNav Surveyor — Industry-Standard Upgrade Plan

> **Codebase**: 21 Dart files · 6,406 lines · Flutter 3.x / Dart 3.13  
> **Benchmarks**: OGC IMDF 1.0 · Apple Indoor Survey · ISO 16739 (IFC) · ISO 18305 · IndoorGML 2.0  
> **Current Score**: **38 / 100** feature completeness vs. industry standard

---

## Executive Summary

EWUNav Surveyor has a **solid architectural foundation** — multi-building/floor SLAM engine, Weinberg PDR step detection, complementary compass fusion, Wi-Fi fingerprinting, loop closure optimization, area zone polygons, and a responsive surveyor UI. However, compared to industry-grade indoor mapping platforms (Mappedin, IndoorAtlas, MazeMap), it has **critical gaps** in calibration, data modeling (IMDF compliance), export formats, quality assurance, and accessibility.

This plan upgrades EWUNav from a functional prototype to a **professional-grade indoor surveyor tool** across 7 phases, 42 tasks, targeting **92+ / 100** industry alignment.

---

## Gap Analysis Summary

| Domain | Current State | Industry Standard | Gap Severity |
|:---|:---|:---|:---:|
| **PDR Calibration** | Fixed 0.75m stride, no calibration wizard | Weinberg K-factor calibrated per-user, 10m known-distance walk | 🔴 Critical |
| **Heading Estimation** | Complementary filter (mag + gyro), Manhattan snapping only | EKF/Madgwick AHRS, QSMF anomaly detection, building axis alignment | 🟡 Major |
| **Data Model** | 5 custom tables (rooms, edges, fingerprints, steps, zones) | IMDF 16 feature types with UUIDs, GeoJSON geometry, referential integrity | 🔴 Critical |
| **Room Categories** | 11 types (classroom → deadEnd) | IMDF: 40+ unit categories + opening types + amenity categories + fixtures | 🟡 Major |
| **Corridor Model** | No width, no surface, no slope, no pass count | Width, slope, surface type, accessibility tags, multi-pass centerline | 🔴 Critical |
| **Openings (Doors)** | Door side recorded (left/right/straight), no door type | IMDF Opening: door type, access control, accessibility, coincident geometry | 🟡 Major |
| **Stride Calibration** | None — hardcoded 0.75m | Per-user calibration wizard, Weinberg K-factor fitting | 🔴 Critical |
| **Wi-Fi Scanning** | Single scan per step, no throttle handling, no RSSI filtering | Gaussian/median filtering, scan queuing, density validation, BLE support | 🟡 Major |
| **Loop Closure** | Linear drift distribution | Pose-graph SLAM with Levenberg-Marquardt, particle filter map matching | 🟢 Adequate* |
| **Export Formats** | JSON graph dump + raw SQLite | IMDF ZIP archive, GeoJSON, IndoorGML, SVG blueprint, IFC4 | 🔴 Critical |
| **Coverage Quality** | None | Heatmaps, AP density metrics, CEP50/CE95, ISO 18305 verification | 🔴 Critical |
| **Accessibility/ADA** | `isAccessible` boolean only | Ramp slope, door width, surface type, wheelchair routing, tactile paving | 🟡 Major |
| **Test Coverage** | 2 widget tests (< 5% coverage) | Unit tests for all algorithms, integration tests, >80% line coverage | 🔴 Critical |
| **Architecture** | 1,969-line monolith screen widget | Modular dialogs, repository pattern, proper error boundaries | 🟡 Major |
| **Barometric Floor Detection** | Not implemented | Pressure-based automatic floor transitions | 🟡 Major |
| **Multi-Pass Averaging** | Not implemented | Corridor centerline snapping from multiple walks | 🟡 Major |
| **Building Azimuth** | `setBuildingBaseline()` exists but no UI | Compass rose UI for surveyor to set true north alignment | 🟢 Minor |

> \* Loop closure is adequate for current scope but should evolve to pose-graph SLAM for scale.

---

## Phase 1 — Calibration & Sensor Foundation

**Goal**: Transform raw sensor input into calibrated, trustworthy measurements  
**Effort**: ~1,200 lines | 3-4 days  
**Impact**: 🔴→🟢 Fixes the #1 accuracy bottleneck

### Task 1.1 — Stride Calibration Wizard
**File**: [`pdr_engine.dart`](file:///f:/EWUNav/ewunav/lib/services/pdr_engine.dart)  
**New File**: `lib/views/surveyor/dialogs/stride_calibration_dialog.dart`

- Add `calibrateStrideFromKnownDistance(double knownDistanceM, int measuredSteps)` to PdrEngine
- Compute personal K-factor: $K = \frac{d_{known}}{N_{steps} \cdot (a_{max} - a_{min})^{0.25}}$
- Persist K-factor in SharedPreferences per building
- Create a guided calibration UI: "Walk exactly 10 meters along a known corridor, then tap Done"
- Display calibrated stride vs default with accuracy percentage
- Add "Re-calibrate" option in the app bar overflow menu

### Task 1.2 — Building Azimuth Alignment UI
**File**: [`compass_fusion_service.dart`](file:///f:/EWUNav/ewunav/lib/services/compass_fusion_service.dart)  
**New File**: `lib/views/surveyor/dialogs/azimuth_alignment_dialog.dart`

- Create compass rose widget showing live magnetometer heading
- Surveyor aligns phone along building's longest wall and taps "Set Baseline"
- Persist baseline per building in SQLite
- Show current baseline offset in the HUD overlay
- Add Manhattan axis overlay on canvas (ghost lines at 0°/90°/180°/270° relative to baseline)

### Task 1.3 — Barometric Floor Detection
**New File**: `lib/services/barometer_service.dart`  
**Dependency**: Add `environment_sensors: ^0.3.0` to pubspec.yaml

- Subscribe to barometric pressure stream
- Establish reference pressure at Ground Floor during calibration
- Detect floor transitions when pressure delta exceeds threshold ($\Delta P \approx 0.36$ hPa per 3m floor)
- Auto-suggest floor switch when barometric transition is detected
- Fall back gracefully on devices without barometer sensor

### Task 1.4 — Configurable Pixels-Per-Meter & Canvas Origin
**Files**: [`slam_surveyor_engine.dart`](file:///f:/EWUNav/ewunav/lib/services/slam_surveyor_engine.dart), [`surveyor_canvas.dart`](file:///f:/EWUNav/ewunav/lib/views/surveyor/surveyor_canvas.dart)

- Extract `pixelsPerMeter = 28.0` and origin `(400, 400)` into a `SurveyConfig` class
- Allow per-building scale factor (useful for zoomed-in small rooms vs large campus halls)
- Store config in building metadata

---

## Phase 2 — IMDF-Compliant Data Model

**Goal**: Restructure internal data to map 1:1 onto OGC IMDF 1.0 feature types  
**Effort**: ~1,800 lines | 4-5 days  
**Impact**: 🔴→🟢 Enables Apple Indoor Maps submission and GIS interoperability

### Task 2.1 — Expand RoomCategory → IMDF Unit Categories
**File**: [`room_node.dart`](file:///f:/EWUNav/ewunav/lib/models/room_node.dart)

Current 11 categories → Expand to match IMDF `unit.category` values:

```dart
enum UnitCategory {
  room, corridor, walkway, openSpace, elevator, escalator, 
  stairs, ramp, restroom, restroomMale, restroomFemale,
  serverRoom, parking, lobby, atrium, office, classroom,
  laboratory, library, auditorium, cafeteria, prayerRoom,
  storage, mechanical, electrical, utility, unspecified
}
```

- Maintain backward compatibility by mapping old enum values → new values
- Update DB migration (version 3) with ALTER TABLE for category column

### Task 2.2 — Opening Model (Doors, Gates, Turnstiles)
**New File**: `lib/models/opening.dart`

```dart
enum DoorType { hinged, sliding, revolving, folding, automatic, open, none }
enum AccessControl { open, keyCard, keyPad, biometric, manual, none }

class Opening {
  final String id;        // UUIDv4
  final String levelId;   // foreign key → floor
  final String unitIdA;   // unit on side A
  final String unitIdB;   // unit on side B  
  final DoorType doorType;
  final AccessControl accessControl;
  final double clearWidthMeters;    // ADA: min 0.815m
  final double thresholdHeightMm;   // ADA: max 13mm
  final bool isAccessible;
  final bool isEmergencyExit;
}
```

- Add `openings` table to DbService (version 3 migration)
- When surveyor tags a door, prompt for door type and width
- Render openings as gap lines on canvas between adjacent units

### Task 2.3 — Amenity Model (Points of Interest)
**New File**: `lib/models/amenity.dart`

```dart
enum AmenityCategory {
  restroom, waterFountain, fireExtinguisher, aed, atm,
  vendingMachine, informationDesk, securityDesk, 
  chargingStation, prayerRoom, firstAid, parking,
  bicycleParking, elevator, escalator, unspecified
}

class Amenity {
  final String id;
  final String levelId;
  final String unitId;
  final AmenityCategory category;
  final String? name;
  final double x, y;
  final bool isAccessible;
}
```

- Add amenity quick-tag chips in ThumbActionBar (fire extinguisher, water fountain, AED)
- Render as distinct icons on canvas

### Task 2.4 — Corridor Edge Enrichment
**File**: [`corridor_edge.dart`](file:///f:/EWUNav/ewunav/lib/models/corridor_edge.dart)

Add industry-standard fields:

```dart
class CorridorEdge {
  // ... existing fields ...
  final double? widthMeters;           // Corridor width
  final double? runningSlopePercent;    // Ramp grade (ADA: max 8.33%)
  final double? crossSlopePercent;     // ADA: max 2.08%
  final String? surfaceType;           // concrete, tile, carpet, gravel
  final bool hasTactilePaving;         // Accessibility: tactile guides
  final int passCount;                 // Multi-pass averaging count
}
```

- Add "Estimate Width" button: surveyor walks perpendicular and taps to measure
- DB migration adds new columns with NULL defaults for backward compatibility

### Task 2.5 — Venue / Building / Level IMDF Hierarchy
**New File**: `lib/models/imdf_venue.dart`

Model the IMDF spatial hierarchy:
- **Venue** → contains Buildings → contains Levels → contains Units
- Add `ordinal` (integer floor ordering) to floor metadata
- Add building address (ISO 3166 country code, locality, postal code)
- Required for IMDF ZIP archive export

---

## Phase 3 — Survey Quality & Multi-Pass

**Goal**: Professional survey verification and accuracy improvement  
**Effort**: ~1,400 lines | 3-4 days  
**Impact**: 🔴→🟢 Establishes measurable quality guarantees

### Task 3.1 — Multi-Pass Corridor Centerline
**File**: [`slam_surveyor_engine.dart`](file:///f:/EWUNav/ewunav/lib/services/slam_surveyor_engine.dart)

- Track `passCount` per edge segment
- When walking the same corridor again (within 1.5m of existing edge), average coordinates:
  $$x_{avg} = \frac{x_{existing} \cdot (n-1) + x_{new}}{n}$$
- Visual indicator: edge color shifts from red (1 pass) → yellow (2) → green (3+)
- Display pass count in edge tooltip

### Task 3.2 — Coverage Heatmap Overlay
**New File**: `lib/views/surveyor/overlays/coverage_heatmap.dart`

- Divide floor into 2m × 2m grid cells
- Color cells by survey quality metric:
  - **Red** (0): Unsurveyed — no step logs or Wi-Fi scans
  - **Orange** (1): Low — visited once, < 3 APs detected
  - **Yellow** (2-3): Medium — 2-3 passes, 3-5 APs
  - **Green** (4+): High — 4+ passes, 5+ APs with RSSI ≥ -75 dBm
- Toggle heatmap layer on/off via canvas overlay button
- Calculate and display coverage percentage: $C_{cov} = \frac{\text{green + yellow cells}}{\text{total navigable cells}} \times 100\%$

### Task 3.3 — Wi-Fi RSSI Gaussian Filtering
**File**: [`wifi_scanner_service.dart`](file:///f:/EWUNav/ewunav/lib/services/wifi_scanner_service.dart)

- Collect multiple RSSI readings per AP per location (minimum 3 scans over 5 seconds)
- Apply Gaussian filter: discard readings outside $[\mu - 1.5\sigma, \mu + 1.5\sigma]$
- Compute filtered mean RSSI per AP
- Discard APs with RSSI < -85 dBm (noise floor)
- Add scan queue system: if OS throttles scan, queue for next available slot
- Show AP count and average RSSI quality in HUD

### Task 3.4 — Ground Control Point (GCP) Waypoints
**New File**: `lib/models/ground_control_point.dart`

- Let surveyor drop named GCP markers at known physical locations (entrance doors, column labels, fire exits)
- GCPs serve as drift anchors during loop closure
- When revisiting a GCP, auto-trigger loop closure with known ground-truth coordinates
- Minimum 3 GCPs per floor for affine transformation to WGS84

### Task 3.5 — Survey Session Management
**New File**: `lib/models/survey_session.dart`

- Track individual survey sessions with start/end timestamps, operator name, device info
- Allow multiple sessions per floor (morning pass + afternoon pass)
- Merge sessions with weighted averaging
- Export session metadata in IMDF `manifest.json`

---

## Phase 4 — Professional Export Pipeline

**Goal**: Output data in every format the industry expects  
**Effort**: ~2,000 lines | 4-5 days  
**Impact**: 🔴→🟢 Enables GIS, BIM, and Apple Maps pipeline integration

### Task 4.1 — IMDF ZIP Archive Export
**New File**: `lib/services/export/imdf_exporter.dart`

Generate OGC-compliant IMDF archive:
```
ewunav_survey.imdf/
├── manifest.json          (version, created, language, generated_by)
├── venue.geojson           (campus polygon boundary)
├── building.geojson        (building metadata, null geometry)
├── footprint.geojson       (building ground outline)
├── level.geojson           (floor polygons with ordinal)
├── unit.geojson            (rooms, corridors, zones → polygons)
├── opening.geojson         (doors → LineString on unit boundaries)
├── amenity.geojson         (POIs → Points)
├── anchor.geojson          (spatial anchors → Points)
├── occupant.geojson        (faculty occupants → null geometry)
├── address.geojson         (postal address → null geometry)
└── relationship.geojson    (vertical connections, parent-child)
```

- Convert local Cartesian (px) → WGS84 via GeospatialService projection
- Generate RFC 4122 UUIDv4 for all feature IDs
- Enforce RFC 7946 winding order (CCW exterior, CW interior)
- 7 decimal places coordinate precision
- Validate referential integrity before export

### Task 4.2 — GeoJSON Feature Collection Export
**New File**: `lib/services/export/geojson_exporter.dart`

- Export individual floor plans as RFC 7946 GeoJSON FeatureCollections
- Include semantic properties (category, name, accessibility, notes)
- Support both local coordinate (meters) and projected WGS84 output
- Optional TopoJSON variant for shared-boundary compression

### Task 4.3 — SVG Blueprint Export
**New File**: `lib/services/export/svg_exporter.dart`

- Render floor plan as geo-referenced SVG with semantic CSS classes
- Layer hierarchy: `.unit-room`, `.unit-corridor`, `.opening-door`, `.amenity-*`, `.zone-*`
- Include `viewBox` scaled to meters
- Embed metadata: building name, floor, survey date, operator
- Support high-resolution export for architectural printing

### Task 4.4 — IndoorGML Routing Graph Export
**New File**: `lib/services/export/indoor_gml_exporter.dart`

- Export Primal-Dual space topology
- Primal: CellSpace (rooms as 3D volumes)
- Dual: State (nodes) + Transition (edges) for pathfinding
- Include edge weights (distance, time, accessibility cost)
- Multi-layered: pedestrian layer + wheelchair-accessible layer

### Task 4.5 — Export Manager UI
**New File**: `lib/views/surveyor/dialogs/export_dialog.dart`

- Unified export dialog with format selector (IMDF, GeoJSON, SVG, IndoorGML, Raw JSON)
- Preview summary statistics before export
- Export quality gate: warn if coverage < 80% or IMDF validation fails
- Share via system share sheet or save to device storage

---

## Phase 5 — Accessibility & ADA Compliance

**Goal**: Capture data required for wheelchair-accessible routing  
**Effort**: ~800 lines | 2 days  
**Impact**: 🟡→🟢 Required for public venue compliance

### Task 5.1 — Ramp & Slope Recording
- When surveyor identifies a ramp, prompt for:
  - Running slope (%) — ADA max 8.33%
  - Cross slope (%) — ADA max 2.08%  
  - Clear width (meters) — ADA min 0.915m
  - Landing present (bool)
- Auto-flag violations (red warning badge on canvas)
- Store in CorridorEdge enrichment fields

### Task 5.2 — Door Accessibility Audit
- During door tagging, capture:
  - Clear opening width (meters) — ADA min 0.815m
  - Threshold height (mm) — ADA max 13mm beveled
  - Operation type (manual push/pull, lever, automatic push-button, proximity sensor)
- Flag non-compliant openings with warning icon

### Task 5.3 — Accessible Route Layer
- Generate a separate routing graph with only wheelchair-accessible edges
- Filter out: stairs without adjacent elevator, non-accessible doors, edges with slope > 8.33%
- Visual toggle on canvas: "Show Accessible Routes Only"
- Export as separate IndoorGML layer

---

## Phase 6 — Architecture & Testing

**Goal**: Production-grade code quality and maintainability  
**Effort**: ~1,500 lines | 3-4 days  
**Impact**: 🔴→🟢 Essential for long-term maintenance

### Task 6.1 — Decompose SurveyorScreen (1,969 lines → ~6 files)
**Current**: [`surveyor_screen.dart`](file:///f:/EWUNav/ewunav/lib/views/surveyor/surveyor_screen.dart) — monolith

Extract into:
```
lib/views/surveyor/
├── surveyor_screen.dart          (~400 lines — scaffold, layout, state)
├── dialogs/
│   ├── add_building_dialog.dart  (~120 lines)
│   ├── complete_floor_dialog.dart (~100 lines)
│   ├── enclose_zone_dialog.dart  (~150 lines)
│   ├── export_dialog.dart        (~200 lines)
│   └── schema_viewer.dart        (~200 lines)
├── overlays/
│   ├── telemetry_hud.dart        (~80 lines)
│   ├── coverage_heatmap.dart     (~150 lines)
│   └── loop_candidate_banner.dart (~60 lines)
└── workbench_dock.dart           (~200 lines)
```

### Task 6.2 — Repository Pattern for Data Access
**New File**: `lib/repositories/survey_repository.dart`

- Wrap DbService + in-memory SlamSurveyorEngine state into a single transactional source of truth
- All mutations go through repository (prevents in-memory ↔ SQLite divergence)
- Add retry logic and error boundaries for SQLite operations

### Task 6.3 — Comprehensive Unit Test Suite
**Target**: >80% line coverage on all service and model files

| Test File | Covers | Key Test Cases |
|:---|:---|:---|
| `test/pdr_engine_test.dart` | PdrEngine | Weinberg stride calc, IIR filter, peak/valley detection, refractory timing |
| `test/compass_fusion_test.dart` | CompassFusionService | Magnetic anomaly rejection, Manhattan snapping, gyro integration |
| `test/geospatial_test.dart` | GeospatialService | Cartesian→WGS84 projection math, elevation table lookup |
| `test/loop_closure_test.dart` | LoopClosureOptimizer | Drift distribution across vertices, rejection of >15m error |
| `test/db_service_test.dart` | DbService | Schema creation, CRUD operations, cascade deletes, JSON export |
| `test/area_zone_test.dart` | AreaZone | Shoelace formula (square, triangle, irregular polygon) |
| `test/imdf_export_test.dart` | IMDF Exporter | UUID generation, GeoJSON compliance, winding order, referential integrity |
| `test/corridor_edge_test.dart` | CorridorEdge | Serialization with new accessibility fields, backward compat |
| `test/opening_test.dart` | Opening model | Door type enum, ADA compliance flags |

### Task 6.4 — Error Boundaries & Offline Resilience
- Wrap all sensor subscriptions in try-catch with graceful degradation
- Add offline indicator when GPS or Wi-Fi is unavailable
- Queue failed DB writes for retry
- Add crash recovery: auto-save survey state every 30 seconds to a backup JSON file

---

## Phase 7 — Advanced Features & Polish

**Goal**: Differentiate from competitors with unique capabilities  
**Effort**: ~1,000 lines | 2-3 days  
**Impact**: 🟢 Nice-to-have professional polish

### Task 7.1 — Free-Angle Heading (45° Diagonal Support)
- Add option to disable Manhattan snapping for non-orthogonal buildings
- Support 45° snap grid for diagonal corridors (hexagonal atriums, V-shaped wings)
- User toggle: "Manhattan Grid" vs "Free Heading" vs "45° Grid"

### Task 7.2 — Corridor Width Measurement Tool
- "Measure Width" mode: surveyor walks perpendicular across corridor
- Count steps × calibrated stride = measured width
- Auto-assign width to nearest corridor edge
- Visual: render corridor as double-stroke proportional to width

### Task 7.3 — BLE Beacon Support
**Dependency**: Add `flutter_blue_plus: ^1.35.0` to pubspec.yaml

- Scan for iBeacon / Eddystone advertisements during survey
- Record UUID, Major, Minor, RSSI, TxPower per scan
- Store in `ble_fingerprints` table alongside Wi-Fi fingerprints
- Useful for venues with BLE infrastructure

### Task 7.4 — Photo Attachment for Rooms
**Dependency**: Add `image_picker: ^1.1.0` to pubspec.yaml

- Allow surveyor to attach photos to rooms, amenities, and notes
- Store photos in app documents directory with reference in DB
- Include photo paths in export data

### Task 7.5 — Survey Report Generation
**New File**: `lib/services/export/survey_report.dart`

- Generate human-readable PDF/HTML survey report containing:
  - Building metadata (name, address, operator, date)
  - Floor-by-floor statistics (rooms, corridors, zones, coverage %)
  - Quality metrics (AP density, pass count, drift rate)
  - Miniaturized floor plan SVGs
  - ADA compliance summary with violation list

---

## Implementation Priority Matrix

```
                    HIGH IMPACT
                        │
     ╔══════════════════╪══════════════════╗
     ║  Phase 1         │  Phase 2         ║
     ║  Calibration     │  IMDF Data Model ║
     ║  ⏱ 3-4 days      │  ⏱ 4-5 days      ║
     ║  DO FIRST         │  DO SECOND        ║
LOW ─╫──────────────────┼──────────────────╫─ HIGH
EFFORT║  Phase 5         │  Phase 4         ║  EFFORT
     ║  ADA Compliance  │  Export Pipeline  ║
     ║  ⏱ 2 days         │  ⏱ 4-5 days      ║
     ║  DO FOURTH        │  DO THIRD         ║
     ╚══════════════════╪══════════════════╝
                        │
                    LOW IMPACT
```

**Critical Path**: Phase 1 → Phase 2 → Phase 4 → Phase 3 → Phase 5 → Phase 6 → Phase 7

| Phase | Duration | Cumulative Score |
|:---|:---:|:---:|
| Current State | — | **38 / 100** |
| Phase 1: Calibration | 3-4 days | **48 / 100** |
| Phase 2: IMDF Data Model | 4-5 days | **60 / 100** |
| Phase 3: Quality & Multi-Pass | 3-4 days | **70 / 100** |
| Phase 4: Export Pipeline | 4-5 days | **80 / 100** |
| Phase 5: ADA Compliance | 2 days | **85 / 100** |
| Phase 6: Architecture & Testing | 3-4 days | **92 / 100** |
| Phase 7: Advanced Features | 2-3 days | **97 / 100** |
| **Total** | **~22-30 days** | **97 / 100** |

---

## New Dependencies Required

| Package | Version | Purpose | Phase |
|:---|:---|:---|:---:|
| `environment_sensors` | ^0.3.0 | Barometric pressure for floor detection | 1 |
| `shared_preferences` | ^2.3.0 | Persist calibration K-factor per building | 1 |
| `uuid` | ^4.5.1 | RFC 4122 UUIDv4 generation for IMDF | 2 |
| `archive` | ^4.0.4 | ZIP packaging for IMDF archive export | 4 |
| `flutter_blue_plus` | ^1.35.0 | BLE beacon scanning | 7 |
| `image_picker` | ^1.1.0 | Photo attachments for rooms | 7 |

---

## Database Migration Path

```
Version 1 → rooms, edges, wifi_fingerprints, step_logs
Version 2 → + area_zones (current)
Version 3 → + openings, amenities, ble_fingerprints,
             + ground_control_points, survey_sessions
             + ALTER corridor edges (width, slope, surface, tactile, passCount)
             + ALTER rooms (expanded category enum, door attributes)
             + ADD imdf_metadata table (venue, building, level hierarchy)
```

---

## Files Changed vs Created

### Modified Files (15):
- `pubspec.yaml` — new dependencies
- `lib/models/room_node.dart` — expanded categories, door attributes
- `lib/models/corridor_edge.dart` — width, slope, surface, accessibility enrichment
- `lib/models/area_zone.dart` — IMDF unit ID mapping
- `lib/services/pdr_engine.dart` — calibration method, K-factor persistence
- `lib/services/compass_fusion_service.dart` — enhanced anomaly detection
- `lib/services/wifi_scanner_service.dart` — RSSI filtering, scan queuing
- `lib/services/slam_surveyor_engine.dart` — multi-pass, GCP waypoints, session tracking
- `lib/services/db_service.dart` — version 3 migration, new tables
- `lib/services/geospatial_service.dart` — affine GCP transformation
- `lib/views/surveyor/surveyor_screen.dart` — decompose into modules
- `lib/views/surveyor/surveyor_canvas.dart` — heatmap layer, amenity icons, opening rendering
- `lib/views/surveyor/thumb_action_bar.dart` — new quick-tag buttons
- `test/widget_test.dart` — expand coverage
- `test/area_zone_test.dart` — additional polygon test cases

### New Files (25+):
- `lib/models/opening.dart`
- `lib/models/amenity.dart`
- `lib/models/ground_control_point.dart`
- `lib/models/survey_session.dart`
- `lib/models/imdf_venue.dart`
- `lib/services/barometer_service.dart`
- `lib/services/export/imdf_exporter.dart`
- `lib/services/export/geojson_exporter.dart`
- `lib/services/export/svg_exporter.dart`
- `lib/services/export/indoor_gml_exporter.dart`
- `lib/services/export/survey_report.dart`
- `lib/repositories/survey_repository.dart`
- `lib/views/surveyor/dialogs/stride_calibration_dialog.dart`
- `lib/views/surveyor/dialogs/azimuth_alignment_dialog.dart`
- `lib/views/surveyor/dialogs/add_building_dialog.dart`
- `lib/views/surveyor/dialogs/complete_floor_dialog.dart`
- `lib/views/surveyor/dialogs/enclose_zone_dialog.dart`
- `lib/views/surveyor/dialogs/export_dialog.dart`
- `lib/views/surveyor/dialogs/schema_viewer.dart`
- `lib/views/surveyor/overlays/telemetry_hud.dart`
- `lib/views/surveyor/overlays/coverage_heatmap.dart`
- `lib/views/surveyor/overlays/loop_candidate_banner.dart`
- `lib/views/surveyor/workbench_dock.dart`
- `test/pdr_engine_test.dart`
- `test/compass_fusion_test.dart`
- `test/geospatial_test.dart`
- `test/loop_closure_test.dart`
- `test/db_service_test.dart`
- `test/imdf_export_test.dart`
- `test/corridor_edge_test.dart`
- `test/opening_test.dart`

---

> [!IMPORTANT]
> This plan requires your approval before any code changes begin. Review each phase and let me know if you want to adjust priorities, skip any phase, or add additional requirements.
