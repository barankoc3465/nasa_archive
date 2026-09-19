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
    final dataValues = item['data'];
    final data = dataValues is List
        ? dataValues.whereType<Map<String, dynamic>>().firstOrNull
        : null;
    final linkValues = item['links'];
    final links = linkValues is List
        ? linkValues.whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    final previewLink =
        links
            .where((link) => link['rel'] == 'preview' && link['href'] is String)
            .firstOrNull ??
        links.firstOrNull;

    return SpaceImage(
      id: data?['nasa_id']?.toString() ?? '',
      title: data?['title']?.toString() ?? 'Başlık bulunamadı',
      description: data?['description']?.toString() ?? 'Açıklama bulunamadı.',
      imageUrl: (previewLink?['href']?.toString() ?? '').replaceFirst(
        'http://',
        'https://',
      ),
      dateCreated: data?['date_created']?.toString() ?? '',
    );
  }
}
