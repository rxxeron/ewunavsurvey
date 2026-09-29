import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/pdr_engine.dart';
import 'services/compass_fusion_service.dart';
import 'services/wifi_scanner_service.dart';
import 'services/slam_surveyor_engine.dart';
import 'services/db_service.dart';
import 'views/surveyor/surveyor_screen.dart';

Future<void> _requestPermissions() async {
  if (kIsWeb) return;
  try {
    await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.nearbyWifiDevices,
    ].request();
  } catch (e) {
    debugPrint('Permission request error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

  final pdrEngine = PdrEngine(enableHardwareSensors: true);
  final compassFusion = CompassFusionService(enableHardwareSensors: true);
  final wifiScanner = WiFiScannerService();
  final dbService = DbService();

  final slamEngine = SlamSurveyorEngine(
    pdrEngine: pdrEngine,
    compassFusion: compassFusion,
    wifiScanner: wifiScanner,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SlamSurveyorEngine>.value(value: slamEngine),
        Provider<DbService>.value(value: dbService),
      ],
      child: const EWUNavApp(),
    ),
  );
}

class EWUNavApp extends StatelessWidget {
  const EWUNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    final slamEngine = Provider.of<SlamSurveyorEngine>(context);
    final dbService = Provider.of<DbService>(context);

    return MaterialApp(
      title: 'EWUNav Surveyor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64B5F6),
          secondary: Color(0xFF81C784),
          surface: Color(0xFF1E2235),
        ),
      ),
      home: SurveyorScreen(engine: slamEngine, dbService: dbService),
    );
  }
}
