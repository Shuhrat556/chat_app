import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/core/theme/theme_state.dart';
import 'package:chat_app/src/features/settings/domain/settings_repository.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required SettingsRepository settingsRepository,
    required FirebaseAuth firebaseAuth,
  }) : _settingsRepository = settingsRepository,
       _firebaseAuth = firebaseAuth,
       super(const ThemeState());

  final SettingsRepository _settingsRepository;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<User?>? _authSub;

  Future<void> start() async {
    await _authSub?.cancel();
    await _loadTheme();
    _authSub = _firebaseAuth.authStateChanges().listen((_) {
      unawaited(_loadTheme());
    });
  }

  Future<void> _loadTheme() async {
    final userId = _firebaseAuth.currentUser?.uid;
    final mode = await _settingsRepository.loadThemePreference(userId: userId);
    emit(state.copyWith(preference: mode, isReady: true));
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    if (mode == state.preference) return;
    emit(state.copyWith(preference: mode, isReady: true));
    final userId = _firebaseAuth.currentUser?.uid;
    await _settingsRepository.saveThemePreference(mode: mode, userId: userId);
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }
}
