import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> loginWithPhone(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2));
    // TODO: integrate Firebase Auth phone sign-in
    state = state.copyWith(
      isLoading: false,
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Utilisateur Xoho',
        phone: phone,
        role: UserRole.sender,
        kycStatus: KycStatus.none,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> logout() async {
    state = const AuthState();
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void setRole(UserRole role) {
    if (state.user == null) return;
    state = state.copyWith(user: state.user!.copyWith(role: role));
  }
}
