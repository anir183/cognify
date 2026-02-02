import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

import '../widgets/academic_trust_engine.dart';
import 'qr_scanner_screen.dart';

class CertificateVerificationScreen extends StatefulWidget {
  final String? initialHash;

  const CertificateVerificationScreen({
    super.key,
    this.initialHash,
  });

  @override
  State<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends State<CertificateVerificationScreen> {
  late final TextEditingController _hashController;

  @override
  void initState() {
    super.initState();
    _hashController = TextEditingController(text: widget.initialHash ?? '');
  }
  bool _isLoading = false;
  Map<String, dynamic>? _verificationResult;
  bool _showDebug = false;

  // Mock Global Stats
  int _totalIssued = 12450;
  int _totalVerified = 8932;
  int _fraudBlocked = 142;

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificate() async {
    setState(() {
      _isLoading = true;
      _verificationResult = null;
    });

    // Simulate API Call
    await Future.delayed(const Duration(seconds: 2));

    // Mock Response
    setState(() {
      _isLoading = false;
      // For demo purposes, if hash is empty or "fail", show fake. Else verified.
      bool isFake = _hashController.text.toLowerCase().contains("fake");

      if (isFake) {
        _verificationResult = {
          "status": "FAKE",
          "message": "Certificate hash not found in blockchain ledger.",
          "timestamp": DateTime.now().toIso8601String(),
        };
        _fraudBlocked++; // Live update stat
      } else {
        _verificationResult = {
          "status": "VERIFIED",
          "studentName": "Alex Rivera",
          "courseName": "Advanced AI Architecture & Neural Networks",
          "issuer": "Cognify University",
          "walletAddress": "0x71C...9A23",
          "issueDate": DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
          "txHash": "0x8f2d...3k92",
          "trustScore": 98,
          "ipfsHash": "QmXyZ...2h9A",
        };
        _totalVerified++; // Live update stat
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Deep Navy/Black
      body: Stack(
        children: [
          // Ambient Background Particles
          const _AmbientBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 40),

                  // Main Verification Panel
                  _buildVerificationPanel(),
                  const SizedBox(height: 32),

                  // Result Panel (Animated In)
                  if (_verificationResult != null) ...[
                    _buildResultPanel()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
                    const SizedBox(height: 32),
                  ],

                  // Global Stats Panel
                  _buildGlobalStats(),
                  const SizedBox(height: 32),

                  // Toggle Debug
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showDebug = !_showDebug),
                      child: Text(
                        _showDebug ? "Hide Debug Console" : "Show System Logs",
                        style: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ),

                  if (_showDebug) _buildDebugPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CERTIFICATE ENGINE",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
            Text(
              "Blockchain Verification",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationPanel() {
    return _GlassCard(
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 48, color: Colors.cyanAccent),
          const SizedBox(height: 16),
          Text(
            "Verify Academic Authenticity",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Upload certificate or enter blockchain hash",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Upload Button
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Mock file picker
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: Colors.purpleAccent, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "Click to Upload PDF",
                      style: TextStyle(color: Colors.purpleAccent.shade100),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: Colors.white.withOpacity(0.3))),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            ],
          ),
          const SizedBox(height: 24),

          // Input Field
          TextField(
            controller: _hashController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
            decoration: InputDecoration(
              hintText: "Enter Certificate Hash ID",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.tag, color: Colors.cyanAccent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QRScannerScreen(
                        onScanned: (code) {
                          _hashController.text = code;
                          _verifyCertificate();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          "VERIFY NOW",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ).animate(target: _isLoading ? 0 : 1).shimmer(duration: 2.seconds),
        ],
      ),
    );
  }


  Widget _buildResultPanel() {
    final bool isVerified = _verificationResult!['status'] == 'VERIFIED';
    final Color statusColor = isVerified ? const Color(0xFF00FF9D) : const Color(0xFFFF2E2E);
    final int trustScore = _verificationResult!['trustScore'] ?? 0;

    return _GlassCard(
      borderColor: statusColor.withOpacity(0.5),
      child: Column(
        children: [
          // New Academic Trust Engine Widget
          if (isVerified)
            AcademicTrustEngine(
              trustScore: trustScore,
              isVerified: isVerified,
              globalVerifiedCount: "12,450", // You could bind this to state variable
            ),
          
          if (!isVerified) ...[
             const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
             Text(
              "Verification Failed",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
             Text(
              _verificationResult!['message'],
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],

          const SizedBox(height: 24),

          if (isVerified) ...[
            _buildDetailRow("Student Name", _verificationResult!['studentName']),
            _buildDetailRow("Course", _verificationResult!['courseName']),
            _buildDetailRow("Issuer", _verificationResult!['issuer']),
            _buildDetailRow("Issue Date", 
              DateFormat.yMMMd().format(DateTime.parse(_verificationResult!['issueDate']))
            ),
            const Divider(color: Colors.white12, height: 32),
            _buildBlockchainInfo(),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text("Blockchain Record", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _verificationResult!['txHash'],
            style: GoogleFonts.firaCode(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text("View on Explorer"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGlobalStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Issued", _totalIssued, Colors.blueAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Verified", _totalVerified, Colors.purpleAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Blocked", _fraudBlocked, Colors.redAccent)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.compact().format(value),
            style: GoogleFonts.orbitron(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          )
              .animate(key: ValueKey(value))
              .scale(duration: 300.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text("DEBUG TERMINAL >_", style: GoogleFonts.firaCode(color: Colors.greenAccent)),
            const Divider(color: Colors.white24),
            Text("[LOG] System initialized at ${DateTime.now()}", style: GoogleFonts.firaCode(color: Colors.green, fontSize: 10)),
            if (_verificationResult != null)
              Text("[API] Response: $_verificationResult", style: GoogleFonts.firaCode(color: Colors.yellow, fontSize: 10)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.purple.withOpacity(0.3), Colors.purple.withOpacity(0.05)],
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 5.seconds),
        
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.cyan.withOpacity(0.2), Colors.cyan.withOpacity(0.05)],
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
          begin: 0, end: -50, duration: 7.seconds),
      ],
    );
  }
}
