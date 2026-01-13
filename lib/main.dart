import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/magic_engine.dart';
import 'screens/magic_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce full screen and portrait mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MagicEngine()..initialize()),
      ],
      child: const ImagicApp(),
    ),
  );
}

class ImagicApp extends StatelessWidget {
  const ImagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '魔术师',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MagicScreen(),
    );
  }
}
