# EWUNav Campus Surveyor

Autonomous Indoor Mapping & Building SLAM Engine for East West University campus.

## Overview
EWUNav Campus Surveyor is a mobile Flutter application designed for indoor surveying. It utilizes zero-hardware Pedestrian Dead Reckoning (PDR), compass fusion, Wi-Fi fingerprinting, and SLAM graph construction to create highly accurate indoor maps without requiring external hardware. It outputs IMDF and GeoJSON formats to enable accessible indoor navigation.

## Features
- Zero-hardware PDR (accelerometer-based step detection with Weinberg stride model)
- Complementary compass + gyroscope heading fusion with building-aligned snapping
- Real-time SLAM corridor graph construction with loop closure optimization
- Multi-floor vertical portal transitions (stairs, elevators)
- ADA wheelchair accessibility auditing and routing
- Wi-Fi fingerprint collection for positioning
- Polygon area zone detection (rooms, atriums, courtyards)
- IMDF & GeoJSON export for indoor mapping standards
- SQLite local persistence with schema migrations
- Photo attachment for door/corridor/room auditing

## Architecture
- `lib/models/`: Data models representing map entities, sensor data, and database schemas.
- `lib/services/`: Core business logic including SLAM algorithms, sensor processing, routing, and database operations.
- `lib/views/`: Flutter UI components for the surveyor interface, map visualization, and data entry.
- `lib/constants/`: Configuration and standardized values, including ADA (Americans with Disabilities Act) accessibility standards.

## Prerequisites
- Flutter SDK >= 3.13.4
- Android device with accelerometer, gyroscope, magnetometer sensors
- Wi-Fi scanning permissions (Android)
- Location permissions for GPS baseline anchoring

## Getting Started
```bash
cd ewunav
flutter pub get
flutter run
```

## Project Structure
- `lib/main.dart`: Application entry point.
- `lib/services/slam_surveyor_engine.dart`: Core SLAM engine implementation.
- `lib/services/pdr_processor.dart`: Pedestrian Dead Reckoning logic.
- `lib/services/database_helper.dart`: SQLite database management.
- `lib/views/surveyor_map_view.dart`: Main map UI.

## Database Schema
The app uses SQLite v3 for local persistence with the following key tables:
- `rooms`: Map landmarks and points of interest.
- `edges`: Graph connections (corridors, doors) between rooms/nodes.
- `wifi_fingerprints`: Collected Wi-Fi beacon signals for positioning.
- `step_logs`: Historical PDR step events for trajectory reconstruction.
- `area_zones`: Polygonal spatial regions (rooms, atriums).
- `openings`: Doors and transitional spaces.
- `amenities`: Map amenities (restrooms, water fountains).

## ADA Compliance
The project enforces accessibility standards through centralized `AdaConstants` (corridor widths, slopes, etc.) which influence map data collection and Dijkstra-based wheelchair-accessible routing.

## Testing
```bash
flutter test
```

## License
MIT
