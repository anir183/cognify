import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'battle_effect_overlay.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/providers/user_state.dart';
import '../../../../core/constants/app_sounds.dart';

class BattleArena extends ConsumerStatefulWidget {
  final Widget child;
  final bool shakeScreen;
  final List<Projectile> projectiles;

  const BattleArena({
    super.key,
    required this.child,
    this.shakeScreen = false,
    this.projectiles = const [],
  });

  @override
  ConsumerState<BattleArena> createState() => _BattleArenaState();
}

class _BattleArenaState extends ConsumerState<BattleArena> {
  @override
  void didUpdateWidget(BattleArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Play sound on shake (Damage/Impact)
    if (widget.shakeScreen && !oldWidget.shakeScreen) {
        final settings = ref.read(userStateProvider).settings;
        AudioService().play(SoundType.battleHit, settings.soundEffects);
    }

    // Play sound on new projectile (Attack)
    if (widget.projectiles.length > oldWidget.projectiles.length) {
         final settings = ref.read(userStateProvider).settings;
         AudioService().play(SoundType.battleAttack, settings.soundEffects);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Main Content (Shakable)
        Positioned.fill(
          child: widget.child
              .animate(target: widget.shakeScreen ? 1 : 0)
              .shake(
                duration: 500.ms,
                hz: 10,
                offset: const Offset(10, 10), // Stronger shake
                curve: Curves.easeInOut,
              ),
        ),

        // 2. Projectile Overlay (Fixed on top, not shaken relative to camera)
        if (widget.projectiles.isNotEmpty)
          Positioned.fill(
            child: BattleEffectOverlay(projectiles: widget.projectiles),
          ),
          
        // 3. Dark Vignette (Damage Feedback) - Optional triggers could go here
      ],
    );
  }
}
