import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String username,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? bio,
    String? photoUrl,
  }) {
    return _repository.updateProfile(
      username: username,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      bio: bio,
      photoUrl: photoUrl,
    );
  }
}
