import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/sfx.dart';
import 'ui/common.dart';
import 'ui/level_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Progress.init();
  await Sfx.init();
  runApp(const SweetCrushApp());
}

class SweetCrushApp extends StatelessWidget {
  const SweetCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweet Crush',
      debugShowCheckedModeBanner: false,
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
  }
}
