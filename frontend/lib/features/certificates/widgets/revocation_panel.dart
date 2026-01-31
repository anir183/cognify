import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_state.dart';
import '../../../core/services/api_service.dart';

class RevocationPanel extends ConsumerStatefulWidget {
  final String certificateHash;
  final String studentName;
  final VoidCallback onRevoked;

  const RevocationPanel({
    super.key,
    required this.certificateHash,
    required this.studentName,
    required this.onRevoked,
  });

  @override
  ConsumerState<RevocationPanel> createState() => _RevocationPanelState();
}

class _RevocationPanelState extends ConsumerState<RevocationPanel> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _revokeCertificate() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Direct Blockchain Call would go here via Web3Client
      // For now, in "Mock Mode" or if using backend relay (which user suggested in prompt part 4?)
      // User said: "Smart contract revokeCertificate function... Backend revoke API endpoint"
      // If we use backend endpoint:
      
      final response = await ApiService.post(
        '/api/certificate/revoke',
        {
          'hash': widget.certificateHash,
          'reason': _reasonController.text,
        },
      );
      
      if (response['success'] == true) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate Revoked Successfully'),
            backgroundColor: Colors.redAccent,
          ),
        );
        widget.onRevoked();
        Navigator.of(context).pop();
      } else {
        throw Exception(response['message']);
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revoke: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a0000), // Dark Red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                'Revoke Certificate',
                style: GoogleFonts.orbitron(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This action is irreversible. The certificate for ${widget.studentName} will be permanently marked as REVOKED on the blockchain.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Reason for Revocation",
              labelStyle: TextStyle(color: Colors.redAccent.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _revokeCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("CONFIRM REVOCATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
