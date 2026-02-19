import 'package:chat_app/src/core/theme/theme_cubit.dart';
import 'package:chat_app/src/core/theme/theme_state.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_state.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          if (settingsState.status == SettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = settingsState.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                t.appearance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return Column(
                    children: [
                      RadioListTile<ThemeModePreference>(
                        value: ThemeModePreference.system,
                        groupValue: themeState.preference,
                        title: Text(t.themeSystem),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<ThemeCubit>().setThemeMode(value);
                          }
                        },
                      ),
                      RadioListTile<ThemeModePreference>(
                        value: ThemeModePreference.light,
                        groupValue: themeState.preference,
                        title: Text(t.themeLight),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<ThemeCubit>().setThemeMode(value);
                          }
                        },
                      ),
                      RadioListTile<ThemeModePreference>(
                        value: ThemeModePreference.dark,
                        groupValue: themeState.preference,
                        title: Text(t.themeDark),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<ThemeCubit>().setThemeMode(value);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                t.privacySettings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: settings.readReceipts,
                title: Text(t.readReceiptsTitle),
                subtitle: Text(t.readReceiptsSubtitle),
                onChanged: (value) {
                  context.read<SettingsCubit>().setReadReceipts(value);
                },
              ),
              SwitchListTile.adaptive(
                value: settings.secretChatDefaultOn,
                title: Text(t.secretChatDefaultTitle),
                subtitle: Text(t.secretChatDefaultSubtitle),
                onChanged: (value) {
                  context.read<SettingsCubit>().setSecretChatDefault(value);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(t.stickerPackTitle),
                subtitle: Text(t.stickerPackSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/stickers'),
              ),
            ],
          );
        },
      ),
    );
  }
}
