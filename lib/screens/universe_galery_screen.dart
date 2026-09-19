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
import 'package:nasa_uzay_yolu/core/theme/app_theme.dart';
import 'package:nasa_uzay_yolu/features/space/space_images_model.dart';

class SpaceGalleryScreen extends StatefulWidget {
  const SpaceGalleryScreen({super.key});

  @override
  State<SpaceGalleryScreen> createState() => _SpaceGalleryScreenState();
}

class _SpaceGalleryScreenState extends State<SpaceGalleryScreen> {
  final NasaApiService _apiService = NasaApiService();
  List<SpaceImage> _images = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = 'galaxy';
  int _requestVersion = 0;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<Map<String, String>> _categories = [
    {'label': 'Galaxy', 'query': 'galaxy'},
    {'label': 'Nebula', 'query': 'nebula'},
    {'label': 'Jupiter', 'query': 'jupiter'},
    {'label': 'Saturn', 'query': 'saturn'},
    {'label': 'Uranus', 'query': 'uranus'},
    {'label': 'Neptune', 'query': 'neptune'},
    {'label': 'Moon', 'query': 'moon'},
    {'label': 'Sun', 'query': 'sun'},
    {'label': 'Star', 'query': 'star'},
    {'label': 'Planet', 'query': 'planet'},
    {'label': 'Asteroid', 'query': 'asteroid'},
    {'label': 'Comet', 'query': 'comet'},
    {'label': 'Space Shuttle', 'query': 'space shuttle'},
    {
      'label': 'International Space Station',
      'query': 'international space station',
    },
    {'label': 'Black Hole', 'query': 'black hole'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchImages(_currentQuery);
  }

  Future<void> _fetchImages(String query) async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuery = query;
      _images = [];
      _currentPage = 1;
      _isLoadingMore = false;
      _hasMore = true;
    });

    final images = await _apiService.searchSpaceImages(query, page: 1);

    if (!mounted || requestVersion != _requestVersion) return;

    setState(() {
      _images = images;
      _isLoading = false;
      _hasMore = images.length >= 24;
      _errorMessage = images.isEmpty
          ? 'Bu kategoride fotoğraf bulunamadı.'
          : null;
    });
  }

  Future<void> _loadMoreImages() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    final requestVersion = _requestVersion;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final images = await _apiService.searchSpaceImages(
      _currentQuery,
      page: nextPage,
    );

    if (!mounted || requestVersion != _requestVersion) return;

    setState(() {
      _isLoadingMore = false;
      if (images.isEmpty) {
        _hasMore = false;
      } else {
        _images = [..._images, ...images];
        _currentPage = nextPage;
        _hasMore = images.length >= 24;
      }
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
      if (!await Gal.hasAccess()) {
        throw Exception('Galeri izni verilmedi.');
      }

      // 2) Geçici klasöre indir
      final tempDir = await getTemporaryDirectory();
      final ext = image.imageUrl.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final fileName =
          'nasa_${image.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 30);
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
        title: const Text('Nasa Universe Galery'),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _currentQuery == 'galaxy'
                ? const [AppColors.deepViolet, AppColors.ink]
                : const [AppColors.magenta, AppColors.deepViolet],
          ),
        ),
        child: Column(
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
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cream),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.mutedText),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final image = _images[index];
              return GestureDetector(
                onTap: () => _showImageDetails(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: image.id,
                    child: CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      cacheKey: image.id,
                      memCacheWidth: 540,
                      maxWidthDiskCache: 540,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.panel,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.panel,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.mutedText,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: _images.length),
          ),
        ),
        if (_hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingMore ? null : _loadMoreImages,
                  icon: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    _isLoadingMore ? 'Loading...' : 'Load more images',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showImageDetails(SpaceImage image) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.9),
      builder: (dialogContext) {
        bool isDownloading = false; // Popup içi state

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.panel,
              insetPadding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.pale),
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
                          cacheKey: image.id,
                          memCacheWidth: 1080,
                          maxWidthDiskCache: 1080,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: AppColors.panel,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.mutedText,
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
                              color: AppColors.peach,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (image.dateCreated.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              image.dateCreated,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Linkify(
                            onOpen: (link) => _launchUrl(link.url),
                            text: image.description,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            linkStyle: const TextStyle(
                              color: AppColors.coral,
                              fontSize: 15,
                              height: 1.4,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.coral,
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
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
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
                                    ),
                                  )
                                : const Icon(Icons.download, size: 18),
                            label: Text(
                              isDownloading ? 'Downloading...' : 'Download',
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
