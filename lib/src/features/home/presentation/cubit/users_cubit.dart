import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_conversation_preview.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:equatable/equatable.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._remoteDataSource, this._chatRepository)
    : super(const UsersState());

  final UserRemoteDataSource _remoteDataSource;
  final ChatRepository _chatRepository;
  StreamSubscription<List<AppUser>>? _usersSub;
  StreamSubscription<Map<String, ChatConversationPreview>>? _conversationSub;
  List<AppUser> _users = const [];
  Map<String, int> _unreadByUserId = const {};
  Map<String, ChatConversationPreview> _conversationsByUserId = const {};

  void start() {
    emit(
      state.copyWith(
        status: UsersStatus.loading,
        error: null,
        unreadByUserId: const {},
        conversationsByUserId: const {},
      ),
    );
    _usersSub?.cancel();
    _conversationSub?.cancel();

    _usersSub = _remoteDataSource.streamUsers().listen(
      (users) {
        _users = users;
        _emitLoaded();
      },
      onError: (error) => emit(
        state.copyWith(status: UsersStatus.error, error: error.toString()),
      ),
    );

    _conversationSub = _chatRepository.watchConversationPreviewsByPeer().listen(
      (conversationsByPeer) {
        _conversationsByUserId = conversationsByPeer;
        _unreadByUserId = {
          for (final entry in conversationsByPeer.entries)
            entry.key: entry.value.unreadCount,
        };
        _emitLoaded();
      },
      onError: (_) {
        // Keep users list active if conversation stream fails.
      },
    );
  }

  Future<void> refresh() async {
    start();
    try {
      await stream.firstWhere(
        (s) => s.status == UsersStatus.loaded || s.status == UsersStatus.error,
      );
    } catch (_) {
      // Pull-to-refresh should fail silently and keep current UI state.
    }
  }

  void _emitLoaded() {
    emit(
      state.copyWith(
        status: UsersStatus.loaded,
        users: _users,
        unreadByUserId: _unreadByUserId,
        conversationsByUserId: _conversationsByUserId,
        error: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _usersSub?.cancel();
    _conversationSub?.cancel();
    return super.close();
  }
}
