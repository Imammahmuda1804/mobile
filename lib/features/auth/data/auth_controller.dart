import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  final AuthUser? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<void> restoreSession() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).fetchMe();
      state = AuthState(user: user, isAuthenticated: true);
    } catch (_) {
      await storage.clearTokens();
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await _ref.read(secureStorageProvider).saveTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
      state = AuthState(user: session.user, isAuthenticated: true);
      return true;
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    }
  }

  void markAuthenticated() {
    state = state.copyWith(isAuthenticated: true);
  }

  void updateUser(AuthUser user) {
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  Future<void> logout() async {
    await _ref.read(secureStorageProvider).clearTokens();
    state = const AuthState();
  }
}
