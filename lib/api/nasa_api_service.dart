import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';
import 'package:nasa_uzay_yolu/features/space/space_images_model.dart';

class _CachedValue<T> {
  final T value;
  final DateTime createdAt;

  const _CachedValue(this.value, this.createdAt);
}

class NasaApiService {
  late final Dio _dio;
  final Map<String, _CachedValue<List<SpaceImage>>> _imageCache = {};
  _CachedValue<ApodModel?>? _apodCache;

  final String _apiKey = dotenv.env['API_KEY']?.trim() ?? 'DEMO_KEY';

  NasaApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// Günün Astronomi Görselini (APOD) getirir
  Future<ApodModel?> fetchApod({bool forceRefresh = false}) async {
    final cached = _apodCache;
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) <
            const Duration(minutes: 15)) {
      return cached.value;
    }

    try {
      final response = await _dio.get(
        'https://api.nasa.gov/planetary/apod',
        queryParameters: {'api_key': _apiKey},
      );

      if (response.statusCode == 200 && response.data != null) {
        final apod = ApodModel.fromJson(response.data as Map<String, dynamic>);
        _apodCache = _CachedValue(apod, DateTime.now());
        return apod;
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

  /// NASA Uzay ve Görsel Kütüphanesinde arama yapar
  Future<List<SpaceImage>> searchSpaceImages(
    String query, {
    int page = 1,
    int pageSize = 24,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${query.trim().toLowerCase()}::$page::$pageSize';
    final cached = _imageCache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) <
            const Duration(minutes: 30)) {
      return cached.value;
    }

    try {
      final response = await _dio.get(
        'https://images-api.nasa.gov/search',
        queryParameters: {
          'q': query,
          'media_type': 'image',
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            response.data['collection']?['items'] as List<dynamic>? ?? [];

        final images = items
            .whereType<Map<String, dynamic>>()
            .map(SpaceImage.fromNasaItem)
            .where((image) => image.imageUrl.isNotEmpty)
            .toList();
        _imageCache[cacheKey] = _CachedValue(images, DateTime.now());
        return images;
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
