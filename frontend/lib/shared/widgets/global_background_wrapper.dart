import 'package:flutter/material.dart';
import '../animations/ambient_background.dart';

class GlobalBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const GlobalBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // This wrapper ensures AmbientBackground is at the root and persists
    return Stack(
      children: [
        // The background sits behind everything
        const Positioned.fill(
          child: AmbientBackground(
            child: SizedBox.expand(), 
          ),
        ),
        // The actual app content (routes)
        Positioned.fill(child: child),
      ],
    );
  }
}
