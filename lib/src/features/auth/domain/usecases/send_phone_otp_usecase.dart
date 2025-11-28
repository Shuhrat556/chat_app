import 'package:chat_app/src/features/auth/domain/repositories/auth_repository.dart';

class SendPhoneOtpUseCase {
  SendPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call({
    required String phoneNumber,
    int? forceResendingToken,
  }) {
    return _repository.sendPhoneOtp(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
    );
  }
}
