import 'package:flutter_test/flutter_test.dart';
import 'package:nasa_uzay_yolu/features/space/space_images_model.dart';

void main() {
  test('NASA image metadata is parsed safely', () {
    final image = SpaceImage.fromNasaItem({
      'data': [
        {
          'nasa_id': 'abc123',
          'title': 'Galaxy',
          'description': 'A distant galaxy.',
          'date_created': '2024-01-01T00:00:00Z',
        },
      ],
      'links': [
        {'rel': 'preview', 'href': 'http://example.com/galaxy.jpg'},
      ],
    });

    expect(image.id, 'abc123');
    expect(image.title, 'Galaxy');
    expect(image.description, 'A distant galaxy.');
    expect(image.imageUrl, 'https://example.com/galaxy.jpg');
  });

  test('NASA image metadata tolerates missing fields', () {
    final image = SpaceImage.fromNasaItem({});

    expect(image.id, isEmpty);
    expect(image.imageUrl, isEmpty);
    expect(image.title, 'Başlık bulunamadı');
  });
}
