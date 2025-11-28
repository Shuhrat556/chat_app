import 'package:chat_app/src/features/chat/data/local/chat_message_entity.dart';
import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:isar/isar.dart';

class ChatLocalDataSource {
  ChatLocalDataSource(this._isar);

  final Isar _isar;

  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
  }) {
    return _isar.chatMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .watch(fireImmediately: true)
        .map((entities) => entities.map((e) => e.toModel()).toList(growable: false));
  }

  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    if (messages.isEmpty) return;
    final entities = messages.map(ChatMessageEntity.fromModel).toList();
    await _isar.writeTxn(() async {
      await _isar.chatMessageEntitys.putAll(entities);
    });
  }
}
