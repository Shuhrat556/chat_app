import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';

class MarkConversationReadUseCase {
  MarkConversationReadUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({required String peerId}) {
    return _repository.markConversationRead(peerId: peerId);
  }
}
