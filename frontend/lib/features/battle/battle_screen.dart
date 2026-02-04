import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_state.dart';
import '../../core/providers/auth_state.dart';
import '../../core/providers/gamification_state.dart';
import '../../core/services/gamification_service.dart';
import 'data/battle_state.dart';
import 'widgets/card_deck.dart';
import 'widgets/boss_hp_bar.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/notification_service.dart';

import 'widgets/boss_intro_overlay.dart';
import 'widgets/cinematic_boss_visuals.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  int? _selectedIndex;
  bool _showResult = false;
  bool _showIntro = true;
  double _prevHp = 1000;
  bool _takeDamage = false;

  @override
  void initState() {
    super.initState();
    // Reset state just in case
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Ensure fresh start if needed
    });
  }

  void _onCardSelect(int index) {
    if (_showResult) return;

    final controller = ref.read(battleProvider.notifier);
    final currentQuestion = controller.currentQuestion;
    final settings = ref.read(userStateProvider).settings;
    final battleState = ref.read(battleProvider);
    final isLastHit = battleState.bossHp <= 100; // Assuming 100 dmg per hit roughly? Or check actual logic.
    // Actually we don't know damage amount exactly without logic, but we can animate based on result.
    
    // Check if correct
    final isCorrect = index == currentQuestion?.correctIndex;

    setState(() {
      _selectedIndex = index;
      _showResult = true;
      if (isCorrect) _takeDamage = true;
    });

    // Immediate Feedback
    if (currentQuestion != null) {
      if (index == currentQuestion.correctIndex) {
         AudioService().playSound('sounds/laser_shoot.wav', settings.soundEffects);
         if (settings.hapticFeedback) HapticService.light();
      } else {
         AudioService().playSound('sounds/error.wav', settings.soundEffects);
         if (settings.hapticFeedback) HapticService.error();
      }
    }

    // Delay for Cinematic Pacing
    // If it's a kill shot (we anticipate), we might want longer delay or slow mo.
    final delayMs = isCorrect && isLastHit ? 2500 : 1500;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        // Stop damage animation
        setState(() => _takeDamage = false);
        
        controller.submitAnswer(index);
        setState(() {
          _selectedIndex = null;
          _showResult = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleProvider);
    final controller = ref.read(battleProvider.notifier);
    final currentQuestion = controller.currentQuestion;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Performance / Low Spec Detection
    // We check accessibility settings or if explicit low-spec mode (mock or user setting) is on.
    // For now, rely on standard "disableAnimations".
    final isLowSpec = MediaQuery.of(context).disableAnimations || 
                      MediaQuery.of(context).accessibleNavigation; 
    
    // Cinematic State Calculation
    final hpPercent = battleState.maxBossHp > 0 ? battleState.bossHp / battleState.maxBossHp : 0.0;
    final isPhase2 = hpPercent < 0.5 && hpPercent > 0;
    final isDead = battleState.bossHp <= 0;

    if (battleState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgBlack,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryCyan),
        ),
      );
    }

    // Handle Intro Finish
    if (_showIntro) {
       return BossIntroOverlay(
         bossName: "SYSTEM CORE",
         isLowSpec: isLowSpec,
         onFinished: () => setState(() => _showIntro = false),
       );
    }

    if (currentQuestion == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgBlack,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(
          child: Text(
            "No battle questions available.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBlack,
      body: Stack(
        children: [
          // Background gradient (Cinematic Shift)
          if (!isLowSpec)
            AnimatedContainer(
              duration: 1.seconds,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: isPhase2 
                      ? [Colors.deepOrange.shade900, Colors.black] // Phase 2: Intense
                      : [Colors.red.withOpacity(0.25), AppTheme.bgBlack], // Phase 1: Normal
                ),
              ),
            )
          else 
            Container( // Static background for low spec
                 decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: isPhase2 
                      ? [Colors.deepOrange.shade900, Colors.black]
                      : [Colors.red.withOpacity(0.25), AppTheme.bgBlack],
                ),
              ),
            ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final bossAreaHeight = availableHeight * 0.25;
                final questionAreaHeight = availableHeight * 0.18;
                final cardAreaHeight = availableHeight * 0.35;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    context.go('/dashboard');
                                  }
                                },
                              ),
                              Text(
                                "BOSS BATTLE",
                                style: AppTheme.labelLarge.copyWith(
                                  color: Colors.red,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),

                        // HP Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: BossHpBar(
                            currentHp: battleState.bossHp,
                            maxHp: battleState.maxBossHp,
                          ),
                        ),

                        // Boss Area (Cinematic)
                        SizedBox(
                          height: bossAreaHeight,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CinematicBossVisuals(
                                  isPhase2: isPhase2,
                                  isDead: isDead,
                                  takeDamage: _takeDamage,
                                  isLowSpec: isLowSpec,
                                  child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.red.shade800,
                                              Colors.red.shade900,
                                              Colors.black,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(0.6),
                                              blurRadius: 25,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.bug_report,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 12),
                                if (battleState.feedbackMessage != null && !_takeDamage)
                                  Text(
                                    battleState.feedbackMessage!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          battleState.feedbackMessage!.contains(
                                            "Correct",
                                          )
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ).animate().fadeIn().scale(),
                              ],
                            ),
                          ),
                        ),

                        // Question Panel
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryCyan.withOpacity(0.3),
                            ),
                          ),
                          child: AnimatedSwitcher( // Smooth transition between questions
                            duration: 300.ms,
                            child: Column(
                              key: ValueKey(currentQuestion.text),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Question ${battleState.currentQuestionIndex + 1}",
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentQuestion.text,
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 12),

                        // Card Deck
                        SizedBox(
                          height: cardAreaHeight,
                          child: CardDeck(
                            options: currentQuestion.options,
                            onSelect: _onCardSelect,
                            selectedIndex: _selectedIndex,
                            correctIndex: currentQuestion.correctIndex,
                            showResult: _showResult,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Victory Overlay (Replaces original logic mostly, but keep it consistent)
          if (battleState.isVictory)
            Container(
              color: Colors.black.withOpacity(0.95), // Darker for cinematic ending
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🏆", style: TextStyle(fontSize: 80))
                        .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      "VICTORY!",
                      style: AppTheme.headlineLarge.copyWith(
                        color: Colors.amber,
                        letterSpacing: 4,
                        fontSize: 40,
                      ),
                    ).animate().fadeIn().shimmer(duration: 1.5.seconds),
                    const SizedBox(height: 8),
                    Text(
                      "Boss Defeated!",
                      style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Award XP and increment battles won via API
                        final userId = ref.read(userStateProvider).profile.id;
                        if (userId.isNotEmpty) {
                          GamificationService.completeBattle(
                            userId,
                            true,
                            150,
                          ).then((success) {
                            if (success) {
                              // Refresh global stats
                              ref.read(gamificationProvider.notifier).refresh();
                            }
                          });
                        }

                        // Send Victory Notification
                        if (ref.read(userStateProvider).settings.notificationsEnabled) {
                           NotificationService().showNotification(
                             id: 1, 
                             title: 'Battle Won! 🏆', 
                             body: 'You defeated the boss and earned +150 XP!'
                           );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('+150 XP earned! 🎉'),
                            backgroundColor: Colors.amber,
                          ),
                        );
                        context.go('/dashboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        "CLAIM REWARDS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
