import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/commencer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TrilApp());
}

class TrilApp extends StatelessWidget {
  const TrilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRIL — Logistique Sahélienne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const CommencerScreen(),
    );
  }
}
