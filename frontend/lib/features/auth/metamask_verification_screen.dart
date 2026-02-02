import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/metamask_service.dart';
import '../../core/providers/auth_state.dart';
import '../../core/providers/user_state.dart';
import '../../shared/animations/ambient_background.dart';

class MetaMaskVerificationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra; // Might receive email/role from login

  const MetaMaskVerificationScreen({super.key, this.extra});

  @override
  ConsumerState<MetaMaskVerificationScreen> createState() => _MetaMaskVerificationScreenState();
}

class _MetaMaskVerificationScreenState extends ConsumerState<MetaMaskVerificationScreen> {
  final _metamaskService = MetaMaskService();
  String _statusMessage = "Initializing Web3 Identity...";
  String _walletAddress = "";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger verification after a short delay for animation
    Future.delayed(const Duration(seconds: 2), _startVerification);
  }

  Future<void> _startVerification() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = "Connecting to MetaMask...";
    });

    try {
      if (!_metamaskService.isMetaMaskInstalled) {
        throw Exception("MetaMask is not installed on your device.");
      }

      // 1. Connect Wallet
      final wallet = await _metamaskService.connectWallet();
      if (wallet == null) throw Exception("Wallet connection rejected.");
      
      if (mounted) {
        setState(() {
          _walletAddress = "${wallet.substring(0, 6)}...${wallet.substring(38)}";
          _statusMessage = "Verifying Signature...";
        });
      }

      // 2. Sign Challenge (Authenticate)
      String role = widget.extra?['role'] ?? 'student';
      String email = widget.extra?['email'] ?? 'User';

      final result = await _metamaskService.authenticate(
        studentName: email,
        role: role,
        email: email, // Passed to enable wallet linking on backend
      );

      if (result != null && result['success'] == true) {
        if (mounted) {
          setState(() {
            _statusMessage = "Identity Verified. Access Granted.";
          });
          
          // 3. Update Global Auth State
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.login(
            result['token'] ?? '',
            role: result['role'] ?? role,
            walletAddress: wallet,
          );

          // 3b. Update User Profile State (CRITICAL for Dashboard)
          if (result['user'] != null) {
             final userNotifier = ref.read(userStateProvider.notifier);
             userNotifier.setUser(result['user']);
          }

          // 4. Redirect to Shell Routes (enables full navigation)
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            if (result['role'] == 'instructor') {
              context.go('/instructor/dashboard');
            } else {
              context.go('/dashboard');
            }
          }
        }
      } else {
        throw Exception("Signature verification failed.");
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isError = false;
      _statusMessage = "Retrying Connection...";
    });
    _startVerification();
  }

  void _backToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBlack,
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dual Identity Shield Animation
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shield Background
                    Icon(
                      Icons.shield_outlined,
                      size: 180,
                      color: _isError ? Colors.red : AppTheme.primaryCyan.withOpacity(0.3),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .fadeIn(duration: 500.ms), // Removed problematic boxShadow for stability

                    // Email Identity (Fading Out/Merging)
                    if (!_isError)
                      const Icon(Icons.email, color: Colors.white, size: 60)
                          .animate()
                          .slide(begin: const Offset(-2, 0), end: const Offset(0, 0), duration: 1000.ms, curve: Curves.easeOut)
                          .fadeOut(delay: 800.ms, duration: 500.ms),

                    // Wallet Identity (Fading In/Merging)
                    if (!_isError)
                      const Icon(Icons.account_balance_wallet, color: AppTheme.accentPurple, size: 60)
                          .animate()
                          .slide(begin: const Offset(2, 0), end: const Offset(0, 0), duration: 1000.ms, curve: Curves.easeOut)
                          .fadeIn(duration: 500.ms),

                    // Final Merged Lock/Check (After Merge)
                    if (!_isError)
                       Icon(Icons.verified_user, color: AppTheme.primaryCyan, size: 80)
                          .animate(delay: 1200.ms)
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
                    
                    // Error Icon
                    if (_isError)
                      const Icon(Icons.error_outline, color: Colors.red, size: 80)
                          .animate()
                          .shake(),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Glass Status Panel
              GlassContainer(
                height: 180,
                width: 340,
                borderRadius: BorderRadius.circular(24),
                borderColor: _isError ? Colors.red.withOpacity(0.5) : AppTheme.primaryCyan.withOpacity(0.3),
                blur: 15, // Frosted glass
                frostedOpacity: 0.1,
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isError)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Connection Failed",
                              style: AppTheme.headlineMedium.copyWith(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _statusMessage, // Now contains raw error
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _backToLogin,
                                child: const Text("Back"),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _retry, // This calls connectWallet
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryCyan,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text("Manual Connect", style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Check if a popup was blocked or is already open.",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            "Verifying Web3 Identity",
                            style: AppTheme.headlineMedium.copyWith(fontSize: 20),
                          ).animate().shimmer(duration: 2000.ms, color: AppTheme.primaryCyan),
                          
                          const SizedBox(height: 12),
                          
                          if (_walletAddress.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
                              ),
                              child: Text(
                                _walletAddress,
                                style: TextStyle(color: AppTheme.primaryCyan, fontFamily: 'Courier'),
                              ),
                            ).animate().fadeIn(),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.grey),
                          ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).fadeOut(delay: 800.ms),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
