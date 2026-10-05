import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/i18n/messages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone layout only, like the web app below its `md` breakpoint.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
  await Messages.load();
  runApp(const ProviderScope(child: ZukkolarApp()));
}
