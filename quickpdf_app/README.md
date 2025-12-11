# QuickPDF Mobile App

QuickPDF, kullanıcıların kolayca PDF belgesi oluşturması sağlayan ve dinamik şablon pazaryeri özelliği sunan bir mobil uygulamadır.

## Özellikler

### MVP Özellikleri
- ✅ Basit metin → PDF dönüştürme
- ✅ Temel düzenleme özellikleri (yazı tipi, boyut, tarih)
- ✅ Offline çalışma
- ✅ Local storage ile belge geçmişi
- ✅ Clean Architecture yapısı
- ✅ State management (Provider)
- ✅ Routing (GoRouter)

### Gelecek Özellikler
- 🔄 Dinamik şablon sistemi
- 🔄 Şablon pazaryeri
- 🔄 Kullanıcı kimlik doğrulama
- 🔄 Ödeme sistemi
- 🔄 Admin paneli

## Teknoloji Stack

- **Framework:** Flutter 3.10+
- **State Management:** Provider
- **Routing:** GoRouter
- **Local Storage:** SQLite, SharedPreferences
- **PDF Generation:** pdf package
- **HTTP Client:** Dio
- **Architecture:** Clean Architecture

## Proje Yapısı

```
lib/
├── core/                 # Temel konfigürasyon ve yardımcılar
│   ├── app_config.dart
│   └── theme/
├── domain/              # İş mantığı ve entity'ler
│   └── entities/
├── data/                # Veri katmanı (gelecekte eklenecek)
└── presentation/        # UI katmanı
    ├── providers/       # State management
    ├── router/          # Routing konfigürasyonu
    └── screens/         # UI ekranları
```

## Kurulum

1. Flutter SDK'yı yükleyin (3.10 veya üzeri)
2. Projeyi klonlayın
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## Geliştirme

### Yeni Ekran Ekleme
1. `lib/presentation/screens/` altında yeni klasör oluşturun
2. Screen widget'ını oluşturun
3. `app_router.dart` dosyasına route ekleyin

### Yeni Provider Ekleme
1. `lib/presentation/providers/` altında provider oluşturun
2. `app_providers.dart` dosyasına ekleyin

### Test Çalıştırma
```bash
flutter test
```

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add some amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.