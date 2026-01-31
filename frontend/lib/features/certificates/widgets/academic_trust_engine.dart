import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

class AcademicTrustEngine extends StatelessWidget {
  final int trustScore;
  final bool isVerified;
  final String globalVerifiedCount;

  const AcademicTrustEngine({
    super.key,
    required this.trustScore,
    required this.isVerified,
    required this.globalVerifiedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACADEMIC TRUST ENGINE",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildBlockchainBadge(),
            ],
          ),
          const SizedBox(height: 24),

          // Main Visuals: Circular Score + DNA
          Row(
            children: [
              // Circular Trust Score
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: trustScore / 100),
                      duration: 1500.ms,
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          color: _getScoreColor(trustScore),
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$trustScore%",
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "TRUST",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 8,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Academic DNA Lines & Global Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DNA HASH VISUALIZATION",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDnaLines(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.public, color: Colors.purpleAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Global Verified: ",
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                          Text(
                            globalVerifiedCount,
                            style: GoogleFonts.firaCode(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFF00FF9D).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? const Color(0xFF00FF9D).withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
        boxShadow: [
          if (isVerified)
            BoxShadow(
              color: const Color(0xFF00FF9D).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.gpp_bad,
            size: 14,
            color: isVerified ? const Color(0xFF00FF9D) : Colors.red,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.2, 1.2),
            duration: 1500.ms,
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? "BLOCKCHAIN VERIFIED" : "UNVERIFIED",
            style: GoogleFonts.orbitron(
              color: isVerified ? const Color(0xFF00FF9D) : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnaLines() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          final color = index % 3 == 0 
              ? Colors.cyanAccent 
              : index % 2 == 0 
                  ? Colors.purpleAccent 
                  : Colors.blueAccent;
          
          return Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ).animate(
              onPlay: (c) => c.repeat(),
            ).custom(
              duration: Duration(milliseconds: 1000 + (index * 100)),
              builder: (context, value, child) {
                // Sine wave animation
                final height = 10 + 20 * (0.5 + 0.5 * math.sin(value * 2 * math.pi));
                return SizedBox(height: height, child: child);
              },
            ),
          );
        }),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00FF9D);
    if (score >= 70) return Colors.cyanAccent;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
