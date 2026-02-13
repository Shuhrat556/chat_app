import 'package:chat_app/src/core/router/refresh_stream.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_app/src/features/auth/presentation/pages/change_password_page.dart';
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
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const _AuthBootstrapPage(),
          animate: false,
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _buildPage(key: state.pageKey, child: const SignInPage()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            _buildPage(key: state.pageKey, child: const SignUpPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _buildPage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/chat/:userId',
        pageBuilder: (context, state) {
          final peer = state.extra;
          return _buildPage(
            key: state.pageKey,
            child: ChatPage(peer: peer is AppUser ? peer : null),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildPage(key: state.pageKey, child: const ProfilePage()),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) =>
            _buildPage(key: state.pageKey, child: const ChangePasswordPage()),
      ),
    ],
  );

  CustomTransitionPage<void> _buildPage({
    required LocalKey key,
    required Widget child,
    bool animate = true,
  }) {
    if (!animate) {
      return CustomTransitionPage<void>(
        key: key,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      );
    }

    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: const Duration(milliseconds: 230),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offsetTween = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        );
        final scaleTween = Tween<double>(begin: 0.985, end: 1.0);
        return SlideTransition(
          position: offsetTween.animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.90, end: 1).animate(curved),
            child: ScaleTransition(
              scale: scaleTween.animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AuthBootstrapPage extends StatelessWidget {
  const _AuthBootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF010A1F),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
