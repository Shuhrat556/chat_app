import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:equatable/equatable.dart';

enum SettingsStatus { initial, loading, ready, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const UserSettings(),
    this.message,
  });

  final SettingsStatus status;
  final UserSettings settings;
  final String? message;

  SettingsState copyWith({
    SettingsStatus? status,
    UserSettings? settings,
    String? message,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, settings, message];
}
