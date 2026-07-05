import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/sfx.dart';
import 'i18n/strings.dart';
import 'ui/common.dart';
import 'ui/level_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Progress.init();
  await Lang.init();
  await Sfx.init();
  runApp(const SweetCrushApp());
}

class SweetCrushApp extends StatelessWidget {
  const SweetCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: Lang.notifier,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Sweet Crush',
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          supportedLocales: [
            for (final l in AppLang.values) l.locale,
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Fredoka',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB45CFF),
              brightness: Brightness.dark,
            ),
          ),
          home: const LevelSelectScreen(),
        );
      },
    );
  }
}
