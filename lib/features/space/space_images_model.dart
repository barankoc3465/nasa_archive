class SpaceImage {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String dateCreated;

  const SpaceImage({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dateCreated,
  });

  factory SpaceImage.fromNasaItem(Map<String, dynamic> item) {
    final data = (item['data'] as List<dynamic>?)?.firstWhere(
      (value) => value is Map,
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;
    final links = item['links'] as List<dynamic>? ?? [];
    final previewLink = links.cast<Map>().firstWhere(
      (link) => link['rel'] == 'preview' && link['href'] is String,
      orElse: () => links.cast<Map>().isNotEmpty
          ? links.cast<Map>().first
          : <String, dynamic>{},
    );

    return SpaceImage(
      id: data['nasa_id']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Başlık bulunamadı',
      description: data['description']?.toString() ?? 'Açıklama bulunamadı.',
      imageUrl: (previewLink['href']?.toString() ?? '').replaceFirst(
        'http://',
        'https://',
      ),
      dateCreated: data['date_created']?.toString() ?? '',
    );
  }
}
