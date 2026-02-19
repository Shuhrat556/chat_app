import 'dart:async';

import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/presence/presence_lifecycle_service.dart';
import 'package:chat_app/src/core/router/app_router.dart';
import 'package:chat_app/src/core/theme/app_theme.dart';
import 'package:chat_app/src/core/theme/theme_cubit.dart';
import 'package:chat_app/src/core/theme/theme_state.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final SettingsCubit _settingsCubit;
  late final ThemeCubit _themeCubit;
  late final PresenceLifecycleService _presenceLifecycleService;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _settingsCubit = sl<SettingsCubit>()..start();
    _themeCubit = sl<ThemeCubit>()..start();
    _presenceLifecycleService = sl<PresenceLifecycleService>();
    unawaited(_presenceLifecycleService.start());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  void dispose() {
    unawaited(_presenceLifecycleService.dispose());
    _themeCubit.close();
    _settingsCubit.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<SettingsCubit>.value(value: _settingsCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final isDark = themeState.themeMode == ThemeMode.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarColor: isDark
                    ? const Color(0xFF010A1F)
                    : const Color(0xFFF3F6FF),
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: MaterialApp.router(
                title: 'Chat App',
                debugShowCheckedModeBanner: false,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  if (locale == null) return const Locale('ru');
                  final match = supportedLocales
                      .where((l) => l.languageCode == locale.languageCode)
                      .toList();
                  return match.isNotEmpty ? match.first : const Locale('ru');
                },
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeState.themeMode,
                routerConfig: _appRouter.router,
              ),
            );
          },
        ),
      ),
    );
  }
}
