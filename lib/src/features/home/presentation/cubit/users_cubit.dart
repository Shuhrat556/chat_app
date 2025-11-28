import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:equatable/equatable.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._remoteDataSource) : super(const UsersState());

  final UserRemoteDataSource _remoteDataSource;
  StreamSubscription<List<AppUser>>? _sub;

  void start() {
    emit(state.copyWith(status: UsersStatus.loading, error: null));
    _sub?.cancel();
    _sub = _remoteDataSource.streamUsers().listen(
      (users) => emit(
        state.copyWith(
          status: UsersStatus.loaded,
          users: users,
          error: null,
        ),
      ),
      onError: (error) => emit(
        state.copyWith(
          status: UsersStatus.error,
          error: error.toString(),
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
