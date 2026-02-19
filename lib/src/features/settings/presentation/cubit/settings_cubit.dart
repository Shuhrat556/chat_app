import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/settings/domain/settings_repository.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required SettingsRepository settingsRepository,
    required FirebaseAuth firebaseAuth,
  }) : _settingsRepository = settingsRepository,
       _firebaseAuth = firebaseAuth,
       super(const SettingsState());

  final SettingsRepository _settingsRepository;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription? _settingsSub;

  Future<void> start() async {
    await _settingsSub?.cancel();
    await _authSub?.cancel();

    await _handleUser(_firebaseAuth.currentUser);
    _authSub = _firebaseAuth.authStateChanges().listen(_handleUser);
  }

  Future<void> _handleUser(User? user) async {
    await _settingsSub?.cancel();
    if (user == null) {
      emit(
        state.copyWith(
          status: SettingsStatus.ready,
          settings: const SettingsState().settings,
          message: null,
        ),
      );
      return;
    }

    emit(state.copyWith(status: SettingsStatus.loading, message: null));
    try {
      final initial = await _settingsRepository.getSettings(userId: user.uid);
      emit(
        state.copyWith(
          status: SettingsStatus.ready,
          settings: initial,
          message: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          message: 'settings_load_failed',
        ),
      );
    }

    _settingsSub = _settingsRepository
        .watchSettings(userId: user.uid)
        .listen(
          (settings) {
            emit(
              state.copyWith(
                status: SettingsStatus.ready,
                settings: settings,
                message: null,
              ),
            );
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: SettingsStatus.error,
                message: 'settings_stream_failed',
              ),
            );
          },
        );
  }

  Future<void> setReadReceipts(bool enabled) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final next = state.settings.copyWith(readReceipts: enabled);
    emit(state.copyWith(status: SettingsStatus.ready, settings: next));
    try {
      await _settingsRepository.updateReadReceipts(
        userId: uid,
        enabled: enabled,
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          message: 'read_receipts_update_failed',
        ),
      );
    }
  }

  Future<void> setSecretChatDefault(bool enabled) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final next = state.settings.copyWith(secretChatDefaultOn: enabled);
    emit(state.copyWith(status: SettingsStatus.ready, settings: next));
    try {
      await _settingsRepository.updateSecretChatDefaultOn(
        userId: uid,
        enabled: enabled,
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          message: 'secret_default_update_failed',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _settingsSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
