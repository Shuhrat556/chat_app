import 'package:chat_app/src/features/chat/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required String peerId,
    required String text,
    String? imageUrl,
  }) {
    return _repository.sendMessage(
      peerId: peerId,
      text: text,
      imageUrl: imageUrl,
    );
  }
}
