# Changelog

## [1.0.0] - 2026-09-29

### Added
- Core SLAM surveyor engine with PDR step detection
- Complementary compass/gyroscope heading fusion
- Multi-floor building survey management
- Dijkstra-based indoor routing with ADA wheelchair accessibility
- Centralized ADA constants (corridor width, slopes, door clearance, thresholds)
- Wi-Fi fingerprint collection and beacon signal modeling
- BLE fingerprint data model
- Loop closure detection and linear drift correction
- Polygon area zone detection (Shoelace formula)
- Geospatial coordinate projection (Canvas → WGS84)
- SQLite persistence with schema migration (v1 → v2 → v3)
- IMDF archive export (venue, level GeoJSON)
- GeoJSON corridor graph export with full ADA attributes
- Photo attachment service for door/corridor/room auditing
- Markdown survey audit report generator
- Coverage heatmap visualization
- Faculty room management with member directory
- Stride calibration dialog
- Corridor width measurement tool (PDR-based)

### Database Schema
- **v1**: rooms, edges, wifi_fingerprints, step_logs
- **v2**: Added geospatial coordinates to rooms and step_logs
- **v3**: Added openings table, amenities table, ADA columns on edges (widthMeters, runningSlopePercent, crossSlopePercent, surfaceType, hasTactilePaving, passCount), area_zones table
