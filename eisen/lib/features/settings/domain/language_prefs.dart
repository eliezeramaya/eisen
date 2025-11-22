import 'package:flutter/material.dart';

class LanguagePrefs {
  const LanguagePrefs(this.locale);

  /// Null locale means "follow system".
  final Locale? locale;

  Map<String, Object?> toJson() => {
        'languageCode': locale?.languageCode ?? 'system',
        'countryCode': locale?.countryCode,
      };

  static LanguagePrefs fromJson(Map<String, Object?> json) {
    final lang = json['languageCode'] as String?;
    final country = json['countryCode'] as String?;
    if (lang == null || lang == 'system') {
      return const LanguagePrefs(null);
    }
    return LanguagePrefs(Locale(lang, country?.isNotEmpty == true ? country : null));
  }
}
