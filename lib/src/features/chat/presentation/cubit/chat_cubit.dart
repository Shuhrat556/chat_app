import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required WatchMessagesUseCase watchMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required FirebaseAuth firebaseAuth,
  })  : _watchMessagesUseCase = watchMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _firebaseAuth = firebaseAuth,
        super(const ChatState());

  final WatchMessagesUseCase _watchMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<List<ChatMessage>>? _sub;

  void start(AppUser peer) {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    emit(
      state.copyWith(
        peer: peer,
        status: ChatStatus.loading,
        currentUserId: currentUserId,
        error: null,
      ),
    );
    _sub?.cancel();
    _sub = _watchMessagesUseCase(peerId: peer.id).listen(
      (messages) => emit(
        state.copyWith(
          messages: messages,
          status: ChatStatus.loaded,
          error: null,
        ),
      ),
      onError: (error) => emit(
        state.copyWith(
          status: ChatStatus.error,
          error: error.toString(),
        ),
      ),
    );
  }

  Future<void> send(String text) {
    final peerId = state.peer?.id;
    if (peerId == null) return Future.value();
    return _sendMessageUseCase(peerId: peerId, text: text);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
