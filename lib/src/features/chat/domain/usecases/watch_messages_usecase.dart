import 'package:chat_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';

class WatchMessagesUseCase {
  WatchMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Stream<List<ChatMessage>> call({required String peerId}) {
    return _repository.watchMessages(peerId: peerId);
  }
}
