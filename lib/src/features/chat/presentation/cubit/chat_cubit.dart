import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required WatchMessagesUseCase watchMessagesUseCase,
    required LoadOlderMessagesUseCase loadOlderMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required FirebaseAuth firebaseAuth,
  }) : _watchMessagesUseCase = watchMessagesUseCase,
       _loadOlderMessagesUseCase = loadOlderMessagesUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _firebaseAuth = firebaseAuth,
       super(const ChatState());

  static const _pageSize = 40;

  final WatchMessagesUseCase _watchMessagesUseCase;
  final LoadOlderMessagesUseCase _loadOlderMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _olderMessages = const [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  void start(AppUser peer) {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    _olderMessages = const [];
    _hasMore = true;
    _isLoadingMore = false;
    emit(
      state.copyWith(
        peer: peer,
        status: ChatStatus.loading,
        currentUserId: currentUserId,
        error: null,
        hasMore: true,
        isLoadingMore: false,
      ),
    );
    _sub?.cancel();
    _sub = _watchMessagesUseCase(peerId: peer.id, limit: _pageSize).listen(
      (messages) {
        if (_olderMessages.isEmpty && messages.length < _pageSize) {
          _hasMore = false;
        }
        final merged = _mergeMessages(
          olderMessages: _olderMessages,
          liveMessages: messages,
        );
        emit(
          state.copyWith(
            messages: merged,
            status: ChatStatus.loaded,
            error: null,
            hasMore: _hasMore,
            isLoadingMore: _isLoadingMore,
          ),
        );
      },
      onError: (error) => emit(
        state.copyWith(status: ChatStatus.error, error: error.toString()),
      ),
    );
  }

  Future<void> loadOlder() async {
    final peer = state.peer;
    if (peer == null) return;
    if (_isLoadingMore || !_hasMore || state.messages.isEmpty) return;

    _isLoadingMore = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final oldestLoaded = state.messages.first;
      final older = await _loadOlderMessagesUseCase(
        peerId: peer.id,
        beforeCreatedAt: oldestLoaded.createdAt,
        beforeMessageId: oldestLoaded.id,
        limit: _pageSize,
      );

      if (older.length < _pageSize) {
        _hasMore = false;
      }
      if (older.isNotEmpty) {
        _olderMessages = _mergeMessages(
          olderMessages: older,
          liveMessages: _olderMessages,
        );
      }

      final merged = _mergeMessages(
        olderMessages: _olderMessages,
        liveMessages: state.messages,
      );
      emit(
        state.copyWith(
          messages: merged,
          status: ChatStatus.loaded,
          error: null,
          hasMore: _hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: error.toString(),
          isLoadingMore: false,
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> send(String text) {
    final peerId = state.peer?.id;
    if (peerId == null) return Future.value();
    return _sendMessageUseCase(peerId: peerId, text: text);
  }

  List<ChatMessage> _mergeMessages({
    required List<ChatMessage> olderMessages,
    required List<ChatMessage> liveMessages,
  }) {
    final byId = <String, ChatMessage>{};
    for (final message in olderMessages) {
      byId[message.id] = message;
    }
    for (final message in liveMessages) {
      byId[message.id] = message;
    }
    final merged = byId.values.toList(growable: false);
    merged.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return merged;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
