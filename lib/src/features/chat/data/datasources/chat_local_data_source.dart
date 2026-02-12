import 'package:chat_app/src/features/chat/data/local/chat_message_entity.dart';
import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ChatLocalDataSource {
  ChatLocalDataSource();

  static const defaultPageSize = 40;

  Isar? _isar;
  Future<Isar?>? _opening;
  bool _disabled = false;

  Future<void> cacheMessage(ChatMessage message) async {
    await cacheMessages([message]);
  }

  Future<void> cacheMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    final isar = await _getIsar();
    if (isar == null) return;

    final entities = messages.map(_toEntity).toList(growable: false);
    await isar.writeTxn(() async {
      await isar.chatMessageEntitys.putAll(entities);
    });
  }

  Future<List<ChatMessage>> loadRecentMessages({
    required String conversationId,
    int limit = defaultPageSize,
  }) async {
    final isar = await _getIsar();
    if (isar == null) return const [];

    final entities = await isar.chatMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .findAll();

    final sorted = _sortAscending(entities);
    final chunk = _takeLast(sorted, limit);
    return chunk.map(_toDomain).toList(growable: false);
  }

  Stream<List<ChatMessage>> watchRecentMessages({
    required String conversationId,
    int limit = defaultPageSize,
  }) async* {
    final isar = await _getIsar();
    if (isar == null) {
      yield const [];
      return;
    }

    final query = isar.chatMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .build();

    await for (final _ in query.watchLazy(fireImmediately: true)) {
      final entities = await query.findAll();
      final sorted = _sortAscending(entities);
      final chunk = _takeLast(sorted, limit);
      yield chunk.map(_toDomain).toList(growable: false);
    }
  }

  Future<List<ChatMessage>> loadOlderMessages({
    required String conversationId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = defaultPageSize,
  }) async {
    final isar = await _getIsar();
    if (isar == null) return const [];

    final entities = await isar.chatMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .findAll();

    final sorted = _sortAscending(entities);
    final older = sorted
        .where((entity) {
          final olderByTime = entity.createdAt.isBefore(beforeCreatedAt);
          final sameTimeButOlderId =
              entity.createdAt.isAtSameMomentAs(beforeCreatedAt) &&
              entity.messageId.compareTo(beforeMessageId) < 0;
          return olderByTime || sameTimeButOlderId;
        })
        .toList(growable: false);

    final chunk = _takeLast(older, limit);
    return chunk.map(_toDomain).toList(growable: false);
  }

  Future<Isar?> _getIsar() async {
    if (_disabled) return null;
    if (_isar != null) return _isar;
    if (_opening != null) return _opening!;

    _opening = _openInternal();
    final opened = await _opening!;
    _opening = null;
    _isar = opened;
    return opened;
  }

  Future<Isar?> _openInternal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return Isar.open(
        [ChatMessageEntitySchema],
        directory: dir.path,
        name: 'chat_cache',
      );
    } catch (_) {
      _disabled = true;
      return null;
    }
  }

  ChatMessageEntity _toEntity(ChatMessage message) {
    final entity = ChatMessageEntity()
      ..messageId = message.id
      ..conversationId = message.conversationId
      ..senderId = message.senderId
      ..receiverId = message.receiverId
      ..text = message.text
      ..createdAt = message.createdAt;
    return entity;
  }

  ChatMessage _toDomain(ChatMessageEntity entity) {
    return ChatMessage(
      id: entity.messageId,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      receiverId: entity.receiverId,
      text: entity.text,
      createdAt: entity.createdAt,
    );
  }

  List<ChatMessageEntity> _sortAscending(List<ChatMessageEntity> input) {
    final sorted = List<ChatMessageEntity>.of(input);
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.messageId.compareTo(b.messageId);
    });
    return sorted;
  }

  List<ChatMessageEntity> _takeLast(List<ChatMessageEntity> input, int limit) {
    if (limit <= 0 || input.length <= limit) {
      return input;
    }
    return input.sublist(input.length - limit);
  }
}
