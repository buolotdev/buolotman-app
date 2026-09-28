import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  AppLanguage._();

  static const supported = <String>['en', 'fr', 'rw'];
  static const labels = <String, String>{
    'en': 'English',
    'fr': 'Français',
    'rw': 'Kinyarwanda',
  };
  static const _key = 'language_preference';
  static final ValueNotifier<String> current = ValueNotifier<String>('en');

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? prefs.getString('lang');
    if (saved != null && supported.contains(saved)) current.value = saved;
  }

  static Future<void> setLocal(String code) async {
    if (!supported.contains(code)) return;
    current.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    await prefs.setString('lang', code);
  }
}

class AppLanguagePicker extends StatelessWidget {
  const AppLanguagePicker({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: AppLanguage.current,
    builder: (context, value, _) => DropdownButtonFormField<String>(
      initialValue: AppLanguage.supported.contains(value) ? value : 'en',
      decoration: const InputDecoration(labelText: 'Language'),
      items: [
        for (final code in AppLanguage.supported)
          DropdownMenuItem(value: code, child: Text(AppLanguage.labels[code]!)),
      ],
      onChanged: (code) {
        if (code != null) AppLanguage.setLocal(code);
      },
    ),
  );
}
