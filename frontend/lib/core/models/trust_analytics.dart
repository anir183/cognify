class TrustAnalytics {
  final String certificateHash;
  final double trustScore;
  final String trustLevel;
  final double percentile;
  final TrustScoreBreakdown trustBreakdown;
  final List<TrustMetric> history;

  TrustAnalytics({
    this.certificateHash = '',
    required this.trustScore,
    required this.trustLevel,
    required this.percentile,
    required this.trustBreakdown,
    this.history = const [],
  });

  factory TrustAnalytics.fromJson(Map<String, dynamic> json) {
    return TrustAnalytics(
      certificateHash: json['certificateHash'] ?? '',
      trustScore: (json['trustScore'] as num?)?.toDouble() ?? 0.0,
      trustLevel: json['trustLevel'] ?? 'Unknown',
      percentile: (json['percentile'] as num?)?.toDouble() ?? 0.0,
      trustBreakdown: TrustScoreBreakdown.fromJson(json['trustBreakdown'] ?? {}),
      history: (json['history'] as List?)
              ?.map((e) => TrustMetric.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Helper to get trust level color
  String get trustLevelColor {
    switch (trustLevel) {
      case 'Excellent':
        return '#10b981'; // Green
      case 'High':
        return '#3b82f6'; // Blue
      case 'Moderate':
        return '#f59e0b'; // Orange
      default:
        return '#ef4444'; // Red
    }
  }
}

class TrustMetric {
  final DateTime date;
  final double score;

  TrustMetric({required this.date, required this.score});

  factory TrustMetric.fromJson(Map<String, dynamic> json) {
    return TrustMetric(
      date: DateTime.parse(json['date']),
      score: (json['score'] as num).toDouble(),
    );
  }
}

class TrustScoreBreakdown {
  final int baseScore;
  final int verificationBonus;
  final int longevityBonus;
  final int issuerReputation;
  final int geoDiversity;
  final int blockchainProof;
  final int totalScore;

  TrustScoreBreakdown({
    required this.baseScore,
    required this.verificationBonus,
    required this.longevityBonus,
    required this.issuerReputation,
    required this.geoDiversity,
    required this.blockchainProof,
    required this.totalScore,
  });

  factory TrustScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return TrustScoreBreakdown(
      baseScore: json['baseScore'] ?? 0,
      verificationBonus: json['verificationBonus'] ?? 0,
      longevityBonus: json['longevityBonus'] ?? 0,
      issuerReputation: json['issuerReputation'] ?? 0,
      geoDiversity: json['geoDiversity'] ?? 0,
      blockchainProof: json['blockchainProof'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseScore': baseScore,
      'verificationBonus': verificationBonus,
      'longevityBonus': longevityBonus,
      'issuerReputation': issuerReputation,
      'geoDiversity': geoDiversity,
      'blockchainProof': blockchainProof,
      'totalScore': totalScore,
    };
  }
}
