import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';

/// Verification Badge - Shows VERIFIED or FAKE status
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  
  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: BadgePatternPainter(isVerified: isVerified),
            ),
          ),
          
          // Content
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.dangerous,
                color: Colors.white,
                size: size * 0.4,
              ),
              const SizedBox(width: 12),
              Text(
                isVerified ? 'VERIFIED' : 'FAKE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3))
        .then()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}

/// Pattern painter for verification badge
class BadgePatternPainter extends CustomPainter {
  final bool isVerified;

  BadgePatternPainter({required this.isVerified});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
