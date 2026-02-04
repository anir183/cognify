import 'package:flutter/material.dart';
import '../../../core/providers/gamification_state.dart';
import '../../../core/theme/app_theme.dart';

enum AchievementRarity { common, rare, epic, legendary }

extension AchievementRarityExt on Achievement {
  AchievementRarity get rarity => _rarityMap[id] ?? _inferRarity();

  // Custom mapping for specific IDs if known, otherwise infer
  static const Map<String, AchievementRarity> _rarityMap = {
    'program_master': AchievementRarity.legendary,
    'battle_legend': AchievementRarity.legendary,
    'perfect_streak_30': AchievementRarity.legendary,
    'course_master': AchievementRarity.epic,
    'battle_veteran': AchievementRarity.epic,
    '7_day_streak': AchievementRarity.rare,
    'perfect_score': AchievementRarity.rare,
    'first_win': AchievementRarity.common,
  };

  AchievementRarity _inferRarity() {
    if (xpReward >= 1000) return AchievementRarity.legendary;
    if (xpReward >= 500) return AchievementRarity.epic;
    if (xpReward >= 200) return AchievementRarity.rare;
    return AchievementRarity.common;
  }
}

extension RarityVisuals on AchievementRarity {
  Color get color {
    switch (this) {
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700); // Gold/Amber
      case AchievementRarity.epic:
        return Colors.purpleAccent;
      case AchievementRarity.rare:
        return Colors.cyanAccent;
      case AchievementRarity.common:
        return Colors.blueGrey;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case AchievementRarity.legendary:
        return [const Color(0xFFFFD700), const Color(0xFFDAA520), Colors.amber];
      case AchievementRarity.epic:
        return [Colors.purpleAccent, Colors.deepPurple];
      case AchievementRarity.rare:
        return [Colors.cyanAccent, Colors.blueAccent];
      case AchievementRarity.common:
        return [Colors.blueGrey, Colors.grey];
    }
  }

  double get glowIntensity {
    switch (this) {
      case AchievementRarity.legendary:
        return 16.0;
      case AchievementRarity.epic:
        return 12.0;
      case AchievementRarity.rare:
        return 8.0;
      case AchievementRarity.common:
        return 0.0;
    }
  }
}
