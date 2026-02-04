import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CinematicBossVisuals extends StatelessWidget {
  final bool isPhase2;
  final bool isDead;
  final bool takeDamage;
  final bool isLowSpec;
  final Widget child;

  const CinematicBossVisuals({
    super.key,
    required this.child,
    this.isPhase2 = false,
    this.isDead = false,
    this.takeDamage = false,
    this.isLowSpec = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDead) {
      if (isLowSpec) {
         // Low Spec Death: Simple Fade
         return child.animate().fadeOut(duration: 500.ms).scale(end: const Offset(0.5, 0.5));
      }
      // High Spec Death: Shatter/Dissolve
      return child
          .animate()
          .shake(hz: 20, duration: 500.ms) // Violent shake
          .scale(end: const Offset(1.5, 1.5), duration: 500.ms) // Expand (explode)
          .fadeOut(delay: 300.ms, duration: 800.ms); // Fade out
    }

    Widget boss = child;

    // Phase 2 Aura
    if (isPhase2) {
      if (!isLowSpec) {
         boss = Stack(
           alignment: Alignment.center,
           children: [
              // Aura
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.redAccent.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1,1), end: const Offset(1.3, 1.3), duration: 1.seconds),
              boss,
           ],
         );
      } else {
         // Low Spec Phase 2: Just tint or minimal logic
         // No aura stack
      }
    }

    // Floating / Breathing (Continuous) - Cheap enough for low spec usually, but lets respect strict.
    if (!isLowSpec) {
      boss = boss.animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -10, duration: 2.seconds, curve: Curves.easeInOutSine); // Float
    }

    // Damage Reaction
    if (takeDamage) {
      if (isLowSpec) {
         boss = boss.animate().fade(end: 0.5, duration: 100.ms).then().fade(end: 1.0);
      } else {
         boss = boss.animate().shake(hz: 8, duration: 300.ms).tint(color: Colors.white, duration: 100.ms);
      }
    }

    return boss;
  }
}
