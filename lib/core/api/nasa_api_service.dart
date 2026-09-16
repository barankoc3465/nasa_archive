import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';

// import 'package:senin_proje_adin/features/apod/apod_model.dart';

class NasaApiService {
  // late final: "Bu değişkeni hemen şimdi değil, sınıf oluşturulurken (constructor içinde) dolduracağım" demek.
  late final Dio _dio;

  final String _apiKey = "DEMO_KEY";
  final String _baseUrl = "https://api.nasa.gov/planetary/apod";

  // Sınıf başlatıldığında çalışacak Kurucu Metot (Constructor)
  NasaApiService() {
    // 1. Temel Ayarlar (BaseOptions)
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(
          seconds: 10,
        ), // Sunucuya bağlanmak için max 10 saniye bekle
        receiveTimeout: const Duration(
          seconds: 10,
        ), // Veriyi indirmek için max 10 saniye bekle
      ),
    );
  }

  Future<ApodModel?> fetchApod() async {
    try {
      // 2. URL'e elle "?api_key=..." yazmak yerine queryParameters kullanıyoruz.
      // BaseUrl'i yukarıda verdiğimiz için ilk parametre boş ('').
      final response = await _dio.get(
        '',
        queryParameters: {
          'api_key': _apiKey,
          // İleride belirli bir günü çekmek istersen buraya kolayca 'date': '2023-10-25' ekleyebilirsin.
        },
      );

      // Dio varsayılan olarak 200 dışındaki yanıtları direkt "catch" bloğuna atar.
      // Yani buraya ulaştıysa işlem %99 başarılıdır, yine de verinin null olmadığını teyit edelim.
      if (response.statusCode == 200 && response.data != null) {
        return ApodModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      // 3. Kriz Yönetimi 2.0: Dio Hatalarını Özel Olarak Yakalama
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        debugPrint(
          "Sunucuya bağlanılamadı, zaman aşımı (İnternet yavaş olabilir).",
        );
      } else if (e.response?.statusCode == 429) {
        debugPrint("API limitine takıldık, çok fazla istek atıldı.");
      } else {
        debugPrint("Dio Hata: ${e.message}");
      }
      return null;
    } catch (e) {
      // 4. Dio dışındaki genel hatalar (Örn: Model'e dönüştürürken yaşanan bir tip hatası)
      debugPrint("Beklenmeyen bir hata oluştu: $e");
      return null;
    }
  }
}
