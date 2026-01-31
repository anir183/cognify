import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MetaMask wallet service for Web3 authentication (Web-only)
/// Uses JavaScript interop to communicate with MetaMask browser extension
class MetaMaskService {
  static const String _walletKey = 'connected_wallet';
  static const String _userKey = 'user_data';
  
  String? _connectedWallet;
  
  // Singleton pattern
  static final MetaMaskService _instance = MetaMaskService._internal();
  factory MetaMaskService() => _instance;
  MetaMaskService._internal();
  
  /// Initialize service
  Future<void> initialize() async {
    await _loadSavedWallet();
  }
  
  /// Check if MetaMask is installed
  bool get isMetaMaskInstalled {
    if (!kIsWeb) return false;
    try {
      return js_util.hasProperty(html.window, 'ethereum');
    } catch (e) {
      return false;
    }
  }
  
  /// Connect to MetaMask wallet
  Future<String?> connectWallet() async {
    if (!kIsWeb) {
      throw UnsupportedError('MetaMask is only supported on web');
    }
    
    if (!isMetaMaskInstalled) {
      throw Exception('MetaMask is not installed');
    }
    
    try {
      // Request accounts from MetaMask
      final accounts = await _callEthereumMethod('eth_requestAccounts', []);
      
      if (accounts != null && accounts is List && accounts.isNotEmpty) {
        _connectedWallet = accounts[0] as String;
        await _saveWallet(_connectedWallet!);
        return _connectedWallet;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
      throw Exception('MetaMask Error: $e');
    }
  }

  /// Listen for account changes
  void listenToAccountChanges(Function(String?) onAccountChanged) {
    if (!kIsWeb) return;

    try {
      final ethereum = js_util.getProperty(html.window, 'ethereum');
      if (ethereum == null) return;

      // Define standard JS callback
      final callback = js.allowInterop((List<dynamic> accounts) {
        if (accounts.isEmpty) {
          onAccountChanged(null); // Disconnected
        } else {
          onAccountChanged(accounts[0]); // Switched account
        }
      });

      js_util.callMethod(ethereum, 'on', ['accountsChanged', callback]);
    } catch (e) {
      debugPrint('Error setting up account listener: $e');
    }
  }
  
  /// Sign authentication message
  Future<String?> signMessage(String message) async {
    if (_connectedWallet == null) {
      throw Exception('Wallet not connected');
    }
    
    if (!kIsWeb) {
      throw UnsupportedError('MetaMask is only supported on web');
    }
    
    try {
      // Hex-encode the message for personal_sign
      final hexMessage = _toHex(message);

      final signature = await _callEthereumMethod('personal_sign', [
        hexMessage,
        _connectedWallet,
      ]);
      
      return signature as String?;
    } catch (e) {
      debugPrint('Error signing message: $e');
      return null;
    }
  }

  /// Helper to convert string to hex with 0x prefix
  String _toHex(String input) {
    if (input.startsWith('0x')) return input;
    return '0x${input.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
  }
  
  /// Authenticate with backend using wallet signature
  Future<Map<String, dynamic>?> authenticate({
    required String studentName,
    String? email,
    String? role,
  }) async {
    if (_connectedWallet == null) {
      throw Exception('Wallet not connected');
    }
    
    try {
      // 1. Get Nonce from Backend
      final nonceResponse = await http.post(
        Uri.parse('http://localhost:8080/api/auth/nonce'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'walletAddress': _connectedWallet}),
      );

      if (nonceResponse.statusCode != 200) {
        throw Exception('Failed to get nonce from backend');
      }

      final nonceData = jsonDecode(nonceResponse.body);
      final messageToSign = nonceData['message'];

      // 2. Sign the Nonce Message
      final signature = await signMessage(messageToSign);
      if (signature == null) {
        return null;
      }
      
      // 3. Send Signature to Backend
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/login/wallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'walletAddress': _connectedWallet,
          'signature': signature,
          'email': email, // Pass email for 2FA linking
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserData(data);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Authentication failed');
      }
      
    } catch (e) {
      debugPrint('Error authenticating: $e');
      rethrow; // Rethrow to show error in UI
    }
  }
  
  /// Disconnect wallet
  Future<void> disconnect() async {
    _connectedWallet = null;
    await _clearSavedData();
  }
  
  /// Get connected wallet address
  String? get connectedWallet => _connectedWallet;
  
  /// Check if wallet is connected
  bool get isConnected => _connectedWallet != null;
  
  Future<dynamic> _callEthereumMethod(String method, List<dynamic> params) async {
    if (!kIsWeb) return null;

    try {
      // Access 'ethereum' from explicit window object
      final ethereum = js_util.getProperty(html.window, 'ethereum');
      
      if (ethereum == null) {
         throw Exception("MetaMask is not detected.");
      }

      // Construct the request object using js_util
      final requestObj = js_util.newObject();
      js_util.setProperty(requestObj, 'method', method);
      js_util.setProperty(requestObj, 'params', js_util.jsify(params));

      // Call 'request' method
      final promise = js_util.callMethod(ethereum, 'request', [requestObj]);

      // Convert Promise to Future
      return await js_util.promiseToFuture(promise);
    } catch (e) {
      debugPrint('Error calling Ethereum method: $e');
      // Unwrap JS errors if possible
      throw Exception('MetaMask Error: $e');
    }
  }
  
  /// Save wallet address to local storage
  Future<void> _saveWallet(String wallet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletKey, wallet.toLowerCase());
  }
  
  /// Load saved wallet from local storage
  Future<void> _loadSavedWallet() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedWallet = prefs.getString(_walletKey);
  }
  
  /// Save user data to local storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }
  
  /// Get saved user data
  Future<Map<String, dynamic>?> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }
  
  /// Clear all saved data
  Future<void> _clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletKey);
    await prefs.remove(_userKey);
  }
  
  /// Format wallet address for display (0x1234...5678)
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
