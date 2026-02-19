import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_app/src/features/auth/data/datasources/presence_remote_data_source.dart';
import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:chat_app/src/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required WatchMessagesUseCase watchMessagesUseCase,
    required LoadOlderMessagesUseCase loadOlderMessagesUseCase,
    required MarkConversationReadUseCase markConversationReadUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required FirebaseAuth firebaseAuth,
    required PresenceRemoteDataSource presenceRemoteDataSource,
  }) : _watchMessagesUseCase = watchMessagesUseCase,
       _loadOlderMessagesUseCase = loadOlderMessagesUseCase,
       _markConversationReadUseCase = markConversationReadUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _firebaseAuth = firebaseAuth,
       _presenceRemoteDataSource = presenceRemoteDataSource,
       super(const ChatState());

  static const _pageSize = 40;

  final WatchMessagesUseCase _watchMessagesUseCase;
  final LoadOlderMessagesUseCase _loadOlderMessagesUseCase;
  final MarkConversationReadUseCase _markConversationReadUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final FirebaseAuth _firebaseAuth;
  final PresenceRemoteDataSource _presenceRemoteDataSource;

  StreamSubscription<List<ChatMessage>>? _sub;
  StreamSubscription<Set<String>>? _typingUsersSub;
  List<ChatMessage> _olderMessages = const [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _lastHandledIncomingId;
  Timer? _typingTimer;
  bool _isCurrentUserTyping = false;
  String? _typingConversationId;

  void start(AppUser peer) {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    unawaited(_stopTypingRemote());
    _typingConversationId = null;
    _typingUsersSub?.cancel();
    _typingUsersSub = null;
    _olderMessages = const [];
    _hasMore = true;
    _isLoadingMore = false;
    _lastHandledIncomingId = null;
    _isCurrentUserTyping = false;
    emit(
      state.copyWith(
        peer: peer,
        status: ChatStatus.loading,
        currentUserId: currentUserId,
        error: null,
        hasMore: true,
        isLoadingMore: false,
        isTyping: false,
      ),
    );
    if (currentUserId != null) {
      _typingConversationId = _canonicalConversationId(currentUserId, peer.id);
      _typingUsersSub = _presenceRemoteDataSource
          .watchTypingUsers(_typingConversationId!)
          .listen((typingUsers) {
            final peerTyping = typingUsers.contains(peer.id);
            if (state.isTyping != peerTyping) {
              emit(state.copyWith(isTyping: peerTyping));
            }
          }, onError: (_, __) {});
    }
    unawaited(_markConversationReadUseCase(peerId: peer.id));
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
            isTyping: state.isTyping,
          ),
        );

        for (var i = merged.length - 1; i >= 0; i--) {
          final message = merged[i];
          if (message.senderId == peer.id) {
            if (_lastHandledIncomingId != message.id) {
              _lastHandledIncomingId = message.id;
              unawaited(_markConversationReadUseCase(peerId: peer.id));
            }
            break;
          }
        }
      },
      onError: (error) => emit(
        state.copyWith(status: ChatStatus.error, error: error.toString()),
      ),
    );
  }

  void onTypingStarted() {
    final conversationId = _typingConversationId;
    if (conversationId == null) return;
    if (!_isCurrentUserTyping) {
      _isCurrentUserTyping = true;
      unawaited(_presenceRemoteDataSource.setTyping(conversationId, true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_stopTypingRemote());
    });
  }

  void onTypingStopped() {
    unawaited(_stopTypingRemote());
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
          isTyping: state.isTyping,
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

  Future<void> send(String text, {int? ttlSeconds}) {
    final peerId = state.peer?.id;
    if (peerId == null) return Future.value();
    return _sendMessageUseCase(
      peerId: peerId,
      text: text,
      ttlSeconds: ttlSeconds,
    );
  }

  Future<void> sendImage(String imageUrl, {String? caption, int? ttlSeconds}) {
    final peerId = state.peer?.id;
    if (peerId == null) return Future.value();
    return _sendMessageUseCase(
      peerId: peerId,
      text: caption ?? '',
      imageUrl: imageUrl,
      ttlSeconds: ttlSeconds,
    );
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
  Future<void> close() async {
    await _sub?.cancel();
    await _typingUsersSub?.cancel();
    await _stopTypingRemote();
    return super.close();
  }

  Future<void> _stopTypingRemote() async {
    _typingTimer?.cancel();
    if (!_isCurrentUserTyping) return;
    _isCurrentUserTyping = false;
    final conversationId = _typingConversationId;
    if (conversationId == null) return;
    try {
      await _presenceRemoteDataSource.setTyping(conversationId, false);
    } catch (_) {
      // Typing indicator failure must not break chat flow.
    }
  }

  String _canonicalConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted.first}_${sorted.last}';
  }
}
