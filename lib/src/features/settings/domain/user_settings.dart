import 'package:equatable/equatable.dart';

enum ThemeModePreference { system, light, dark }

ThemeModePreference themeModePreferenceFromString(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeModePreference.light;
    case 'dark':
      return ThemeModePreference.dark;
    default:
      return ThemeModePreference.system;
  }
}

String themeModePreferenceToString(ThemeModePreference mode) {
  switch (mode) {
    case ThemeModePreference.light:
      return 'light';
    case ThemeModePreference.dark:
      return 'dark';
    case ThemeModePreference.system:
      return 'system';
  }
}

class UserSettings extends Equatable {
  const UserSettings({
    this.readReceipts = true,
    this.secretChatDefaultOn = true,
    this.themeMode = ThemeModePreference.system,
  });

  final bool readReceipts;
  final bool secretChatDefaultOn;
  final ThemeModePreference themeMode;

  UserSettings copyWith({
    bool? readReceipts,
    bool? secretChatDefaultOn,
    ThemeModePreference? themeMode,
  }) {
    return UserSettings(
      readReceipts: readReceipts ?? this.readReceipts,
      secretChatDefaultOn: secretChatDefaultOn ?? this.secretChatDefaultOn,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'readReceipts': readReceipts,
      'secretChatDefaultOn': secretChatDefaultOn,
      'themeMode': themeModePreferenceToString(themeMode),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserSettings();
    return UserSettings(
      readReceipts: map['readReceipts'] as bool? ?? true,
      secretChatDefaultOn: map['secretChatDefaultOn'] as bool? ?? true,
      themeMode: themeModePreferenceFromString(map['themeMode'] as String?),
    );
  }

  @override
  List<Object?> get props => [readReceipts, secretChatDefaultOn, themeMode];
}
