class SurveyCorridorPoint {
  final double x;
  final double y;
  final String floor;
  final double headingDeg;

  SurveyCorridorPoint({
    required this.x,
    required this.y,
    required this.floor,
    required this.headingDeg,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'floor': floor,
        'headingDeg': headingDeg,
      };

  factory SurveyCorridorPoint.fromJson(Map<String, dynamic> json) => SurveyCorridorPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        floor: json['floor'] as String,
        headingDeg: (json['headingDeg'] as num).toDouble(),
      );
}
