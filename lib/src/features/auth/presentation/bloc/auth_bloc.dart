import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:chat_app/src/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required ObserveAuthStateUseCase observeAuthStateUseCase,
    required SendPhoneOtpUseCase sendPhoneOtpUseCase,
    required VerifyPhoneOtpUseCase verifyPhoneOtpUseCase,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _observeAuthStateUseCase = observeAuthStateUseCase,
        _sendPhoneOtpUseCase = sendPhoneOtpUseCase,
        _verifyPhoneOtpUseCase = verifyPhoneOtpUseCase,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthStatusChanged>(_onStatusChanged);
    on<SignInRequested>(_onSignIn);
    on<SignUpRequested>(_onSignUp);
    on<SignOutRequested>(_onSignOut);
    on<PhoneOtpRequested>(_onPhoneOtpRequested);
    on<PhoneOtpSubmitted>(_onPhoneOtpSubmitted);
  }

  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final ObserveAuthStateUseCase _observeAuthStateUseCase;
  final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;

  StreamSubscription<AppUser?>? _authSub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSub?.cancel();
    _authSub = _observeAuthStateUseCase().listen(
      (user) => add(AuthStatusChanged(user)),
    );
  }

  void _onStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    } else {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    }
  }

  Future<void> _onSignIn(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSignUp(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
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
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: e.toString(),
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

  Future<void> _onPhoneOtpRequested(
    PhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null, otpSent: false));
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
          message: e.toString(),
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
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
