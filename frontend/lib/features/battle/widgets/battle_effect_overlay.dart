import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class Projectile {
  final String id;
  final Offset startOffset;
  final Offset targetOffset; // Usually Boss center
  final Color color;
  final VoidCallback onHit;

  Projectile({
    required this.id,
    required this.startOffset,
    required this.targetOffset,
    this.color = Colors.cyanAccent,
    required this.onHit,
  });
}

class BattleEffectOverlay extends StatefulWidget {
  final List<Projectile> projectiles;

  const BattleEffectOverlay({super.key, required this.projectiles});

  @override
  State<BattleEffectOverlay> createState() => _BattleEffectOverlayState();
}

class _BattleEffectOverlayState extends State<BattleEffectOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.projectiles.map((p) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: 400.ms,
          curve: Curves.easeIn,
          onEnd: () => p.onHit(),
          builder: (context, value, child) {
            final currentX =
                Offset.lerp(p.startOffset, p.targetOffset, value)!.dx;
            final currentY =
                Offset.lerp(p.startOffset, p.targetOffset, value)!.dy;

            return Positioned(
              left: currentX,
              top: currentY,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.color.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
