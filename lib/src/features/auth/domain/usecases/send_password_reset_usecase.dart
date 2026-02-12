import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  SendPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) =>
      _repository.sendPasswordReset(email: email);
}
