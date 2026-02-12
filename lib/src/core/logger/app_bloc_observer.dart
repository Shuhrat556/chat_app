import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Global Bloc observer to log events, transitions, and errors to console.
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    debugPrint('[BLOC EVENT] ${bloc.runtimeType}: $event');
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    debugPrint(
      '[BLOC TRANSITION] ${bloc.runtimeType}: '
      '${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
    );
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('[BLOC ERROR] ${bloc.runtimeType}: $error');
    debugPrintStack(stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
