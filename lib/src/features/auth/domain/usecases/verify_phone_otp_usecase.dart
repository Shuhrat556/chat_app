import 'package:chat_app/src/features/auth/domain/entities/app_user.dart';
import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase {
  VerifyPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String verificationId,
    required String smsCode,
    String? username,
  }) {
    return _repository.verifyPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      username: username,
    );
  }
}
