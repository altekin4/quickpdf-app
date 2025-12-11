# 🚀 GitHub Actions ile Android APK Kurulum Rehberi

## ✅ Hazırlık Tamamlandı
- ✅ Git repository oluşturuldu
- ✅ Tüm dosyalar commit edildi (370 dosya)
- ✅ GitHub Actions workflow hazır
- ✅ Android cihaz bağlı (SM G990E)

## 📋 Adım Adım Kurulum

### 🎯 Adım 1: GitHub Repository Oluştur

1. **GitHub.com'a git**: https://github.com
2. **Giriş yap** GitHub hesabınla
3. **"New repository" butonuna tıkla** (yeşil buton)
4. **Repository bilgilerini doldur**:
   - Repository name: `quickpdf-app`
   - Description: `QuickPDF Mobile App - PDF generation and template marketplace`
   - Public/Private: İstediğini seç
   - **Initialize this repository with:** hiçbirini seçme (boş bırak)
5. **"Create repository" butonuna tıkla**

### 🎯 Adım 2: Remote Repository Bağla

GitHub'da repository oluşturduktan sonra, sayfada gösterilen URL'yi kopyala ve şu komutu çalıştır:

```bash
git remote add origin https://github.com/[KULLANICI_ADIN]/quickpdf-app.git
```

**Örnek**: 
```bash
git remote add origin https://github.com/johndoe/quickpdf-app.git
```

### 🎯 Adım 3: Kodu GitHub'a Push Et

```bash
git branch -M main
git push -u origin main
```

### 🎯 Adım 4: GitHub Actions Çalıştır

1. **GitHub repository sayfasına git**
2. **"Actions" sekmesine tıkla** (üst menüde)
3. **"Build QuickPDF Mobile APK" workflow'unu bul**
4. **"Run workflow" butonuna tıkla** (sağ tarafta)
5. **Build type seç**: `debug` (varsayılan)
6. **"Run workflow" yeşil butonuna tıkla**

### 🎯 Adım 5: Build Sürecini İzle

- Build süreci 5-10 dakika sürer
- Yeşil ✅ işareti görene kadar bekle
- Kırmızı ❌ işareti görürsen, log'lara bak

### 🎯 Adım 6: APK'yı İndir

Build tamamlandığında:

1. **Actions sayfasında** tamamlanan workflow'a tıkla
2. **"Artifacts" bölümünü bul** (sayfanın altında)
3. **"quickpdf-mobile-debug-apks"** dosyasını indir
4. **ZIP dosyasını aç**
5. **APK dosyalarını gör**:
   - `app-arm64-v8a-debug.apk` (Samsung için önerilen)
   - `app-armeabi-v7a-debug.apk`
   - `app-x86_64-debug.apk`

### 🎯 Adım 7: APK'yı Android Cihaza Kur

1. **APK dosyasını** `output` klasörüne kopyala
2. **Kurulum script'ini çalıştır**:
   ```bash
   install-apk-to-device.bat
   ```

### 🎯 Adım 8: Uygulamayı Test Et

APK kurulduktan sonra:

1. **"QuickPDF" uygulamasını aç**
2. **Test hesaplarıyla giriş yap**:
   - Email: `test@test.com`
   - Şifre: `123456`
3. **Özellikleri test et**

## 🔧 Sorun Giderme

### GitHub Actions Build Hatası
- **Log'ları kontrol et**: Actions → Workflow → Build log
- **Yeniden çalıştır**: "Re-run jobs" butonuna tıkla

### APK Kurulum Hatası
- **USB Debugging açık mı?** Ayarlar → Geliştirici Seçenekleri
- **Bilinmeyen kaynaklar izni var mı?** Ayarlar → Güvenlik
- **ADB çalışıyor mu?** `adb devices` komutu

### Cihaz Tanınmıyor
```bash
adb kill-server
adb start-server
adb devices
```

## 📱 Beklenen Sonuç

✅ **Başarılı kurulum sonrası**:
- QuickPDF uygulaması cihazda görünür
- Splash screen açılır
- Login ekranı çalışır
- Ana ekran ve özellikler kullanılabilir

## 🎉 Tamamlandı!

Bu adımları takip ederek GitHub Actions ile APK build alıp Android cihazına kurabilirsin. Herhangi bir sorun yaşarsan, log'ları kontrol et veya yardım iste.

---

**💡 İpucu**: İlk build biraz uzun sürebilir, sabırlı ol. Sonraki build'ler daha hızlı olacak.