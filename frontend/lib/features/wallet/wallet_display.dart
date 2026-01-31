import 'package:flutter/material.dart';
import '../../core/services/metamask_service.dart';

/// Wallet display widget for app bar
class WalletDisplay extends StatelessWidget {
  final VoidCallback? onDisconnect;
  
  const WalletDisplay({
    Key? key,
    this.onDisconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metamaskService = MetaMaskService();
    final wallet = metamaskService.connectedWallet;
    
    if (wallet == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            MetaMaskService.formatAddress(wallet),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDisconnect != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDisconnect,
              child: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
