import 'package:chat_app/src/core/theme/theme_cubit.dart';
import 'package:chat_app/src/core/theme/theme_state.dart';
import 'package:chat_app/src/features/settings/domain/user_settings.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_state.dart';
import 'package:chat_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCubit extends Mock implements SettingsCubit {}

class _MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  late _MockSettingsCubit settingsCubit;
  late _MockThemeCubit themeCubit;

  setUpAll(() {
    registerFallbackValue(ThemeModePreference.system);
  });

  setUp(() {
    settingsCubit = _MockSettingsCubit();
    themeCubit = _MockThemeCubit();
  });

  Widget wrap(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('read receipts and secret default switches trigger updates', (
    tester,
  ) async {
    const settingsState = SettingsState(
      status: SettingsStatus.ready,
      settings: UserSettings(readReceipts: true, secretChatDefaultOn: true),
    );
    const themeState = ThemeState(
      preference: ThemeModePreference.system,
      isReady: true,
    );

    when(() => settingsCubit.state).thenReturn(settingsState);
    when(
      () => settingsCubit.stream,
    ).thenAnswer((_) => const Stream<SettingsState>.empty());
    when(() => settingsCubit.setReadReceipts(any())).thenAnswer((_) async {});
    when(
      () => settingsCubit.setSecretChatDefault(any()),
    ).thenAnswer((_) async {});

    when(() => themeCubit.state).thenReturn(themeState);
    when(
      () => themeCubit.stream,
    ).thenAnswer((_) => const Stream<ThemeState>.empty());
    when(() => themeCubit.setThemeMode(any())).thenAnswer((_) async {});

    await tester.pumpWidget(wrap(const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(0));
    await tester.pump();
    verify(() => settingsCubit.setReadReceipts(false)).called(1);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();
    verify(() => settingsCubit.setSecretChatDefault(false)).called(1);
  });

  testWidgets('theme radio option triggers theme cubit', (tester) async {
    const settingsState = SettingsState(status: SettingsStatus.ready);
    const themeState = ThemeState(
      preference: ThemeModePreference.system,
      isReady: true,
    );

    when(() => settingsCubit.state).thenReturn(settingsState);
    when(
      () => settingsCubit.stream,
    ).thenAnswer((_) => const Stream<SettingsState>.empty());
    when(() => settingsCubit.setReadReceipts(any())).thenAnswer((_) async {});
    when(
      () => settingsCubit.setSecretChatDefault(any()),
    ).thenAnswer((_) async {});

    when(() => themeCubit.state).thenReturn(themeState);
    when(
      () => themeCubit.stream,
    ).thenAnswer((_) => const Stream<ThemeState>.empty());
    when(() => themeCubit.setThemeMode(any())).thenAnswer((_) async {});

    await tester.pumpWidget(wrap(const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pump();
    verify(() => themeCubit.setThemeMode(ThemeModePreference.dark)).called(1);
  });
}
