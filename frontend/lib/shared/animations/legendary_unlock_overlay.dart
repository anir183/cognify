import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/providers/gamification_state.dart';
import '../../features/gamification/models/achievement_rarity.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/user_state.dart';
import '../../core/constants/app_sounds.dart';

class LegendaryUnlockOverlay extends ConsumerStatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const LegendaryUnlockOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  ConsumerState<LegendaryUnlockOverlay> createState() => _LegendaryUnlockOverlayState();
}

class _LegendaryUnlockOverlayState extends ConsumerState<LegendaryUnlockOverlay> {
  @override
  void initState() {
    super.initState();
    
    // Play sound immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
        final settings = ref.read(userStateProvider).settings;
        AudioService().play(SoundType.unlockLegendary, settings.soundEffects);
    });

    // Auto dismiss after animation
    Future.delayed(const Duration(seconds: 4), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.achievement.rarity != AchievementRarity.legendary) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Vignette / Dim Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // 2. Light Rays / Energy Burst
          Positioned.fill(
             child: Center(
               child: Container(
                 width: 300,
                 height: 300,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: RadialGradient(
                     colors: [Colors.amber.withOpacity(0.5), Colors.transparent],
                     stops: const [0.2, 1.0],
                   ),
                 ),
               ),
             ),
          ).animate().scale(begin: const Offset(0, 0), end: const Offset(2, 2), duration: 1.seconds, curve: Curves.easeOut),

          // 3. Achievement Icon
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.achievement.emoji,
                style: const TextStyle(fontSize: 100),
              )
              .animate()
              .scale(begin: const Offset(0, 0), end: const Offset(1.2, 1.2), duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 1.seconds, color: Colors.white),

              const SizedBox(height: 24),

              Text(
                "LEGENDARY UNLOCKED",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: Colors.amber, blurRadius: 20),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),

              const SizedBox(height: 12),

              Text(
                widget.achievement.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
          
          // 4. Particles (Simulated with simple dots for now)
          ...List.generate(6, (index) => Positioned(
             left: 100.0 + (index * 50),
             top: 200.0 + (index * 30),
             child: Icon(Icons.star, color: Colors.amber, size: 20)
                .animate(delay: (index * 100).ms)
                .moveY(begin: 0, end: -300, duration: 1.seconds)
                .fadeOut(),
          )),
        ],
      ),
    );
  }
}
