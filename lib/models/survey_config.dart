class SurveyConfig {
  final double pixelsPerMeter;
  final double originX;
  final double originY;

  const SurveyConfig({
    this.pixelsPerMeter = 28.0,
    this.originX = 400.0,
    this.originY = 400.0,
  });

  Map<String, dynamic> toJson() => {
    'pixelsPerMeter': pixelsPerMeter,
    'originX': originX,
    'originY': originY,
  };

  factory SurveyConfig.fromJson(Map<String, dynamic> json) => SurveyConfig(
    pixelsPerMeter: (json['pixelsPerMeter'] as num?)?.toDouble() ?? 28.0,
    originX: (json['originX'] as num?)?.toDouble() ?? 400.0,
    originY: (json['originY'] as num?)?.toDouble() ?? 400.0,
  );
}
