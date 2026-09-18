import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nasa_uzay_yolu/api/nasa_api_service.dart';
import 'package:nasa_uzay_yolu/features/apod/apod_model.dart';

class ApodScreen extends StatefulWidget {
  const ApodScreen({super.key});

  @override
  State<ApodScreen> createState() => _ApodScreenState();
}

class _ApodScreenState extends State<ApodScreen> {
  ApodModel? _apodData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final service = NasaApiService();
    final data = await service.fetchApod();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (data != null) {
        _apodData = data;
      } else {
        _errorMessage =
            "Uzayla iletişim kurulamadı. İnternetinizi kontrol edin.";
      }
    });
  }

  // --- URL açma yardımcısı ---
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
          .showSnackBar(SnackBar(content: Text('Bağlantı açılamadı: $e')));
    }
  }

  // --- Görseli paylaş (metin + URL) ---
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

  // --- Görseli galeriye indir ---
  Future<void> _downloadImage(ApodModel apod) async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final tempDir = await getTemporaryDirectory();
      final ext = apod.url.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final fileName = 'apod_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(apod.url, filePath);

      await Gal.putImage(filePath, album: 'NASA Uzay Galerisi');

      final f = File(filePath);
      if (await f.exists()) await f.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görsel galeriye kaydedildi ✓'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' İndirme başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Astronomy Picture of the Day'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _buildSuccessUI(),
    );
  }

  Widget _buildSuccessUI() {
    final apod = _apodData!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Görsel (önbellekli) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: apod.url,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // --- Başlık + Açıklama ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apod.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama — linkler tıklanabilir
                Linkify(
                  onOpen: (link) => _launchUrl(link.url),
                  text: apod.explanation,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  linkStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.lightBlueAccent,
                    height: 1.5,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
          ),

          // --- Aksiyon Butonları ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                // Paylaş
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareImage(apod),
                    icon: const Icon(
                      Icons.share,
                      color: Colors.orange,
                      size: 18,
                    ),
                    label: const Text(
                      'Share',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // İndir
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadImage(apod),
                    icon: const Icon(
                      Icons.download,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: const Text(
                      'Download',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
