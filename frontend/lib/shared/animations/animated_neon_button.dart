import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/providers/user_state.dart';
import '../../core/theme/app_theme.dart';

class AnimatedNeonButton extends ConsumerStatefulWidget {
  final String label;
  final String? text; // Restored for backward compatibility
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onPressed; // Restored for backward compatibility
  final bool isPrimary;
  final Gradient? gradient;

  const AnimatedNeonButton({
    super.key,
    this.label = '',
    this.text,
    this.icon,
    this.color,
    this.onTap,
    this.onPressed,
    this.isPrimary = true,
    this.gradient,
  });

  @override
  ConsumerState<AnimatedNeonButton> createState() => _AnimatedNeonButtonState();
}

class _AnimatedNeonButtonState extends ConsumerState<AnimatedNeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    final callback = widget.onTap ?? widget.onPressed;
    if (callback != null) {
      // Feedback
      _playFeedback();
      callback();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _playFeedback() {
    try {
      final userState = ref.read(userStateProvider);
      final settings = userState.settings;
      if (settings.hapticFeedback) HapticService.light();
      AudioService().playSound('sounds/ui_click.wav', settings.soundEffects);
    } catch (e) {
      // Fail silently if feedback providers aren't ready (e.g. during auth)
      debugPrint("Feedback error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default color if unprovided
    final color = widget.color ?? (widget.isPrimary ? AppTheme.primaryCyan : Colors.white);
    
    // Use text if label is empty (compatibility)
    final displayLabel = (widget.text != null && widget.text!.isNotEmpty) 
        ? widget.text! 
        : widget.label;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: widget.gradient == null 
                  ? (widget.isPrimary ? color.withOpacity(0.1) : Colors.transparent) 
                  : null,
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.gradient != null 
                    ? Colors.transparent 
                    : color.withOpacity(widget.isPrimary ? 0.8 : 0.3),
                  width: 1,
                ),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon!, color: widget.gradient != null ? Colors.white : color, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    displayLabel,
                    style: TextStyle(
                      color: widget.gradient != null ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
