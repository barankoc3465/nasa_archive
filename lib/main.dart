import 'package:flutter/material.dart';
import 'package:nasa_uzay_yolu/screens/apod_screen.dart';

void main() {
  runApp(const NasaApp());
}

class NasaApp extends StatelessWidget {
  const NasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uzay Fotoğrafları',
      theme: ThemeData.dark(), // Koyu tema uzay konseptine çok yakışır
      home: const ApodScreen(), // Uygulama direkt bu ekranla başlayacak
    );
  }
}
