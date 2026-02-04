import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_sounds.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Cache last played times for throttling
  final Map<String, DateTime> _lastPlayed = {};
  
  // Throttle durations
  static const Duration _throttleTap = Duration(milliseconds: 100);
  static const Duration _throttleCommon = Duration(milliseconds: 200);

  Future<void> init() async {
    // Optional: Preload if critical
  }

  /// Play a sound with specific behavior based on its type.
  /// [soundEnabled] must be passed from UserState settings.
  Future<void> play(SoundType type, bool soundEnabled, {double? volumeOverride}) async {
    if (!soundEnabled) return;

    final String path = _getPath(type);
    final double volume = volumeOverride ?? _getVolume(type);
    final Duration throttle = _getThrottle(type);

    // Throttling Check
    final now = DateTime.now();
    if (_lastPlayed.containsKey(path)) {
      if (now.difference(_lastPlayed[path]!) < throttle) {
        return; // Skip if throttled
      }
    }
    _lastPlayed[path] = now;

    try {
      final player = AudioPlayer();
      // Set volume before playing
      await player.setVolume(volume);
      
      // Use AssetSource - assumes files serve from assets/
      await player.play(AssetSource(path));
      
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      // Squelch errors for missing assets as requested
    }
  }

  String _getPath(SoundType type) {
    switch (type) {
      // UI
      case SoundType.tapPrimary: return AppSounds.tapPrimary;
      case SoundType.tapSecondary: return AppSounds.tapSecondary;
      case SoundType.tapIcon: return AppSounds.tapIcon;
      case SoundType.toggle: return AppSounds.toggleOn; // Simplification
      
      // Forms
      case SoundType.submit: return AppSounds.submit;
      case SoundType.success: return AppSounds.success;
      case SoundType.error: return AppSounds.error;
      case SoundType.inputFocus: return AppSounds.inputFocus;
      
      // Auth
      case SoundType.login: return AppSounds.loginSuccess;

      // Battle
      case SoundType.battleSelect: return AppSounds.battleSelect;
      case SoundType.battleAttack: return AppSounds.battleAttack;
      case SoundType.battleHit: return AppSounds.battleDamage;
      case SoundType.battleCombo: return AppSounds.battleCombo;
      case SoundType.battleBoss: return AppSounds.battleBoss;

      // Unlock
      case SoundType.unlockCommon: return AppSounds.unlockCommon;
      case SoundType.unlockRare: return AppSounds.unlockRare;
      case SoundType.unlockLegendary: return AppSounds.unlockLegendary;

      // Brand
      case SoundType.signature: return AppSounds.signature;
    }
  }

  double _getVolume(SoundType type) {
    switch (type) {
      case SoundType.tapPrimary:
      case SoundType.tapSecondary:
      case SoundType.tapIcon:
      case SoundType.toggle:
        return AppSounds.volUI;
        
      case SoundType.submit:
      case SoundType.success:
      case SoundType.error:
      case SoundType.inputFocus:
      case SoundType.login:
        return AppSounds.volForm;

      case SoundType.battleSelect:
      case SoundType.battleAttack:
      case SoundType.battleHit:
      case SoundType.battleCombo:
      case SoundType.battleBoss:
        return AppSounds.volBattle;

      case SoundType.unlockCommon:
      case SoundType.unlockRare:
        return AppSounds.volUI; // Slightly louder than bg, standard ui
      case SoundType.unlockLegendary:
      case SoundType.signature:
        return AppSounds.volLegendary;
    }
  }

  Duration _getThrottle(SoundType type) {
    switch (type) {
      case SoundType.tapPrimary:
      case SoundType.tapSecondary:
      case SoundType.tapIcon:
      case SoundType.toggle:
        return _throttleTap;
      
      // Battle allowed rapid fire
      case SoundType.battleAttack:
      case SoundType.battleHit:
      case SoundType.battleCombo:
        return Duration.zero; 
        
      default: return _throttleCommon;
    }
  }

  // Legacy support helper (will be deprecated, mapping old calls to new system)
  Future<void> playSound(String soundPath, bool soundEnabled) async {
    // Try to map path to type, otherwise default play
    if (soundPath.contains('ui_click') || soundPath.contains('tap')) {
        await play(SoundType.tapPrimary, soundEnabled);
        return;
    }
    
    // Fallback for unmapped paths
     if (!soundEnabled) return;
     try {
       final player = AudioPlayer();
       await player.setVolume(0.1); // Default low volume
       await player.play(AssetSource(soundPath));
       player.onPlayerComplete.listen((_) => player.dispose());
     } catch (_) {}
  }
}
