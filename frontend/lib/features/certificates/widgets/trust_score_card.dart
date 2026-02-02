import 'package:flutter/material.dart';
import '../../../core/models/trust_analytics.dart';

class TrustScoreCard extends StatelessWidget {
  final TrustAnalytics analytics;

  const TrustScoreCard({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trust Score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Peer Benchmarking Badge
                    if (analytics.percentile > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: analytics.percentile > 80
                                ? const Color(0xFF10B981)
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          analytics.percentile > 90
                              ? 'Top ${(100 - analytics.percentile).toStringAsFixed(1)}% Globally'
                              : 'Better than ${analytics.percentile.toStringAsFixed(0)}% of peers',
                          style: TextStyle(
                            color: analytics.percentile > 80
                                ? const Color(0xFF10B981)
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                _buildTrustBadge(),
              ],
            ),
            SizedBox(height: 20),

            // Score Circle
            Center(
              child: _buildScoreCircle(),
            ),
            SizedBox(height: 24),

            // Breakdown
            Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            _buildBreakdownItem('Base Score', analytics.trustBreakdown.baseScore, 50),
            _buildBreakdownItem('Verification Bonus', analytics.trustBreakdown.verificationBonus, 20),
            _buildBreakdownItem('Longevity Bonus', analytics.trustBreakdown.longevityBonus, 10),
            _buildBreakdownItem('Issuer Reputation', analytics.trustBreakdown.issuerReputation, 15),
            _buildBreakdownItem('Geo Diversity', analytics.trustBreakdown.geoDiversity, 10),
            _buildBreakdownItem('Blockchain Proof', analytics.trustBreakdown.blockchainProof, 15),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(int.parse(analytics.trustLevelColor.replaceFirst('#', '0xff'))),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        analytics.trustLevel,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScoreCircle() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(int.parse(analytics.trustLevelColor.replaceFirst('#', '0xff'))).withOpacity(0.3),
            Color(int.parse(analytics.trustLevelColor.replaceFirst('#', '0xff'))),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${analytics.trustScore}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'out of 100',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int value, int maxValue) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '+$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: value > 0 ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(int.parse(analytics.trustLevelColor.replaceFirst('#', '0xff'))),
            ),
          ),
        ],
      ),
    );
  }
}
