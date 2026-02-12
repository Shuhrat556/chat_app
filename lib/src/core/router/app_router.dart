import 'package:chat_app/src/core/router/refresh_stream.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/auth/presentation/pages/profile_page.dart';
import 'package:chat_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:chat_app/src/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: StreamRefreshListenable(_authBloc.stream),
    redirect: (context, state) {
      final path = state.fullPath ?? state.uri.path;
      final authState = _authBloc.state;
      final isBooting = authState.status == AuthStatus.initial;
      final loggedIn = authState.user != null;
      final loggingIn = path == '/auth' || path == '/signup';
      final inSplash = path == '/splash';

      if (isBooting) return inSplash ? null : '/splash';
      if (!loggedIn && inSplash) return '/auth';
      if (loggedIn && inSplash) return '/home';
      if (!loggedIn && !loggingIn) return '/auth';
      if (loggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _AuthBootstrapPage(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const SignInPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final peer = state.extra;
          return ChatPage(peer: peer is AppUser ? peer : null);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

class _AuthBootstrapPage extends StatelessWidget {
  const _AuthBootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
