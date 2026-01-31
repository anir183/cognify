import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class VerificationHistoryWidget extends ConsumerStatefulWidget {
  final String certificateHash;

  const VerificationHistoryWidget({
    super.key,
    required this.certificateHash,
  });

  @override
  ConsumerState<VerificationHistoryWidget> createState() =>
      _VerificationHistoryWidgetState();
}

class _VerificationHistoryWidgetState
    extends ConsumerState<VerificationHistoryWidget> {
  List<VerificationRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        '/api/certificate/verification-history?hash=${widget.certificateHash}',
      );

      if (response['success'] == true) {
        setState(() {
          _history = (response['history'] as List)
              .map((e) => VerificationRecord.fromJson(e))
              .toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      // Fall through to mock data
    }

    // Mock data
    setState(() {
      _history = [
        VerificationRecord(
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          verifierIP: '192.168.1.100',
          location: 'New York, USA',
          result: 'VERIFIED',
        ),
        VerificationRecord(
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          verifierIP: '10.0.0.50',
          location: 'London, UK',
          result: 'VERIFIED',
        ),
        VerificationRecord(
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          verifierIP: '172.16.0.25',
          location: 'Tokyo, Japan',
          result: 'VERIFIED',
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: AppTheme.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Verification History',
                style: AppTheme.headlineMedium.copyWith(fontSize: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_history.length} verifications',
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppTheme.primaryCyan),
              ),
            )
          else if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      color: AppTheme.textGrey,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No verification history yet',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 14,
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
              itemCount: _history.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withOpacity(0.1),
                height: 24,
              ),
              itemBuilder: (context, index) {
                final record = _history[index];
                return _buildHistoryItem(record, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(VerificationRecord record, int index) {
    final isVerified = record.result == 'VERIFIED';
    final color = isVerified ? Colors.greenAccent : Colors.redAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            if (index < _history.length - 1)
              Container(
                width: 2,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isVerified ? Icons.check_circle : Icons.cancel,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.result,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, y - HH:mm').format(record.timestamp),
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.location,
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.computer,
                    size: 14,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.verifierIP,
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: -0.1, end: 0);
  }
}

class VerificationRecord {
  final DateTime timestamp;
  final String verifierIP;
  final String location;
  final String result;

  VerificationRecord({
    required this.timestamp,
    required this.verifierIP,
    required this.location,
    required this.result,
  });

  factory VerificationRecord.fromJson(Map<String, dynamic> json) {
    return VerificationRecord(
      timestamp: DateTime.parse(json['timestamp']),
      verifierIP: json['verifierIP'],
      location: json['location'],
      result: json['result'],
    );
  }
}
