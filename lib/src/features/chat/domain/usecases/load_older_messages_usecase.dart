import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';

class LoadOlderMessagesUseCase {
  LoadOlderMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessage>> call({
    required String peerId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = 40,
  }) {
    return _repository.loadOlderMessages(
      peerId: peerId,
      beforeCreatedAt: beforeCreatedAt,
      beforeMessageId: beforeMessageId,
      limit: limit,
    );
  }
}
