import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../models/achievement_rarity.dart';
import '../../../core/providers/gamification_state.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final rarity = achievement.rarity;
    final color = rarity.color;
    final isLocked = !achievement.isUnlocked;

    return Tooltip(
      message: isLocked ? 'Locked: ${achievement.requirement}' : '${achievement.name}\n${achievement.description}',
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isLocked ? Colors.black26 : color.withOpacity(0.1),
          gradient: isLocked 
            ? null 
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: rarity.gradient.map((c) => c.withOpacity(0.2)).toList(),
              ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? Colors.white10 : color.withOpacity(0.5),
            width: rarity == AchievementRarity.legendary ? 2 : 1,
          ),
          boxShadow: isLocked || rarity == AchievementRarity.common
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: rarity.glowIntensity,
                    spreadRadius: 1,
                  )
                ],
        ),
        child: Stack(
          children: [
            // Rarity Indicator (Top Right)
            if (!isLocked && rarity != AchievementRarity.common)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                         color: color.withOpacity(0.4),
                         blurRadius: 10,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3)),
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: isLocked ? Colors.white.withOpacity(0.3) : null,
                    shadows: isLocked ? [] : [
                      Shadow(
                        color: color.withOpacity(0.6),
                        blurRadius: rarity.glowIntensity,
                      )
                    ],
                  ),
                )
                .animate(target: isLocked ? 0 : 1)
                .scale(
                   begin: const Offset(1, 1), 
                   end: rarity == AchievementRarity.legendary ? const Offset(1.1, 1.1) : const Offset(1, 1),
                   duration: 2.seconds,
                   curve: Curves.easeInOut, 
                 )
                .then()
                .animate(onPlay: (c) => rarity == AchievementRarity.legendary ? c.repeat(reverse: true) : null)
                .scaleXY(end: 1.1, duration: 2.seconds),

                const SizedBox(height: 8),
                
                // Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    achievement.name,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isLocked)
                   Text(
                     rarity.name.toUpperCase(),
                     style: TextStyle(
                       color: color,
                       fontSize: 8,
                       fontWeight: FontWeight.w900,
                       letterSpacing: 1,
                     ),
                   ),
              ],
            ),
            
            if (isLocked)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
