import 'package:chat_app/src/features/auth/domain/validators/username_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sign-up username rule requires 5..20 latin letters only', () {
    expect(UsernameValidator.validate('abc'), UsernameValidationError.tooShort);
    expect(
      UsernameValidator.validate('ab_cd'),
      UsernameValidationError.latinOnly,
    );
    expect(
      UsernameValidator.validate('абвгд'),
      UsernameValidationError.latinOnly,
    );
    expect(UsernameValidator.validate('abcdef'), isNull);
  });
}
