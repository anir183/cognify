import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.post('/api/verify-reset-otp', {
        'email': widget.email,
        'code': _otp,
      });

      if (mounted) {
        // Navigate to reset password screen
        context.go('/reset-password', extra: {'email': widget.email});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    try {
      await ApiService.post('/api/forgot-password', {'email': widget.email});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/forgot-password'),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -50,
            child:
                Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryCyan.withOpacity(0.2),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: 20, duration: 4.seconds),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: AppTheme.primaryCyan,
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 24),
                  Text(
                    "Verify Code",
                    style: AppTheme.headlineMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    "Enter the 6-digit code sent to\n${widget.email}",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 40),

                  GlassContainer(
                        height: 220,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(24),
                        borderColor: Colors.white.withOpacity(0.1),
                        blur: 20,
                        frostedOpacity: 0.1,
                        color: AppTheme.cardColor.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: 45,
                                    child: TextFormField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      style: AppTheme.headlineMedium.copyWith(
                                        color: AppTheme.primaryCyan,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.black.withOpacity(
                                          0.5,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppTheme.primaryCyan
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryCyan,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < 5) {
                                          _focusNodes[index + 1].requestFocus();
                                        }
                                        if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyOTP,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text("VERIFY CODE"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scaleXY(begin: 0.95, end: 1),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _resendOTP,
                    child: Text(
                      "Didn't receive the code? Resend",
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
