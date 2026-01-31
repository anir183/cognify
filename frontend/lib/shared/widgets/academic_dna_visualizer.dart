import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Academic DNA Visualizer - Futuristic DNA helix animation
/// Displays unique pattern based on Academic DNA hash
class AcademicDNAVisualizer extends StatefulWidget {
  final String academicDNA;
  final double size;
  final bool showLabel;
  
  const AcademicDNAVisualizer({
    Key? key,
    required this.academicDNA,
    this.size = 200,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<AcademicDNAVisualizer> createState() => _AcademicDNAVisualizerState();
}

class _AcademicDNAVisualizerState extends State<AcademicDNAVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Generate unique pattern from DNA hash
  List<int> _generatePattern() {
    if (widget.academicDNA.isEmpty) return List.generate(20, (i) => i % 256);
    
    final bytes = <int>[];
    for (int i = 0; i < widget.academicDNA.length && i < 40; i += 2) {
      final hex = widget.academicDNA.substring(i, math.min(i + 2, widget.academicDNA.length));
      bytes.add(int.tryParse(hex, radix: 16) ?? 0);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _generatePattern();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DNA Helix Visualization
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: DNAHelixPainter(
                  pattern: pattern,
                  animation: _controller.value,
                ),
              );
            },
          ),
        ),
        
        if (widget.showLabel) ...[
          const SizedBox(height: 16),
          
          // Label
          Text(
            'Cognify Academic DNA Identity',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // DNA Hash (truncated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Text(
              _formatDNA(widget.academicDNA),
              style: TextStyle(
                color: const Color(0xFF6366F1),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  String _formatDNA(String dna) {
    if (dna.length < 16) return dna;
    return '${dna.substring(0, 8)}...${dna.substring(dna.length - 8)}';
  }
}

/// Custom painter for DNA helix
class DNAHelixPainter extends CustomPainter {
  final List<int> pattern;
  final double animation;

  DNAHelixPainter({
    required this.pattern,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    // Draw DNA strands
    _drawStrand(canvas, center, radius, 0, const Color(0xFF00D9FF)); // Cyan
    _drawStrand(canvas, center, radius, math.pi, const Color(0xFF8B5CF6)); // Purple
    
    // Draw connecting base pairs
    _drawBasePairs(canvas, center, radius);
  }

  void _drawStrand(Canvas canvas, Offset center, double radius, double phaseOffset, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final points = <Offset>[];
    
    for (int i = 0; i < 50; i++) {
      final t = i / 50;
      final angle = (animation * 2 * math.pi + t * 4 * math.pi + phaseOffset);
      final y = center.dy - radius + (t * radius * 2);
      final x = center.dx + math.sin(angle) * radius * 0.6;
      
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
    }

    // Draw glow
    canvas.drawPath(path, glowPaint);
    
    // Draw strand
    canvas.drawPath(path, paint);
    
    // Draw nodes
    for (int i = 0; i < points.length; i += 5) {
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(points[i], 4, nodePaint);
    }
  }

  void _drawBasePairs(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 20; i++) {
      final t = i / 20;
      final angle = (animation * 2 * math.pi + t * 4 * math.pi);
      final y = center.dy - radius + (t * radius * 2);
      
      final x1 = center.dx + math.sin(angle) * radius * 0.6;
      final x2 = center.dx + math.sin(angle + math.pi) * radius * 0.6;
      
      // Use pattern to determine color
      final patternIndex = i % pattern.length;
      final colorValue = pattern[patternIndex];
      final hue = (colorValue / 255) * 360;
      
      paint.color = HSLColor.fromAHSL(0.6, hue, 0.8, 0.6).toColor();
      
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  @override
  bool shouldRepaint(DNAHelixPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.pattern != pattern;
  }
}
