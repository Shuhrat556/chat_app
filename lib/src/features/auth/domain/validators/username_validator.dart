enum UsernameValidationError {
  empty('required_username'),
  tooShort('username_min_5'),
  tooLong('username_max_20'),
  latinOnly('username_latin_only');

  const UsernameValidationError(this.messageKey);
  final String messageKey;
}

class UsernameValidator {
  static final _latinRegex = RegExp(r'^[A-Za-z]{5,20}$');

  static UsernameValidationError? validate(String input) {
    final value = input.trim();
    if (value.isEmpty) return UsernameValidationError.empty;
    if (value.length < 5) return UsernameValidationError.tooShort;
    if (value.length > 20) return UsernameValidationError.tooLong;
    if (!_latinRegex.hasMatch(value)) return UsernameValidationError.latinOnly;
    return null;
  }

  static bool isValid(String input) => validate(input) == null;

  static String canonical(String input) => input.trim().toLowerCase();
}
