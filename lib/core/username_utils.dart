final usernamePattern = RegExp(r'^[a-zA-Z0-9._]{3,30}$');

String normalizeUsername(String value) => value.trim().toLowerCase();

String? validateUsername(String value) {
  final username = normalizeUsername(value);
  if (username.isEmpty) return 'Username is required.';
  if (!usernamePattern.hasMatch(username)) {
    return 'Use 3–30 characters: letters, numbers, periods, or underscores.';
  }
  return null;
}
