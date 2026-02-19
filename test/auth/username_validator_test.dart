import 'package:chat_app/src/features/auth/domain/validators/username_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsernameValidator', () {
    test('invalid when empty', () {
      expect(UsernameValidator.validate(''), UsernameValidationError.empty);
    });

    test('invalid when too short', () {
      expect(
        UsernameValidator.validate('abcd'),
        UsernameValidationError.tooShort,
      );
    });

    test('invalid when too long', () {
      expect(
        UsernameValidator.validate('abcdefghijklmnopqrstu'),
        UsernameValidationError.tooLong,
      );
    });

    test('invalid when non latin chars are used', () {
      expect(
        UsernameValidator.validate('ab_cd'),
        UsernameValidationError.latinOnly,
      );
      expect(
        UsernameValidator.validate('абвгд'),
        UsernameValidationError.latinOnly,
      );
    });

    test('valid for latin 5..20', () {
      expect(UsernameValidator.validate('Abcde'), isNull);
      expect(UsernameValidator.canonical('AbCdE'), 'abcde');
    });
  });
}
