import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.deleteAccount();
}
