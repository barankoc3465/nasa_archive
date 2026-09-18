import 'package:flutter/material.dart';
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

  // NASA Image Library'de aranacak kategoriler
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Evren Galerisi'),
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
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
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
      builder: (context) {
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
              SizedBox(
                height: 360,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Hero(
                    tag: image.id,
                    child: Image.network(
                      image.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                      Text(
                        image.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
