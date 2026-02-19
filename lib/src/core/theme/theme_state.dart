import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  const ThemeState({
    this.preference = ThemeModePreference.system,
    this.isReady = false,
  });

  final ThemeModePreference preference;
  final bool isReady;

  ThemeMode get themeMode {
    switch (preference) {
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
      case ThemeModePreference.system:
        return ThemeMode.system;
    }
  }

  ThemeState copyWith({ThemeModePreference? preference, bool? isReady}) {
    return ThemeState(
      preference: preference ?? this.preference,
      isReady: isReady ?? this.isReady,
    );
  }

  @override
  List<Object?> get props => [preference, isReady];
}
