import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nasa_uzay_yolu/core/theme/app_theme.dart';
import 'package:nasa_uzay_yolu/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const NasaApp());
}

class NasaApp extends StatelessWidget {
  const NasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uzay Fotoğrafları',
      theme: AppTheme.dark,
      home: const MainScreen(), // Uygulama direkt bu ekranla başlayacak
    );
  }
}
