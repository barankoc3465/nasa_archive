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
