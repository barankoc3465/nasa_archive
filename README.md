# nasa_uzay_yolu

NASA API'lerinden görsel ve yıldız konumu verilerini alıp kullanıcıya uzay hakkında bilgi veren basit bir web uygulaması.

## Özellikler

- **APOD görseli**: `api.nasa.gov` üzerinden günün uzay görselini ve açıklamasını gösterir.
- **Yıldız konumu verisi**: NASA Exoplanet Archive üzerinden yıldız koordinatlarını (RA/Dec) listeler.

## Çalıştırma

Bu proje statik bir web uygulamasıdır.

1. Proje klasöründe bir HTTP sunucusu başlatın:

```bash
python -m http.server 8000
```

2. Tarayıcıda açın:

```text
http://localhost:8000
```

3. Gerekirse NASA API anahtarınızı girin (varsayılan: `DEMO_KEY`).
