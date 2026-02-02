import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart'; // ADDED for context.push
import '../../shared/animations/breathing_card.dart';
import '../../shared/animations/animated_neon_button.dart';

/// Student Certificate Vault - Protected view of student's certificates
class StudentCertificateVault extends StatefulWidget {
  final String walletAddress;
  
  const StudentCertificateVault({
    Key? key,
    required this.walletAddress,
  }) : super(key: key);

  @override
  State<StudentCertificateVault> createState() => _StudentCertificateVaultState();
}

class _StudentCertificateVaultState extends State<StudentCertificateVault> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Call backend API to get certificates
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _certificates = [
          {
            'id': '1',
            'courseName': 'Advanced Blockchain Development',
            'instructorName': 'Dr. Smith',
            'marks': 95.0,
            'issuedAt': DateTime.now().subtract(const Duration(days: 30)),
            'blockchainTx': '0xabc123...',
            'trustScore': 98,
          },
          {
            'id': '2',
            'courseName': 'Smart Contract Security',
            'instructorName': 'Prof. Johnson',
            'marks': 88.0,
            'issuedAt': DateTime.now().subtract(const Duration(days: 60)),
            'blockchainTx': '0xdef456...',
            'trustScore': 95,
          },
        ];
      });
    } catch (e) {
      _showError('Failed to load certificates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Certificate Vault',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_certificates.length} certificates',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: _loadCertificates,
              icon: Icon(
                Icons.refresh,
                color: const Color(0xFF6366F1),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms),
        
        const SizedBox(height: 24),
        
        // Certificates List
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          )
        else if (_certificates.isEmpty)
          _buildEmptyState()
        else
          ..._certificates.asMap().entries.map((entry) {
            final index = entry.key;
            final cert = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCertificateCard(cert)
                  .animate(delay: (index * 100).ms)
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: 0.2, end: 0),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      height: 200,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      blur: 20,
      frostedOpacity: 0.1,
      color: const Color(0xFF1E293B).withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              color: Colors.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No certificates yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6), // Increased opacity for better visibility
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name and trust score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cert['courseName'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cert['trustScore']}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 20),
          
          // QR Code & Actions Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Details Column
              Expanded(
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person, 'Instructor', cert['instructorName']),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.grade, 'Score', '${cert['marks']}%'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.calendar_today, 'Issued', _formatDate(cert['issuedAt'])),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.link, 'Blockchain', cert['blockchainTx']),
                  ],
                ),
              ),
              
              // Unique QR Code
              Container(
                margin: const EdgeInsets.only(left: 16, bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: cert['blockchainTx'],
                  version: QrVersions.auto,
                  size: 80.0,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: AnimatedNeonButton(
                  text: 'Download PDF',
                  icon: Icons.download,
                  onPressed: () {
                    // Placeholder for PDF download
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading Certificate PDF...'),
                        backgroundColor: Color(0xFF6366F1),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedNeonButton(
                  text: 'Verify',
                  icon: Icons.verified_user,
                  onPressed: () {
                    // Navigate to verification with hash
                    context.push(
                      '/certificate-verification',
                      extra: {'hash': cert['blockchainTx']},
                    );
                  },
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
