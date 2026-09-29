# Changelog

All notable changes to the EWUNav Surveyor project will be documented in this file.

## [2.0.0] - 2026-09-29
**The Industry Standards & Architecture Update**

### Added
- **OGC IMDF Architecture:** Data models completely overhauled to support OGC IMDF v1.0.0, expanding room categories to 27+ standardized units.
- **ADA Accessibility Compliance:** Introduced strict ADA variables into `CorridorEdge` and `Opening` (running slope, cross slope, clear width).
- **Wheelchair Routing:** Routing Engine now utilizes `VerticalPreference.wheelchairAccessible` to automatically bypass stairs, ledges, and slopes > 8.33%.
- **Export Pipeline:** New `ExportManager` allowing users to generate `GeoJSON` linestrings and IMDF `.zip` archives on-device with native sharing options.
- **Multi-Pass Snapping:** Paths surveyed within 1.5 meters of existing nodes now automatically snap to create unified centerlines and aggregate pass counts.
- **Coverage Heatmap:** 2x2m grid heatmap overlay added to the `SurveyorCanvas` to visualize mapping density.
- **Sensor Fusion:**
  - `BarometerService` added to detect physical floor transitions.
  - `StrideCalibrationDialog` introduced for dynamic Weinberg K-Factor step lengths.
  - `AzimuthAlignmentDialog` added to lock true north structural baselines.
  - Free-Angle, 45°, and 90° heading snap modes implemented.
- **Photo Attachments:** Added `image_picker` support to attach photos to rooms and corridors.
- **BLE Beacon Fingerprinting:** Integrated Bluetooth Low Energy support for RSSI/path loss localization alongside Wi-Fi.
- **Testing:** 18 new unit tests covering ADA routing, SLAM logic, IMDF serialization, and compass baseline math.

### Changed
- **Decomposition Refactor:** `surveyor_screen.dart` was reduced from a monolithic 1,968 lines down to ~488 lines by modularizing dialogs, overlays, and docks.
- **Database Schema v3 Migration:** Smoothly migrates existing v2 SQLite databases to include `openings`, `amenities`, `ble_fingerprints`, and ADA columns without data loss.
- **UI Architecture:** Extracted state persistence to a clean `SurveyRepository` pattern, drastically reducing race conditions and memory leaks.

### Fixed
- Fixed critical null-assertion crash in `routing_engine.dart` when interpolating step nodes.
- Fixed SQL execution crash inside `AreaZone` initialization.
- Reverted accidentally inverted `isAccessible` defaults in JSON serialization.
- Patched memory leaks by enforcing `dispose()` on all 10+ modal `TextEditingController` instances.
- Added throttle queue to `WiFiScannerService` to prevent Android 4-scans/2min Foreground limits.

## [1.0.0] - Initial Release
- Basic SLAM Engine (PDR + Compass).
- Wi-Fi Fingerprinting collection.
- Local SQLite database.
- Area Polygon Drawing.
