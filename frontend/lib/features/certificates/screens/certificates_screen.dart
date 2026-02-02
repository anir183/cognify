import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart'; // FIXED: Added import
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';
import '../../../shared/animations/breathing_card.dart';
import '../../../shared/animations/animated_neon_button.dart';
import '../../../shared/animations/holographic_shimmer.dart';
import '../../../shared/widgets/academic_dna_card.dart'; // NEW
import '../student_certificate_vault.dart'; // NEW
import '../widgets/academic_dna_widget.dart';
import '../widgets/certificate_history_list.dart';
import '../../../core/providers/auth_state.dart';
import '../../../core/providers/user_state.dart'; // NEW
import '../../../shared/animations/ambient_background.dart';
import '../widgets/certificate_generation_card.dart';
import '../widgets/soulbound_identity_badge.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isInstructor = authState.role == 'instructor';
    return Scaffold(
      backgroundColor: AppTheme.bgBlack,
      appBar: AppBar(
        title: Text('Certificates', style: AppTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AmbientBackground(
        child: AppAnimations.pageTransitionWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
            const SizedBox(height: 16),
            
            // Academic DNA Identity - Show for both students and instructors
            Consumer(
              builder: (context, ref, _) {
                final userState = ref.watch(userStateProvider);
                
                if (authState.walletAddress == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Please connect your wallet to view your Academic DNA',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                return AcademicDNACard(
                  academicDNA: authState.walletAddress!,
                  studentName: userState.profile.name.isNotEmpty 
                    ? userState.profile.name 
                    : (isInstructor ? 'Instructor' : 'Student'),
                  walletAddress: authState.walletAddress!,
                  generatedAt: DateTime.now(),
                  role: isInstructor ? 'Instructor' : 'Student',
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
              },
            ),
            const SizedBox(height: 24),

                // Certificate Vault
                if (authState.walletAddress != null) ...[
                  if (!isInstructor)
                    StudentCertificateVault(
                      walletAddress: authState.walletAddress!,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    
                  if (isInstructor)
                     const CertificateHistoryList(), // Keep for instructor for now
                ] else ...[
                   Center(
                     child: Text(
                       "Connect Wallet to view certificates",
                       style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey),
                     ),
                   )
                ],
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

