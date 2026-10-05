import 'dart:convert';
import 'package:flutter/services.dart';

/// UI text. `assets/i18n/uz.json` is a copy of the web app's `messages/uz.json` (same keys, so a screen
/// ported from the web keeps its `t("…")` calls); `uz.mobile.json` holds the few strings only the app needs.
class Messages {
  Messages(this._data);

  final Map<String, dynamic> _data;

  static Messages instance = Messages(const {});

  static Future<void> load() async {
    final web =
        jsonDecode(await rootBundle.loadString('assets/i18n/uz.json'))
            as Map<String, dynamic>;
    final mobile =
        jsonDecode(await rootBundle.loadString('assets/i18n/uz.mobile.json'))
            as Map<String, dynamic>;
    instance = Messages({...web, ...mobile});
  }

  /// `translate("auth.errors.required")`, `translate("nav.levelXp", {"level": 3, "xp": 120})`.
  /// Unknown keys come back as the key itself, like next-intl does in development.
  String translate(String key, [Map<String, Object?> args = const {}]) {
    Object? node = _data;
    for (final part in key.split('.')) {
      node = node is Map<String, dynamic> ? node[part] : null;
    }
    if (node is! String) return key;
    if (args.isEmpty) return node;
    return node.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => args.containsKey(m[1]) ? '${args[m[1]]}' : m[0]!,
    );
  }
}

String t(String key, [Map<String, Object?> args = const {}]) =>
    Messages.instance.translate(key, args);
