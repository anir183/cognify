import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/gamification_state.dart';
import '../../core/providers/user_state.dart';
import '../../core/providers/auth_state.dart';
import '../../core/theme/app_animations.dart';
import '../../shared/animations/breathing_card.dart';
import '../../shared/animations/animated_neon_button.dart';


import 'widgets/xp_bar.dart';
import 'widgets/stats_grid.dart';
import 'widgets/progress_chart.dart';
import 'widgets/mastery_pie_chart.dart';
import 'widgets/course_card.dart';
import 'widgets/notifications_sheet.dart';
import 'package:cognify/features/explore/data/explore_state.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("🏗️ BUILDING DASHBOARD_SCREEN");
    final userState = ref.watch(userStateProvider);
    final profile = userState.profile;
    final hasUnread = userState.notifications.any((n) => n.isUnread);
    final authState = ref.watch(authProvider); // Watch auth state
    final isInstructor = authState.role == 'instructor';

    final gamification = ref.watch(gamificationProvider);
    
    // Show loading indicator while data is being fetched
    if (gamification.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryCyan),
              const SizedBox(height: 16),
              Text(
                "Loading your dashboard...",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      );
    }
    
    final stats = gamification.userStats;

    // userState already watched at line 30
    
    // Fix Course constructor: 'description' parameter was missing or named incorrectly in previous error.
    // Assuming Course model has 'description'. If not, I will remove it.
    // Error said: "No named parameter with the name 'description'".
    // Checking previous conversation logic, maybe I should remove description if it's not needed or use a different field.
    // I will remove 'description' validation for now to be safe, or check explore_state.dart if possible.
    // Actually, I'll view explore_state.dart to be sure. But for now I'll just remove the duplicate declaration.
    // And fixing the Course instantiation based on the error.
    final myCourses = userState.stats.courses > 0 ? [
      Course(
        id: '1', 
        title: 'Cosmic Coding', 
        subtitle: 'Learn Flutter',
        emoji: '🚀',
        colorHex: '0xFF00FFFF',
        progress: 0.2,
        status: CourseStatus.ongoing,
        lessons: 10, 
        duration: '12h',
        // Removed properties not in Course model: category, level, xpReward, rating, thumbnailUrl
      )
    ] : [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isInstructor) ...[
                  GestureDetector(
                    onTap: () => context.go('/instructor/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school, color: Colors.orange),
                          const SizedBox(width: 12),
                          Text(
                            "Viewing as Student - Switch Back to Instructor",
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                        Text(profile.name, style: AppTheme.headlineMedium),
                      ],
                    ),
                    Row(
                      children: [
                        // Leaderboard button
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
                            onPressed: () {
                               if (userState.settings.hapticFeedback) HapticService.light();
                               AudioService().playSound('sounds/ui_click.wav', userState.settings.soundEffects);
                               context.push('/leaderboard');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                         // Notifications button
                        GestureDetector(
                          onTap: () {
                             if (userState.settings.hapticFeedback) HapticService.light();
                             AudioService().playSound('sounds/ui_click.wav', userState.settings.soundEffects);
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.4,
                                maxChildSize: 0.9,
                                builder: (_, controller) =>
                                    const NotificationsSheet(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 24),
                BreathingCard(
                  glowColor: AppTheme.primaryCyan,
                   child: XpBar(
                    level: stats.level,
                    currentXp: stats.totalXp % 1000,
                    maxXp: 1000,
                    rank: profile.name,
                  ),
                ),
                const SizedBox(height: 24),
                
                // StatsGrid - Re-enabled
                const StatsGrid(),
                // const Center(child: Text("StatsGrid Placeholder", style: TextStyle(color: Colors.white))),
                
                const SizedBox(height: 24),
                
                const ProgressChart(),
                // const Center(child: Text("ProgressChart Placeholder", style: TextStyle(color: Colors.white))),
                
                const SizedBox(height: 16),
                
                const MasteryPieChart(),
                // const Center(child: Text("MasteryPieChart Placeholder", style: TextStyle(color: Colors.white))),
                
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                Text(
                  "QUICK ACTIONS",
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.primaryCyan,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedNeonButton(
                        label: "Forum",
                        icon: Icons.forum,
                        color: Colors.blue,
                        onTap: () => context.go('/forum'),
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedNeonButton(
                        label: "Ask Oracle",
                        icon: Icons.psychology,
                        color: AppTheme.accentPurple,
                        onTap: () => context.go('/ai-chat'),
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MY COURSES",
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.accentPurple,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                         if (userState.settings.hapticFeedback) HapticService.light();
                         AudioService().playSound('sounds/ui_click.wav', userState.settings.soundEffects);
                         context.go('/explore');
                      },
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: myCourses.isEmpty
                      ? Center(
                          child: Text(
                            "No active courses yet. Start exploring!",
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: myCourses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final course = myCourses[index];
                            return GestureDetector(
                              onTap: () {
                                 if (userState.settings.hapticFeedback) HapticService.light();
                                 AudioService().playSound('sounds/ui_click.wav', userState.settings.soundEffects);
                                 context.go('/course/${course.id}');
                              },
                              child: CourseCard(course: course),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
      ),
    );
  }
}
