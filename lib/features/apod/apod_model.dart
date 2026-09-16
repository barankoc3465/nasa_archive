class ApodModel {
  final String title;
  final String explanation;
  final String url;

  // YENİ EKLENENLER:
  final String?
  hdurl; // Yüksek çözünürlüklü link (Bazen null gelebilir, o yüzden String?)
  final String mediaType; // Fotoğraf mı, video mu? ('image' veya 'video')
  final String date; // Hangi günün içeriği?

  ApodModel({
    required this.title,
    required this.explanation,
    required this.url,
    this.hdurl,
    required this.mediaType,
    required this.date,
  });

  // UI (Arayüz) tarafında hayat kurtaracak küçük bir yardımcı özellik
  bool get isImage => mediaType == 'image';

  factory ApodModel.fromJson(Map<String, dynamic> json) {
    return ApodModel(
      // 'as String?' diyerek Dart'a gelen verinin tipini kesin olarak söylüyoruz (Tip Güvenliği)
      title: json['title'] as String? ?? 'Başlık Yok',
      explanation: json['explanation'] as String? ?? 'Açıklama Yok',
      url: json['url'] as String? ?? '',

      hdurl: json['hdurl'] as String?,
      mediaType: json['media_type'] as String? ?? 'image',
      date: json['date'] as String? ?? '',
    );
  }
}
