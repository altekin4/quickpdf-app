# 📱 QuickPDF Android Test Rehberi

## 🚀 Hızlı Test Başlangıcı

### Seçenek 1: Flutter Kurulumu (Önerilen)

#### 1. Flutter SDK Kurulumu
```bash
# 1. Flutter SDK'yı indirin
# https://docs.flutter.dev/get-started/install/windows

# 2. ZIP dosyasını C:\flutter klasörüne çıkarın

# 3. System PATH'e ekleyin
# C:\flutter\bin

# 4. Kurulumu doğrulayın
flutter doctor
```

#### 2. Android Studio Kurulumu
```bash
# 1. Android Studio'yu indirin ve kurun
# https://developer.android.com/studio

# 2. Android SDK'yı kurun
# Tools > SDK Manager > Android SDK

# 3. Android cihazınızı USB ile bağlayın
# Developer Options > USB Debugging açın
```

#### 3. Uygulamayı Çalıştırın
```bash
# Proje klasörüne gidin
cd quickpdf_app

# Bağımlılıkları yükleyin
flutter pub get

# Cihazları listeleyin
flutter devices

# Uygulamayı çalıştırın
flutter run
```

### Seçenek 2: APK Oluşturma (Flutter Kurulu Değilse)

#### 1. Hazır APK İndirme
Eğer Flutter kurulumu yapmak istemiyorsanız, size hazır bir APK dosyası oluşturabilirim. Bunun için:

1. **GitHub Actions** ile otomatik build
2. **Online Flutter Builder** servisleri
3. **Docker** ile Flutter environment

#### 2. Manuel APK Build (Flutter Kurulduktan Sonra)
```bash
# Debug APK oluştur
flutter build apk --debug

# Release APK oluştur (imzalama gerekli)
flutter build apk --release

# APK dosyası lokasyonu:
# build/app/outputs/flutter-apk/app-debug.apk
```

## 🔧 Test Senaryoları

### 1. Temel Fonksiyonalite Testleri

#### PDF Oluşturma Testi
- [ ] Ana ekranda "Yeni PDF" butonuna tıklayın
- [ ] Metin girin ve formatlamayı test edin
- [ ] PDF oluştur butonuna basın
- [ ] PDF'in başarıyla oluşturulduğunu kontrol edin

#### Çevrimdışı Test
- [ ] Uçak modunu açın (WiFi/Mobile data kapatın)
- [ ] Uygulamayı açın
- [ ] PDF oluşturma işlemini test edin
- [ ] Çevrimdışı göstergesinin görünür olduğunu kontrol edin

#### Şablon Testi
- [ ] Şablonlar sekmesine gidin
- [ ] Mevcut şablonları görüntüleyin
- [ ] Bir şablon seçin ve formu doldurun
- [ ] Şablondan PDF oluşturun

### 2. Performans Testleri

#### Uygulama Başlatma
- [ ] Uygulamanın 3 saniye içinde açıldığını kontrol edin
- [ ] Splash screen'in düzgün göründüğünü kontrol edin
- [ ] Ana ekranın sorunsuz yüklendiğini kontrol edin

#### PDF Oluşturma Performansı
- [ ] Kısa metin (100 kelime) - 1 saniye içinde
- [ ] Orta metin (500 kelime) - 2 saniye içinde
- [ ] Uzun metin (1000+ kelime) - 3 saniye içinde

#### Bellek Kullanımı
- [ ] Uygulamanın 100MB altında RAM kullandığını kontrol edin
- [ ] Çoklu PDF oluşturma sonrası bellek sızıntısı olmadığını kontrol edin

### 3. Kullanıcı Deneyimi Testleri

#### Navigasyon
- [ ] Alt menü sekmelerinin düzgün çalıştığını kontrol edin
- [ ] Geri butonunun doğru çalıştığını kontrol edin
- [ ] Ekranlar arası geçişlerin akıcı olduğunu kontrol edin

#### Hata Durumları
- [ ] İnternet bağlantısı kesildiğinde uygun mesaj gösterildiğini kontrol edin
- [ ] Geçersiz veri girişinde hata mesajları gösterildiğini kontrol edin
- [ ] Uygulama çökmelerinin olmadığını kontrol edin

### 4. Türkçe Karakter Testleri

#### PDF İçeriği
- [ ] "çÇ, ğĞ, ıI, İi, öÖ, şŞ, üÜ" karakterlerini test edin
- [ ] Türkçe metin formatlamasının doğru olduğunu kontrol edin
- [ ] PDF'te Türkçe karakterlerin düzgün göründüğünü kontrol edin

## 🐛 Hata Raporlama

Test sırasında karşılaştığınız sorunları şu formatta rapor edin:

```
**Hata Türü:** [Çökme/Performans/UI/Fonksiyonalite]
**Adımlar:**
1. ...
2. ...
3. ...

**Beklenen Sonuç:** ...
**Gerçek Sonuç:** ...
**Cihaz Bilgisi:** [Android sürümü, cihaz modeli]
**Ekran Görüntüsü:** [Varsa ekleyin]
```

## 📊 Test Sonuçları Formu

### Genel Değerlendirme
- [ ] Mükemmel (5/5)
- [ ] İyi (4/5)
- [ ] Orta (3/5)
- [ ] Zayıf (2/5)
- [ ] Çok Zayıf (1/5)

### Özellik Bazlı Değerlendirme
- **PDF Oluşturma:** ⭐⭐⭐⭐⭐
- **Çevrimdışı Çalışma:** ⭐⭐⭐⭐⭐
- **Kullanıcı Arayüzü:** ⭐⭐⭐⭐⭐
- **Performans:** ⭐⭐⭐⭐⭐
- **Kararlılık:** ⭐⭐⭐⭐⭐

### Yorumlar ve Öneriler
```
[Test deneyiminizi ve önerilerinizi buraya yazın]
```

## 🔄 Sonraki Adımlar

Test tamamlandıktan sonra:
1. **Hata raporlarını** toplayın
2. **Performans metriklerini** kaydedin
3. **Kullanıcı geri bildirimlerini** not alın
4. **İyileştirme önerilerini** listeleyin

## 📞 Destek

Test sırasında sorun yaşarsanız:
- Hata mesajlarını tam olarak kaydedin
- Ekran görüntüleri alın
- Cihaz bilgilerini not edin
- Adım adım ne yaptığınızı açıklayın