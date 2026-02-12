import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:chat_app/src/core/notifications/notification_service.dart';
import 'package:chat_app/src/core/notifications/token_sync_service.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
    required ObserveAuthStateUseCase observeAuthStateUseCase,
    required SendPhoneOtpUseCase sendPhoneOtpUseCase,
    required VerifyPhoneOtpUseCase verifyPhoneOtpUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required TokenSyncService tokenSyncService,
  }) : _signInUseCase = signInUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signInWithAppleUseCase = signInWithAppleUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _sendPasswordResetUseCase = sendPasswordResetUseCase,
       _observeAuthStateUseCase = observeAuthStateUseCase,
       _sendPhoneOtpUseCase = sendPhoneOtpUseCase,
       _verifyPhoneOtpUseCase = verifyPhoneOtpUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _tokenSyncService = tokenSyncService,
       super(const AuthState()) {
    _tokenSyncService.startListening();
    on<AuthStarted>(_onStarted);
    on<AuthStatusChanged>(_onStatusChanged);
    on<SignInRequested>(_onSignIn);
    on<SignUpRequested>(_onSignUp);
    on<SignOutRequested>(_onSignOut);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AppleSignInRequested>(_onAppleSignIn);
    on<PasswordResetRequested>(_onPasswordReset);
    on<PhoneOtpRequested>(_onPhoneOtpRequested);
    on<PhoneOtpSubmitted>(_onPhoneOtpSubmitted);
    on<ProfileUpdateRequested>(_onProfileUpdate);
    on<DeleteAccountRequested>(_onDeleteAccount);
  }

  final SignInUseCase _signInUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithAppleUseCase _signInWithAppleUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;
  final ObserveAuthStateUseCase _observeAuthStateUseCase;
  final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final TokenSyncService _tokenSyncService;

  StreamSubscription<AppUser?>? _authSub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSub?.cancel();
    _authSub = _observeAuthStateUseCase().listen(
      (user) => add(AuthStatusChanged(user)),
    );
  }

  void _onStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    } else {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    }
  }

  Future<void> _onSignIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      await _enableNotificationsAndSyncToken();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    if (event.password != event.confirmPassword) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'password_mismatch',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _signUpUseCase(
        username: event.username,
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        photoUrl: event.photoUrl,
        bio: event.bio,
      );
      await _enableNotificationsAndSyncToken();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOutUseCase();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _signInWithGoogleUseCase();
      await _enableNotificationsAndSyncToken();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onAppleSignIn(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _signInWithAppleUseCase();
      await _enableNotificationsAndSyncToken();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await _sendPasswordResetUseCase(email: event.email);
      emit(state.copyWith(status: AuthStatus.initial, message: 'reset_sent'));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onPhoneOtpRequested(
    PhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(status: AuthStatus.loading, message: null, otpSent: false),
    );
    try {
      final verificationId = await _sendPhoneOtpUseCase(
        phoneNumber: event.phoneNumber,
      );
      emit(
        state.copyWith(
          status: AuthStatus.initial,
          verificationId: verificationId,
          otpSent: true,
          message: 'SMS yuborildi',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
          otpSent: false,
        ),
      );
    }
  }

  Future<void> _onPhoneOtpSubmitted(
    PhoneOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _verifyPhoneOtpUseCase(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        username: event.username,
      );
      await _enableNotificationsAndSyncToken();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          otpSent: false,
          verificationId: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _tokenSyncService.dispose();
    return super.close();
  }

  Future<void> _onProfileUpdate(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _updateProfileUseCase(
        username: event.username,
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        bio: event.bio,
        photoUrl: event.photoUrl,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          message: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await _deleteAccountUseCase();
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: _extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _enableNotificationsAndSyncToken() async {
    try {
      await NotificationService.requestPermissionAfterAuth();
      await _tokenSyncService.syncCurrentUserToken();
    } catch (_) {
      // Notification/token sync must not block authentication flow.
    }
  }
}

String _extractErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return error.message ?? error.code;
  }
  return error.toString();
}
