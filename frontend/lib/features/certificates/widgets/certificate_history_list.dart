import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_state.dart';
import 'revocation_panel.dart'; // Import RevocationPanel
import 'package:intl/intl.dart';

class CertificateHistoryList extends ConsumerStatefulWidget {
  const CertificateHistoryList({super.key});

  @override
  ConsumerState<CertificateHistoryList> createState() => _CertificateHistoryListState();
}

class _CertificateHistoryListState extends ConsumerState<CertificateHistoryList> {
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      final walletAddress = authState.walletAddress;

      if (walletAddress == null) {
        setState(() {
          _error = 'No wallet connected';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.get(
        '/api/instructor/certificates?wallet=$walletAddress',
      );

      if (response['success'] == true) {
        setState(() {
          _certificates = List<Map<String, dynamic>>.from(
            response['certificates'] ?? [],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load certificates';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM d, y').format(parsedDate);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatHash(String? hash) {
    if (hash == null || hash.length < 10) return hash ?? 'N/A';
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppTheme.primaryCyan),
            const SizedBox(width: 8),
            Text(
              "Issued Certificates",
              style: AppTheme.headlineMedium.copyWith(fontSize: 18),
            ),
            const Spacer(),
            Icon(
              Icons.lock_outline,
              color: AppTheme.primaryCyan.withOpacity(0.5),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              "Protected on Chain",
              style: TextStyle(
                color: AppTheme.primaryCyan.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: AppTheme.primaryCyan,
              ),
            ),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchCertificates,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_certificates.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: AppTheme.textGrey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No certificates issued yet',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start issuing certificates to your students',
                    style: TextStyle(
                      color: AppTheme.textGrey.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _certificates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cert = _certificates[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert['courseName'] ?? 'Unknown Course',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cert['studentName'] ?? 'Unknown Student',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cert['marks'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryCyan.withOpacity(0.3),
                                  AppTheme.accentPurple.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cert['marks']}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(cert['issuedAt']),
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.link,
                          size: 12,
                          color: AppTheme.accentPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatHash(cert['hash']),
                          style: TextStyle(
                            color: AppTheme.accentPurple.withOpacity(0.8),
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (cert['trustScore'] != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 12,
                            color: AppTheme.primaryCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trust Score: ${cert['trustScore']}',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 12,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cert['verificationCount'] ?? 0} verifications',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement PDF download
                            },
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("PDF"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Open in blockchain explorer
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text("Explorer"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryCyan,
                              side: BorderSide(
                                color: AppTheme.primaryCyan.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        // Revoke Button
                         const SizedBox(width: 8),
                         IconButton(
                          icon: const Icon(Icons.block, color: Colors.redAccent, size: 20),
                          tooltip: "Revoke Certificate",
                          onPressed: () {
                             showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: RevocationPanel(
                                    certificateHash: cert['hash'],
                                    studentName: cert['studentName'] ?? 'Unknown',
                                    onRevoked: _fetchCertificates,
                                  ),
                                ),
                              );
                          },
                         ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    delay: Duration(milliseconds: 100 * index),
                  )
                  .fadeIn();
            },
          ),
      ],
    );
  }
}
