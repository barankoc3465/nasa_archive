import 'package:flutter/material.dart';
import 'package:nasa_uzay_yolu/screens/apod_screen.dart';
import 'package:nasa_uzay_yolu/screens/universe_galery_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Şu an hangi sekmede olduğumuzu tutan değişken (0: APOD, 1: Galeri)
  int _currentIndex = 0;

  // Gösterilecek ekranların listesi (Sırası önemli!)
  final List<Widget> _screens = [
    const ApodScreen(),
    const SpaceGalleryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body kısmına, listedeki seçili index'e denk gelen ekranı veriyoruz
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),

      // Alt Menü Bölümü
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // Kullanıcı bir sekmeye tıkladığında ne olacak?
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Seçili index'i güncelle ve ekranı yenile
          });
        },

        // Menüdeki butonlar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star), // Yıldız ikonu
            label: 'Picture of the Day', // Günün Astronomi Görseli
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore), // Keşif/Pusula ikonu
            label: 'Nasa Universe Galery',
          ),
        ],
      ),
    );
  }
}
