import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:renizo/core/services/auth_service.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Signup state
class SignupState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  SignupState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  SignupState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Signup notifier
class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier() : super(SignupState());

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final response = await AuthService.signup(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      if (response.status == 'success' && response.data != null) {
        // Save session to local storage
        await AuthLocalStorage.saveSession(
          token: response.data!.tokens.accessToken,
          email: response.data!.user.email,
          userId: response.data!.user.id,
          name: response.data!.user.fullName,
          role: response.data!.user.role,
          phone: response.data!.user.phone,
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
          isSuccess: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  void reset() {
    state = SignupState();
  }
}

/// Signup provider
final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>(
  (ref) => SignupNotifier(),
);

/// Login state
class LoginState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  LoginState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Login notifier – calls AuthService.login, saves session, UI navigates by role
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(LoginState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response.status == 'success' && response.data != null) {
        await AuthLocalStorage.saveSession(
          token: response.data!.tokens.accessToken,
          email: response.data!.user.email,
          userId: response.data!.user.id,
          name: response.data!.user.fullName,
          role: response.data!.user.role,
          phone: response.data!.user.phone,
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
          isSuccess: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  void reset() {
    state = LoginState();
  }
}

/// Login provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(),
);
