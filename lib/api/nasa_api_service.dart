import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';
import 'package:nasa_uzay_yolu/features/space/space_images_model.dart';

class NasaApiService {
  late final Dio _dio;

  // dotenv üzerinde API_KEY tanımlı değilse varsayılan DEMO_KEY kullanılır
  final String _apiKey = dotenv.env['API_KEY'] ?? 'DEMO_KEY';

  NasaApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// Günün Astronomi Görselini (APOD) getirir
  Future<ApodModel?> fetchApod() async {
    try {
      final response = await _dio.get(
        'https://api.nasa.gov/planetary/apod',
        queryParameters: {'api_key': _apiKey},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApodModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint("APOD Hata: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("APOD Beklenmeyen Hata: $e");
      return null;
    }
  }

  /// Rastgele belirtilen sayıda APOD fotoğrafı getirir
  Future<List<ApodModel>> fetchGalaxyPhotos({int count = 10}) async {
    final List<ApodModel> photos = [];
    try {
      final response = await _dio.get(
        'https://api.nasa.gov/planetary/apod',
        queryParameters: {'api_key': _apiKey, 'count': count, 'thumbs': true},
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List<dynamic>;
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            photos.add(ApodModel.fromJson(item));
          }
        }
      }
    } on DioException catch (e) {
      debugPrint("APOD Galeri Hatası: ${e.message}");
    } catch (e) {
      debugPrint("APOD Galeri Beklenmeyen Hata: $e");
    }
    return photos;
  }

  /// NASA Uzay ve Görsel Kütüphanesinde arama yapar
  Future<List<SpaceImage>> searchSpaceImages(String query) async {
    try {
      final response = await _dio.get(
        'https://images-api.nasa.gov/search',
        queryParameters: {'q': query, 'media_type': 'image'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            response.data['collection']?['items'] as List<dynamic>? ?? [];

        return items
            .whereType<Map<String, dynamic>>()
            .map(SpaceImage.fromNasaItem)
            .where((image) => image.imageUrl.isNotEmpty)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('NASA Görsel API Hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');
      return [];
    }
  }
}
