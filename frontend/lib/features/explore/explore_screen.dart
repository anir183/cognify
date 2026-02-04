import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_state.dart';
import 'data/explore_state.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exploreState = ref.watch(exploreProvider);
    final controller = ref.read(exploreProvider.notifier);
    final userConfidence = ref.watch(userStateProvider).stats.confidenceScore;
    final filters = ['All', 'Enrolled', 'Ongoing', 'Completed'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Explore Quests", style: AppTheme.headlineMedium),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = exploreState.filter == filter.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) =>
                        controller.setFilter(filter.toLowerCase()),
                    selectedColor: AppTheme.primaryCyan,
                    backgroundColor: AppTheme.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (exploreState.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryCyan,
                    ),
                  ),

                if (!exploreState.isLoading &&
                    exploreState.recommendedCourses.isNotEmpty &&
                    exploreState.filter == 'all') ...[
                  Text(
                    "RECOMMENDED FOR YOU",
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.primaryCyan,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...exploreState.recommendedCourses.map(
                    (course) => _RecommendationCard(
                      course: course,
                      onTap: () => context.go('/course/${course.id}'),
                    ).animate().fadeIn().slideX(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "ALL QUESTS",
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!exploreState.isLoading)
                  ...exploreState.filteredCourses.map((course) {
                    return _CourseListItem(
                      course: course,
                      userConfidence: userConfidence,
                      onTap: () => context.go('/course/${course.id}'),
                    ).animate().fadeIn().slideX();
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseListItem extends StatelessWidget {
  final Course course;
  final int userConfidence;
  final VoidCallback onTap;

  const _CourseListItem({
    required this.course,
    required this.userConfidence,
    required this.onTap,
  });

  String _getStatusLabel() {
    switch (course.status) {
      case CourseStatus.available:
        return '\$${course.price.toStringAsFixed(0)}';
      case CourseStatus.enrolled:
        return 'START';
      case CourseStatus.ongoing:
        return '${(course.progress * 100).toInt()}%';
      case CourseStatus.completed:
        return '✓ DONE';
    }
  }

  Color _getStatusColor() {
    switch (course.status) {
      case CourseStatus.available:
        return AppTheme.accentPurple;
      case CourseStatus.enrolled:
        return AppTheme.primaryCyan;
      case CourseStatus.ongoing:
        return Colors.orange;
      case CourseStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely parse color - handle various formats
    Color color;
    try {
      String hex = course.colorHex;
      if (hex.startsWith('#')) {
        hex = hex.replaceFirst('#', '0xFF');
      } else if (!hex.startsWith('0x') && !hex.startsWith('0X')) {
        hex = '0xFF$hex';
      }
      color = Color(int.parse(hex));
    } catch (e) {
      color = AppTheme.primaryCyan; // Fallback color
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(course.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.subtitle,
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        course.instructor,
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.book, size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lessons} lessons',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (course.status == CourseStatus.ongoing) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: course.progress,
                        backgroundColor: Colors.black,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDifficultyChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip() {
    Color chipColor = AppTheme.textGrey;
    String label = '${course.difficultyRating}/5';
    IconData icon = Icons.bar_chart;

    if (course.status != CourseStatus.available) return const SizedBox.shrink();

    // AI Logic for Difficulty Chip
    if (userConfidence >= 50 && course.difficultyRating <= 3) {
      chipColor = Colors.green;
      label = "Great Match";
      icon = Icons.thumb_up;
    } else if (userConfidence < 30 && course.difficultyRating >= 4) {
      chipColor = Colors.red;
      label = "Challenging";
      icon = Icons.warning;
    } else if (course.difficultyRating >= 4) {
      chipColor = Colors.orange;
      label = "Advanced";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _RecommendationCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Safely parse color - handle various formats
    Color color;
    try {
      String hex = course.colorHex;
      if (hex.startsWith('#')) {
        hex = hex.replaceFirst('#', '0xFF');
      } else if (!hex.startsWith('0x') && !hex.startsWith('0X')) {
        hex = '0xFF$hex';
      }
      color = Color(int.parse(hex));
    } catch (e) {
      color = AppTheme.primaryCyan; // Fallback color
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryCyan,
            width: 2,
          ), // Highlighted border
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "AI SUGGESTION",
                  style: TextStyle(
                    color: AppTheme.primaryCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      course.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        course.instructor,
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                course.recommendationReason ??
                    "Recommended based on your profile.",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
