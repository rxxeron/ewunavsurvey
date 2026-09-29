import 'package:ewunavsurvey/models/area_zone.dart';

class AreaLoopCandidate {
  final List<ZonePoint> points;
  final double areaSqMeters;
  final int startIndex;
  final int endIndex;

  AreaLoopCandidate({
    required this.points,
    required this.areaSqMeters,
    required this.startIndex,
    required this.endIndex,
  });
}
