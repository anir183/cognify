import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth state to track if the user is logged in.
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? token;
  final String? role;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = true,
    this.token,
    this.role,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? token,
    String? role,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuthStatus();
    return const AuthState(isLoading: true);
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('user_role');
    state = AuthState(
      isLoggedIn: token != null && token.isNotEmpty,
      isLoading: false,
      token: token,
      role: role,
    );
  }

  Future<void> login(String token, {String role = 'student'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_role', role);
    state = AuthState(
      isLoggedIn: true,
      isLoading: false,
      token: token,
      role: role,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    state = const AuthState(
      isLoggedIn: false,
      isLoading: false,
      token: null,
      role: null,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _checkAuthStatus();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
