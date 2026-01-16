import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// User Profile
class UserProfile {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String avatarEmoji;
  final String institution;

  const UserProfile({
    this.id = '',
    this.name = 'Cyber Ninja',
    this.username = 'cyberninja42',
    this.bio = 'Learning every day!',
    this.avatarEmoji = '🥷',
    this.institution = '',
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? bio,
    String? avatarEmoji,
    String? institution,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      institution: institution ?? this.institution,
    );
  }
}

// App Settings
class AppSettings {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool soundEffects;
  final bool hapticFeedback;

  const AppSettings({
    this.isDarkMode = true,
    this.notificationsEnabled = true,
    this.soundEffects = true,
    this.hapticFeedback = true,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? soundEffects,
    bool? hapticFeedback,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }
}

// User Stats
class UserStats {
  final int level;
  final int currentXp;
  final int maxXp;
  final int battlesWon;
  final int courses;
  final int streak;
  final int globalRank;
  final int confidenceScore;
  final List<int> weeklyXp;

  const UserStats({
    this.level = 5,
    this.currentXp = 350,
    this.maxXp = 1000,
    this.battlesWon = 12,
    this.courses = 3,
    this.streak = 7,
    this.globalRank = 42,
    this.confidenceScore = 0,
    this.weeklyXp = const [],
  });

  UserStats copyWith({
    int? level,
    int? currentXp,
    int? maxXp,
    int? battlesWon,
    int? courses,
    int? streak,
    int? globalRank,
    int? confidenceScore,
    List<int>? weeklyXp,
  }) {
    return UserStats(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      battlesWon: battlesWon ?? this.battlesWon,
      courses: courses ?? this.courses,
      streak: streak ?? this.streak,
      globalRank: globalRank ?? this.globalRank,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      weeklyXp: weeklyXp ?? this.weeklyXp,
    );
  }
}

// Notification Item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = true,
  });

  NotificationItem copyWith({bool? isUnread}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      time: time,
      icon: icon,
      color: color,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    IconData icon;
    Color color;

    switch (json['type']) {
      case 'challenge':
        icon = Icons.bolt;
        color = const Color(0xFFB388FF);
        break;
      case 'level_up':
        icon = Icons.arrow_upward;
        color = const Color(0xFF00E5CC);
        break;
      case 'course':
        icon = Icons.school;
        color = Colors.orange;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blue;
    }

    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      time: _formatTime(json['createdAt']),
      icon: icon,
      color: color,
      isUnread: !(json['isRead'] ?? false),
    );
  }

  static String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return 'Just now';
    }
  }
}

// Complete User State
class UserState {
  final UserProfile profile;
  final AppSettings settings;
  final UserStats stats;
  final List<NotificationItem> notifications;

  const UserState({
    this.profile = const UserProfile(),
    this.settings = const AppSettings(),
    this.stats = const UserStats(),
    this.notifications = const [],
  });

  UserState copyWith({
    UserProfile? profile,
    AppSettings? settings,
    UserStats? stats,
    List<NotificationItem>? notifications,
  }) {
    return UserState(
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      notifications: notifications ?? this.notifications,
    );
  }
}

// User State Notifier
class UserStateNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    _loadSettings();
    // Fetch notifications asynchronously
    Future.microtask(() => fetchNotifications());
    return UserState(notifications: []);
  }

  Future<void> fetchNotifications() async {
    try {
      final result = await ApiService.get('/api/notifications');
      if (result is List) {
        final notifications = result
            .map(
              (item) => NotificationItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        state = state.copyWith(notifications: notifications);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state.settings.isDarkMode);
    await prefs.setBool(
      'notificationsEnabled',
      state.settings.notificationsEnabled,
    );
    await prefs.setBool('soundEffects', state.settings.soundEffects);
    await prefs.setBool('hapticFeedback', state.settings.hapticFeedback);
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_id', state.profile.id);
    await prefs.setString('profile_name', state.profile.name);
    await prefs.setString('profile_username', state.profile.username);
    await prefs.setString('profile_bio', state.profile.bio);
    await prefs.setString('profile_avatar', state.profile.avatarEmoji);
    await prefs.setString('profile_institution', state.profile.institution);

    await prefs.setInt('stats_level', state.stats.level);
    await prefs.setInt('stats_xp', state.stats.currentXp);
    await prefs.setInt('stats_max_xp', state.stats.maxXp);
    await prefs.setInt('stats_battles', state.stats.battlesWon);
    await prefs.setInt('stats_courses', state.stats.courses);
    await prefs.setInt('stats_streak', state.stats.streak);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Settings
    final isDarkMode = prefs.getBool('isDarkMode') ?? true;
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final soundEffects = prefs.getBool('soundEffects') ?? true;
    final hapticFeedback = prefs.getBool('hapticFeedback') ?? true;

    // Load Profile
    final id = prefs.getString('profile_id');
    final name = prefs.getString('profile_name');
    final username = prefs.getString('profile_username');
    final bio = prefs.getString('profile_bio');
    final avatarEmoji = prefs.getString('profile_avatar');
    final institution = prefs.getString('profile_institution');

    // Load Stats
    final level = prefs.getInt('stats_level');
    final currentXp = prefs.getInt('stats_xp');
    final maxXp = prefs.getInt('stats_max_xp');
    final battlesWon = prefs.getInt('stats_battles');
    final courses = prefs.getInt('stats_courses');
    final streak = prefs.getInt('stats_streak');

    var newState = state.copyWith(
      settings: AppSettings(
        isDarkMode: isDarkMode,
        notificationsEnabled: notificationsEnabled,
        soundEffects: soundEffects,
        hapticFeedback: hapticFeedback,
      ),
    );

    if (name != null) {
      newState = newState.copyWith(
        profile: UserProfile(
          id: id ?? '',
          name: name,
          username: username ?? 'user',
          bio: bio ?? 'Learning every day!',
          avatarEmoji:
              avatarEmoji ??
              ((id?.toLowerCase().contains('instructor') ?? false)
                  ? '👨‍🏫'
                  : '🥷'),
          institution: institution ?? '',
        ),
        stats: UserStats(
          level: level ?? 1,
          currentXp: currentXp ?? 0,
          maxXp: maxXp ?? 1000,
          battlesWon: battlesWon ?? 0,
          courses: courses ?? 0,
          streak: streak ?? 0,
          globalRank: 42, // Keeping mock for now
        ),
      );
    }

    state = newState;
  }

  // User Methods
  void setUser(Map<String, dynamic> userData) {
    if (userData.isEmpty) return;

    state = state.copyWith(
      profile: state.profile.copyWith(
        id: userData['id'] ?? userData['email'] ?? '',
        name: userData['name'] ?? 'User',
        username: userData['username'] ?? 'user',
        avatarEmoji: userData['avatarEmoji'] ?? '🥷',
        institution: userData['institution'] ?? '',
      ),
      stats: state.stats.copyWith(
        level: userData['level'] ?? 1,
        currentXp: userData['xp'] ?? 0,
        // Mock other stats for now as they might not be in the user model yet
        battlesWon: 0,
        courses: 0,
        streak: 0,
        globalRank: userData['globalRank'] ?? 0,
        confidenceScore: userData['confidenceScore'] ?? 0,
        weeklyXp:
            (userData['weeklyXp'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
      ),
    );
    _saveProfile();
  }

  // Profile Methods
  Future<void> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? avatarEmoji,
    String? institution,
  }) async {
    // Optimistic update
    state = state.copyWith(
      profile: state.profile.copyWith(
        name: name,
        username: username,
        bio: bio,
        avatarEmoji: avatarEmoji,
        institution: institution,
      ),
    );
    _saveProfile();

    try {
      // Sync with backend
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email != null) {
        await ApiService.post('/api/update-profile', {
          'id': email,
          'name': state.profile.name,
          'username': state.profile.username,
          'bio': state.profile.bio,
          'avatarEmoji': state.profile.avatarEmoji,
          'institution': state.profile.institution,
        });
      } else {
        debugPrint('Warning: No email found for profile update');
      }
    } catch (e) {
      debugPrint('Error updating profile on backend: $e');
    }
  }

  // Settings Methods
  void setDarkMode(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(isDarkMode: value),
    );
    _saveSettings();
  }

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(notificationsEnabled: value),
    );
    _saveSettings();
  }

  void setSoundEffects(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(soundEffects: value),
    );
    _saveSettings();
  }

  void setHapticFeedback(bool value) {
    state = state.copyWith(
      settings: state.settings.copyWith(hapticFeedback: value),
    );
    _saveSettings();
  }

  // Stats Methods
  void addXp(int xp) {
    var newXp = state.stats.currentXp + xp;
    var newLevel = state.stats.level;
    var newMaxXp = state.stats.maxXp;

    while (newXp >= newMaxXp) {
      newXp -= newMaxXp;
      newLevel++;
      newMaxXp = (newMaxXp * 1.2).toInt();
    }

    state = state.copyWith(
      stats: state.stats.copyWith(
        currentXp: newXp,
        level: newLevel,
        maxXp: newMaxXp,
      ),
    );
  }

  void incrementBattlesWon() {
    state = state.copyWith(
      stats: state.stats.copyWith(battlesWon: state.stats.battlesWon + 1),
    );
  }

  // Notification Methods
  Future<void> clearAllNotifications() async {
    final unreadIds = state.notifications
        .where((n) => n.isUnread)
        .map((n) => n.id)
        .toList();

    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isUnread: false))
          .toList(),
    );

    for (final id in unreadIds) {
      try {
        await ApiService.post('/api/notifications/$id/read', {});
      } catch (e) {
        debugPrint('Error marking notification $id read: $e');
      }
    }
  }

  Future<void> markNotificationRead(String id) async {
    // Optimistic update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isUnread: false);
        return n;
      }).toList(),
    );

    // Sync with backend
    try {
      await ApiService.post('/api/notifications/$id/read', {});
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  int get unreadCount => state.notifications.where((n) => n.isUnread).length;
}

// Providers
final userStateProvider = NotifierProvider<UserStateNotifier, UserState>(
  UserStateNotifier.new,
);
