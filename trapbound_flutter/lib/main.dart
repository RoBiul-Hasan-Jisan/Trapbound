import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core.dart';
import 'screens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (_) {}
  await Save.I.load();
  runApp(const TrapboundApp());
}

class TrapboundApp extends StatelessWidget {
  const TrapboundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trapbound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: kFamily,
        fontFamilyFallback: kFallback,
        scaffoldBackgroundColor: const Color(0xFF7656A6),
      ),
      home: const MenuScreen(),
    );
  }
}
