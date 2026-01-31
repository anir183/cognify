import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Trust Score Meter - Circular progress indicator for certificate trust
class TrustScoreMeter extends StatelessWidget {
  final int score; // 0-100
  final double size;
  final bool showLabel;
  
  const TrustScoreMeter({
    Key? key,
    required this.score,
    this.size = 120,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0, 100);
    final color = _getScoreColor(clampedScore);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(size, size),
                painter: TrustScoreBackgroundPainter(),
              ),
              
              // Progress arc
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: clampedScore / 100),
                builder: (context, value, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: TrustScoreProgressPainter(
                      progress: value,
                      color: color,
                    ),
                  );
                },
              ),
              
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    tween: IntTween(begin: 0, end: clampedScore),
                    builder: (context, value, child) {
                      return Text(
                        '$value',
                        style: TextStyle(
                          color: color,
                          fontSize: size * 0.3,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Trust Score',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: size * 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (showLabel) ...[
          const SizedBox(height: 12),
          
          // Trust level label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              _getTrustLevel(clampedScore),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFFBBF24); // Yellow
    if (score >= 40) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  String _getTrustLevel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Low';
  }
}

/// Background painter for trust score meter
class TrustScoreBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Progress painter for trust score meter
class TrustScoreProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  TrustScoreProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Gradient paint
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: [
        color,
        color.withOpacity(0.6),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2;

    // Draw glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // Draw progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TrustScoreProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
