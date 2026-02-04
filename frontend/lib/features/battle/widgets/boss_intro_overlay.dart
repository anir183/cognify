import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../core/theme/app_theme.dart';

class BossIntroOverlay extends StatelessWidget {
  final VoidCallback onFinished;
  final String bossName;
  final bool isLowSpec;

  const BossIntroOverlay({
    super.key,
    required this.onFinished,
    this.bossName = "SYSTEM CORE",
    this.isLowSpec = false,
  });

  @override
  Widget build(BuildContext context) {
    // Low Spec: Simplified animations
    if (isLowSpec) {
       return Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                "WARNING",
                style: AppTheme.labelLarge.copyWith(color: Colors.redAccent, letterSpacing: 8),
               ).animate().fadeIn(duration: 500.ms),
               const SizedBox(height: 20),
               Text(
                bossName,
                style: AppTheme.headlineLarge.copyWith(color: Colors.white, fontSize: 40),
               ).animate()
                .scale(duration: 500.ms)
                .then(delay: 2.seconds)
                .callback(callback: (_) => onFinished())
            ],
          ),
        ).animate().fadeOut(delay: 2.5.seconds, duration: 300.ms),
       );
    }

    // High Spec: Full Cinematic
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Dark Background Fade
          Positioned.fill(
            child: Container(color: Colors.black)
                .animate()
                .fadeOut(delay: 2.5.seconds, duration: 500.ms),
          ),

          // 2. Boss Name / Warning
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "WARNING",
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.redAccent,
                  letterSpacing: 8,
                  fontSize: 16,
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -2, end: 0)
               .then(delay: 1.5.seconds).fadeOut(),
              
              const SizedBox(height: 20),

              // Cinematic Title Animation: Blur -> Sharp + Light Sweep
              Text(
                bossName,
                style: AppTheme.headlineLarge.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                     BoxShadow(color: Colors.red, blurRadius: 40, spreadRadius: 10),
                  ]
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 1.2.seconds, curve: Curves.easeOutCubic)
              .blur(begin: const Offset(10, 10), end: Offset.zero, duration: 800.ms) // Blur to Sharp
              .fadeIn(duration: 300.ms)
              .shimmer(delay: 400.ms, duration: 1.2.seconds, color: Colors.white) // Light Sweep
              .then(delay: 1.seconds)
              .fadeOut(duration: 300.ms)
              .callback(callback: (_) => onFinished()),
            ],
          ),
          
          // 3. Energy Lines (Decorative)
          Positioned.fill(
             child: IgnorePointer(
               child: Container(
                 decoration: BoxDecoration(
                   gradient: RadialGradient(
                     colors: [Colors.transparent, Colors.red.withOpacity(0.2)],
                     radius: 1.5,
                   ),
                 ),
               ),
             ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
        ],
      ),
    );
  }
}
