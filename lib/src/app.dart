import 'package:chat_app/src/core/di/service_locator.dart';
import 'package:chat_app/src/core/router/app_router.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
      ],
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
          final match = supportedLocales.where((l) => l.languageCode == locale.languageCode).toList();
          return match.isNotEmpty ? match.first : const Locale('ru');
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          useMaterial3: true,
        ),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
