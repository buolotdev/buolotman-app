bool isVerifiedProfile(dynamic profile) {
  if (profile is! Map) return false;

  dynamic value = profile['is_verified'];
  if (value == null) {
    final nested = profile['profile'] ?? profile['client_profile'];
    if (nested is Map) value = nested['is_verified'];
  }

  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'verified' ||
      normalized == 'approved';
}
