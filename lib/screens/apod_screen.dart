import 'package:flutter/material.dart';
import 'package:nasa_uzay_yolu/core/api/nasa_api_service.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';

// Kendi proje adına göre import yollarını güncellemelisin:
// import 'package:senin_proje_adin/core/api/nasa_api_service.dart';
// import 'package:senin_proje_adin/features/apod/apod_model.dart';

class ApodScreen extends StatefulWidget {
  const ApodScreen({super.key});

  @override
  State<ApodScreen> createState() => _ApodScreenState();
}

class _ApodScreenState extends State<ApodScreen> {
  // Masadaki durumları tutacağımız değişkenler
  ApodModel? _apodData; // Tabaktaki yemeğimiz (Veri)
  bool _isLoading = true; // Garson yolda mı? (Yükleniyor durumu)
  String _errorMessage = ''; // Bir sorun çıkarsa göstereceğimiz mesaj

  @override
  void initState() {
    super.initState();
    // Ekran (Müşteri) açılır açılmaz siparişi veriyoruz
    _fetchData();
  }

  // Siparişi getiren asenkron fonksiyon
  Future<void> _fetchData() async {
    final service = NasaApiService();
    final data = await service.fetchApod();

    setState(() {
      _isLoading = false; // Garson geri döndü (Yükleme bitti)
      if (data != null) {
        _apodData = data; // Veri geldiyse tabağa koy
      } else {
        _errorMessage =
            "Uzayla iletişim kurulamadı. İnternetinizi kontrol edin.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Uzay temasına uygun siyah arka plan
      appBar: AppBar(
        title: const Text('Günün Astronomi Görseli'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Duruma göre ekranda ne göstereceğimize karar veriyoruz:
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ) // 1. DURUM: Yükleniyor
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ) // 2. DURUM: Hata
          : _buildSuccessUI(), // 3. DURUM: Başarılı
    );
  }

  // Veri başarıyla geldiğinde çizilecek ekran (Kod kalabalığı olmasın diye ayırdık)
  Widget _buildSuccessUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resim Bölümü
          Image.network(
            _apodData!.url,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            // Resim yüklenirken küçük bir yükleyici gösterelim
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          ),

          // Metin Bölümleri
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _apodData!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _apodData!.explanation,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5, // Satır arası boşluk, okumayı kolaylaştırır
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
