import 'dart:ui';

/// 简体中文、繁体中文走中文；其余语言走英文。
Locale? resolveAppLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  if (locale == null) return const Locale('en');

  if (locale.languageCode == 'zh') {
    return const Locale('zh');
  }

  return const Locale('en');
}
