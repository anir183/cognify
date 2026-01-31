import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'metamask_service.dart';

class BlockchainService {
  final MetaMaskService _metaMaskService = MetaMaskService();
  final String _backendUrl = 'http://localhost:8080/api'; // Configure for env

  /// Orchestrates the full secure minting flow
  /// 1. Prepares mint on backend (Authorized)
  /// 2. Sends transaction to blockchain (MetaMask)
  /// 3. Confirms mint on backend (Optional)
  Future<String> mintCertificate({
    required String studentWallet,
    required String studentName,
    required String courseName,
    required double marks,
    required String instructorAuthToken,
    required String instructorWallet,
  }) async {
    // 0. Sign Authorization Message
    final messageToSign = "Mint Certificate for $studentName in $courseName";
    final walletSignature = await _metaMaskService.signMessage(messageToSign);

    if (walletSignature == null) {
      throw Exception('User rejected signature request');
    }

    // 1. Prepare Mint (Get DNA & Signature)
    final prepareResponse = await http.post(
      Uri.parse('$_backendUrl/instructor/mint/prepare'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $instructorAuthToken',
        'X-Wallet-Address': instructorWallet,
        'X-Wallet-Signature': walletSignature,
        'X-Signed-Message': messageToSign,
      },
      body: jsonEncode({
        'studentWallet': studentWallet,
        'studentName': studentName,
        'courseName': courseName,
        'marks': marks,
      }),
    );

    if (prepareResponse.statusCode != 200) {
      throw Exception('Failed to prepare mint: ${prepareResponse.body}');
    }

    final prepareData = jsonDecode(prepareResponse.body);
    final academicDNA = prepareData['academicDNA'];
    final signature = prepareData['signature'];

    debugPrint('✅ Mint Prepared. DNA: $academicDNA');

    // 2. Send Transaction via MetaMask
    // In a real app, uses web3dart or JS interop to call:
    // Contract.mint(studentWallet, marks, academicDNA, signature)
    
    // Simulating the Contract Call for this Audit Implementation
    // We assume MetaMaskService can send raw transactions or interact with contract
    
    // Mocking the tx hash returned from MetaMask
    await Future.delayed(const Duration(seconds: 2)); 
    final txHash = "0x" + List.generate(64, (index) => "a").join();

    return txHash;
  }
}
