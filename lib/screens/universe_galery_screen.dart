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
import 'package:nasa_uzay_yolu/features/space/space_images_model.dart';

class SpaceGalleryScreen extends StatefulWidget {
  const SpaceGalleryScreen({super.key});

  @override
  State<SpaceGalleryScreen> createState() => _SpaceGalleryScreenState();
}

class _SpaceGalleryScreenState extends State<SpaceGalleryScreen> {
  List<SpaceImage> _images = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = 'galaxy';

  final List<Map<String, String>> _categories = [
    {'label': 'Galaksi', 'query': 'galaxy'},
    {'label': 'Nebula', 'query': 'nebula'},
    {'label': 'Jüpiter', 'query': 'jupiter'},
    {'label': 'Satürn', 'query': 'saturn'},
    {'label': 'Mars', 'query': 'mars'},
    {'label': 'Ay', 'query': 'moon'},
    {'label': 'Güneş', 'query': 'sun'},
    {'label': 'Yıldızlar', 'query': 'stars'},
    {'label': 'Kara Delik', 'query': 'black hole'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchImages(_currentQuery);
  }

  Future<void> _fetchImages(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuery = query;
      _images = [];
    });

    final service = NasaApiService();
    final images = await service.searchSpaceImages(query);

    if (!mounted) return;

    setState(() {
      _images = images;
      _isLoading = false;
      _errorMessage = images.isEmpty
          ? 'Bu kategoride fotoğraf bulunamadı.'
          : null;
    });
  }

  // --- YENİ: URL açma yardımcısı ---
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

  // --- YENİ: Görseli paylaş ---
  Future<void> _shareImage(SpaceImage image) async {
    try {
      await Share.share(
        '${image.title}\n\n${image.description}\n\n${image.imageUrl}',
        subject: image.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Paylaşım başarısız: $e')));
    }
  }

  // --- YENİ: Görseli galeriye indir ---
  Future<void> _downloadImage(SpaceImage image) async {
    try {
      // 1) Galeri izni
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2) Geçici klasöre indir
      final tempDir = await getTemporaryDirectory();
      final ext = image.imageUrl.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final fileName =
          'nasa_${image.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(image.imageUrl, filePath);

      // 3) Galeriye kaydet
      await Gal.putImage(filePath, album: 'NASA Uzay Galerisi');

      // 4) Geçici dosyayı temizle (opsiyonel)
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
          content: Text('İndirme başarısız: $e'),
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
        title: const Text('Nasa Universe Galery'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat['query'] == _currentQuery;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (_) => _fetchImages(cat['query']!),
                    backgroundColor: Colors.grey[900],
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return GestureDetector(
          onTap: () => _showImageDetails(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: image.id,
              child: CachedNetworkImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageDetails(SpaceImage image) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        bool isDownloading = false; // Popup içi state

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.grey[900],
              insetPadding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),

                  // Görsel
                  SizedBox(
                    height: 360,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Hero(
                        tag: image.id,
                        child: CachedNetworkImage(
                          imageUrl: image.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Başlık + tarih + açıklama
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            image.title,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (image.dateCreated.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              image.dateCreated,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Linkify(
                            onOpen: (link) => _launchUrl(link.url),
                            text: image.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            linkStyle: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 15,
                              height: 1.4,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- YENİ: Aksiyon butonları ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Paylaş
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareImage(image),
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
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    setDialogState(() => isDownloading = true);
                                    await _downloadImage(image);
                                    if (dialogContext.mounted) {
                                      setDialogState(
                                        () => isDownloading = false,
                                      );
                                    }
                                  },
                            icon: isDownloading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                            label: Text(
                              isDownloading ? 'Downloading...' : 'Download',
                              style: const TextStyle(color: Colors.black),
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
          },
        );
      },
    );
  }
}
