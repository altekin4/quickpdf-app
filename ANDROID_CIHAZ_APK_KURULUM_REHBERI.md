# 📱 Android Cihaz APK Kurulum Rehberi

## 🚨 Mevcut Durum

### ❌ Yerel Build Sorunu
- **Sorun**: Flutter Impeller engine Windows'ta Türkçe karakterli path'te çalışmıyor
- **Hata**: `impellerc.exe` Türkçe "ı" karakterini tanımıyor
- **Path**: `C:\Users\AnılTekin\Desktop\dilekcego\` (Anıl'daki "ı" karakteri)

### ✅ Çözüm: GitHub Actions APK Build

## 🎯 Hızlı APK Kurulum Adımları

### 1. GitHub Actions ile APK Build
```bash
# Repository'yi push et
git add .
git commit -m "APK build için hazır"
git push origin main

# GitHub Actions otomatik APK build edecek
# Yaklaşık 5-10 dakika sürer
```

### 2. APK İndirme
1. GitHub repository'ye git: https://github.com/[username]/quickpdf-app
2. **Actions** sekmesine tıkla
3. En son **"Build Mobile APK"** workflow'unu aç
4. **Artifacts** bölümünden **"android-apk"** indir
5. ZIP dosyasını aç, içinde `app-release.apk` var

### 3. Android Cihaza Kurulum

#### A. USB ile Kurulum
```bash
# APK'yı cihaza kopyala
adb install app-release.apk

# Veya manuel:
# 1. APK'yı telefona kopyala (USB/Bluetooth)
# 2. Dosya yöneticisinden APK'ya tıkla
# 3. "Bilinmeyen kaynaklardan kuruluma izin ver"
# 4. Kur butonuna bas
```

#### B. Manuel Kurulum
1. **Developer Options** aktif et:
   - Ayarlar → Telefon Hakkında
   - "Build Number"a 7 kez tıkla
   
2. **USB Debugging** aktif et:
   - Ayarlar → Developer Options
   - USB Debugging ✅

3. **Unknown Sources** aktif et:
   - Ayarlar → Security
   - Unknown Sources ✅

4. APK'yı kur:
   - APK dosyasına tıkla
   - Install → Done

## 🔧 Alternatif Çözümler

### Çözüm 1: Path Değiştirme
```bash
# Türkçe karaktersiz path'e taşı
mkdir C:\dev\quickpdf
xcopy /E /I "C:\Users\AnılTekin\Desktop\dilekcego" "C:\dev\quickpdf"
cd C:\dev\quickpdf\quickpdf_app
flutter build apk --release
```

### Çözüm 2: Docker Build
```bash
# Docker container'da build et
docker run --rm -v ${PWD}:/workspace cirrusci/flutter:stable sh -c "cd /workspace/quickpdf_app && flutter build apk --release"
```

### Çözüm 3: GitHub Codespaces
1. GitHub'da repository aç
2. Code → Codespaces → Create codespace
3. Terminal'de:
```bash
cd quickpdf_app
flutter build apk --release
```

## 📋 APK Build Status

### ✅ Çalışan Yöntemler
- GitHub Actions (önerilen)
- Docker build
- GitHub Codespaces
- Türkçe karaktersiz path

### ❌ Çalışmayan Yöntemler
- Yerel Windows build (Türkçe path)
- Impeller engine bypass denemeleri

## 🎯 Önerilen Akış

1. **Geliştirme**: Yerel web/desktop test
```bash
flutter run -d chrome  # Web test
flutter run -d windows # Desktop test
```

2. **APK Build**: GitHub Actions kullan
```bash
git push origin main
# Actions'dan APK indir
```

3. **Test**: APK'yı cihaza kur ve test et

## 📱 Cihaz Bilgileri

**Bağlı Cihaz**: SM G990E (Samsung Galaxy S21)
- Android 16 (API 36)
- ARM64 architecture
- USB debugging aktif ✅

## 🚀 Sonraki Adımlar

1. **GitHub'a push et** → APK otomatik build olacak
2. **APK'yı indir** → Artifacts'tan
3. **Cihaza kur** → USB veya manuel
4. **Test et** → Tüm özellikler çalışıyor mu?

**APK build sorunu Türkçe path'ten kaynaklanıyor. GitHub Actions ile kesin çözüm!**