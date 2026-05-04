class SegmentDetails {
  final int id;
  final int totalReports;
  final String maxSeverity;
  final DateTime lastReportDate;
  final double avgSeverityScore;

  SegmentDetails({
    required this.id,
    required this.totalReports,
    required this.maxSeverity,
    required this.lastReportDate,
    required this.avgSeverityScore,
  });

  factory SegmentDetails.fromJson(Map<String, dynamic> json) {
    return SegmentDetails(
      id: json['id'] as int,
      totalReports: json['total_reports'] as int,
      maxSeverity: json['max_severity'] as String,
      lastReportDate: DateTime.parse(json['last_report_date'] as String),
      avgSeverityScore: (json['avg_severity'] as num).toDouble(),
    );
  }
}
