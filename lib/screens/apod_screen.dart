import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:gal/gal.dart';
import 'package:nasa_uzay_yolu/api/nasa_api_service.dart';
import 'package:nasa_uzay_yolu/core/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';

class ApodScreen extends StatefulWidget {
  const ApodScreen({super.key});

  @override
  State<ApodScreen> createState() => _ApodScreenState();
}

class _ApodScreenState extends State<ApodScreen> {
  final NasaApiService _apiService = NasaApiService();
  ApodModel? _apodData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApodData();
  }

  Future<void> _loadApodData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apod = await _apiService.fetchApod();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (apod != null) {
        _apodData = apod;
      } else {
        _errorMessage = 'Günün astronomi görseli yüklenemedi.';
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Bağlantı açılamadı: $url')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _shareImage(ApodModel apod) async {
    try {
      await Share.share(
        '${apod.title}\n\n${apod.explanation}\n\n${apod.url}',
        subject: apod.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Paylaşım başarısız: $e')));
    }
  }

  Future<void> _downloadImage(ApodModel apod) async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final tempDir = await getTemporaryDirectory();
      final extension = apod.url.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final filePath =
          '${tempDir.path}/apod_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await Dio().download(apod.url, filePath);
      await Gal.putImage(filePath, album: 'NASA Uzay Galerisi');

      final file = File(filePath);
      if (await file.exists()) await file.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görsel galeriye kaydedildi'),
          backgroundColor: AppColors.magenta,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İndirme başarısız: $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: const Text(
          'Astronomy Picture of the Day',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cream),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.coral,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadApodData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _buildContent(_apodData!),
    );
  }

  Widget _buildContent(ApodModel apod) {
    return RefreshIndicator(
      onRefresh: _loadApodData,
      color: AppColors.cream,
      backgroundColor: AppColors.panel,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel Kartı
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.panel,
              child: Column(
                children: [
                  InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: CachedNetworkImage(
                      imageUrl: apod.url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: AppColors.panel,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 280,
                        color: AppColors.panel,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.mutedText,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Başlık & Tarih
            Text(
              apod.title,
              style: const TextStyle(
                color: AppColors.pale,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (apod.date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.peach,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    apod.date,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Açıklama Metni
            Linkify(
              onOpen: (link) => _launchUrl(link.url),
              text: apod.explanation,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
                height: 1.5,
              ),
              linkStyle: const TextStyle(
                color: AppColors.coral,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 24),

            // Aksiyon Butonları
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  // --- Paylaş ---
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareImage(apod),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Paylaş'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- İndir ---
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadImage(apod),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
