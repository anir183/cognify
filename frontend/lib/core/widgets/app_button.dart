import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../providers/user_state.dart';
import '../constants/app_sounds.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.color,
  });

  Future<void> _handlePress(WidgetRef ref) async {
    if (onPressed == null || isLoading) return;

    // Feedback
    final settings = ref.read(userStateProvider).settings;
    if (settings.hapticFeedback) HapticService.light();
    
    SoundType soundType;
    switch (type) {
      case AppButtonType.primary:
        soundType = SoundType.tapPrimary;
        break;
      case AppButtonType.secondary:
      case AppButtonType.outline:
        soundType = SoundType.tapSecondary;
        break;
      case AppButtonType.text:
        soundType = SoundType.tapIcon;
        break;
    }
    
    AudioService().play(soundType, settings.soundEffects);

    // Execute callback
    onPressed!();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (type == AppButtonType.text) {
      return TextButton(
        onPressed: onPressed == null ? null : () => _handlePress(ref),
        child: _buildContent(),
      );
    }

    final buttonStyle = _getStyle();

    return SizedBox(
      width: width,
      height: 50,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: isLoading || onPressed == null ? null : () => _handlePress(ref),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon),
              label: isLoading ? const Text('Loading...') : Text(label),
              style: buttonStyle,
            )
          : ElevatedButton(
              onPressed: isLoading || onPressed == null ? null : () => _handlePress(ref),
              style: buttonStyle,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(label),
            ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }

  ButtonStyle _getStyle() {
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.primaryCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: AppTheme.primaryCyan.withOpacity(0.4),
        );
      case AppButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardColor,
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      case AppButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: color ?? AppTheme.primaryCyan,
          side: BorderSide(color: color ?? AppTheme.primaryCyan),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.transparent,
        );
      default:
        return ElevatedButton.styleFrom();
    }
  }
}
