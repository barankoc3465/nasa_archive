# NASA Uzay Yolu

NASA APOD ve NASA Image Library verilerini gösteren Flutter uygulaması.

## Özellikler

- Astronomy Picture of the Day: başlık, tarih, açıklama, paylaşma ve indirme.
- Universe Gallery: kategori araması, görsel metadata'sı, popup detay ve zoom.
- Görsel disk önbelleği ve API yanıtları için kısa süreli bellek önbelleği.

## Kurulum

1. `.env.example` dosyasını `.env` olarak kopyalayın.
2. `.env` içine NASA anahtarınızı ekleyin:

```text
API_KEY=your_nasa_api_key
```

3. Bağımlılıkları yükleyin ve uygulamayı çalıştırın:

```bash
flutter pub get
flutter run
```

USB Android cihaz için:

```bash
flutter devices
flutter run -d DEVICE_ID
```

## Notlar

`.env` dosyası APK içine asset olarak dahil edildiği için API anahtarı mobil uygulamada tamamen gizli değildir. Üretim güvenliği için NASA isteklerini bir backend proxy üzerinden geçirmek gerekir.

# nasa_uzay_yolu

nasa api'yı ile görselleri ve yıldız konumu verilerini alıp, uygulamamızın içerisinde kullanıcıya uzay hakkında bilgi veren bir proje

lib/
core/ # Uygulama genelinde kullanılacak ortak şeyler
api/ # API servis sınıfları ve interceptorlar
constants/ # Renkler, sabit metinler, API URL'leri vb.
widgets/ # Ortak butonlar, yükleme animasyonları vb.
features/ # Uygulamanın ana özellikleri
apod/ # Günün Astronomi Görseli özelliği (UI, Bloc/Provider, Model)
mars_rovers/ # Mars fotoğrafları özelliği
main.dart # Uygulama başlangıç noktası

flutter pub add dio cached_network_image provider
