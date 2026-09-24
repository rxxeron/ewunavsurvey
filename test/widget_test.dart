import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ewunavsurvey/main.dart';
import 'package:ewunavsurvey/services/pdr_engine.dart';
import 'package:ewunavsurvey/services/compass_fusion_service.dart';
import 'package:ewunavsurvey/services/wifi_scanner_service.dart';
import 'package:ewunavsurvey/services/slam_surveyor_engine.dart';
import 'package:ewunavsurvey/services/db_service.dart';

void main() {
  testWidgets('EWUNavApp boots into blank first boot waiting for user to add building', (WidgetTester tester) async {
    final slamEngine = SlamSurveyorEngine(
      pdrEngine: PdrEngine(),
      compassFusion: CompassFusionService(),
      wifiScanner: WiFiScannerService(),
    );
    final dbService = DbService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SlamSurveyorEngine>.value(value: slamEngine),
          Provider<DbService>.value(value: dbService),
        ],
        child: const EWUNavApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Building Survey Active'), findsOneWidget);
    expect(find.text('+ Create New Building Survey'), findsOneWidget);
  });

  testWidgets('Creating building and adding floors dynamically updates surveyor interface', (WidgetTester tester) async {
    final slamEngine = SlamSurveyorEngine(
      pdrEngine: PdrEngine(),
      compassFusion: CompassFusionService(),
      wifiScanner: WiFiScannerService(),
    );
    final dbService = DbService();

    // User creates first building with starting floor
    slamEngine.createBuilding(
      name: 'Main Building & Block-C',
      initialFloor: 'Ground Floor',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SlamSurveyorEngine>.value(value: slamEngine),
          Provider<DbService>.value(value: dbService),
        ],
        child: const EWUNavApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Main Building & Block-C'), findsOneWidget);
    expect(find.text('Ground Floor'), findsWidgets);
    expect(find.text('Add Floor'), findsOneWidget);

    // User adds 1st Floor one-by-one
    slamEngine.addCustomFloor('1st Floor');
    await tester.pumpAndSettle();

    expect(find.text('1st Floor'), findsWidgets);
  });
}
