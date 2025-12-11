# QuickPDF APK Build Rehberi

## 🚀 Hızlı Başlangıç

### 1. En Kolay Yöntem - Build Menüsü
```bash
# Ana klasörde çalıştırın
quick-build-menu.bat
```

### 2. Tek Komut Build
```bash
# Debug APK
build-apk.bat debug

# Release APK
build-apk.bat release
```

### 3. PowerShell ile Build
```powershell
# Debug APK
.\Build-APK.ps1 -BuildType debug

# Release APK + Cihaza Kur
.\Build-APK.ps1 -BuildType release -Install

# Cache temizle + Build
.\Build-APK.ps1 -BuildType debug -Clean
```

## 🌐 GitHub Actions ile Otomatik Build

### Kurulum
1. Projeyi GitHub'a push edin
2. Repository'de Actions sekmesine gidin
3. "Build QuickPDF APK" workflow'unu çalıştırın

### Manuel Tetikleme
1. Actions sekmesinde "Build QuickPDF APK"
2. "Run workflow" butonuna tıklayın
3. Build type seçin (debug/release)
4. "Run workflow" ile başlatın

### APK İndirme
1. Workflow tamamlandıktan sonra
2. "Artifacts" bölümünden APK'ları indirin
3. ZIP dosyasını açın

## 🐳 Docker ile Build (Alternatif)

```bash
# Docker image oluştur
docker build -f Dockerfile.build -t quickpdf-builder .

# APK build et
docker-build.bat debug
```

## 📱 Cihaza Kurulum

### Otomatik Kurulum
```bash
# Build + Install
build-apk.bat debug
# Menüden "Cihaza kur" seçeneğini seçin
```

### Manuel Kurulum
```bash
# APK dosyasını bul
cd quickpdf_app\build\app\outputs\flutter-apk

# Cihaza kur
adb install app-arm64-v8a-debug.apk
```

## 🔧 Sorun Giderme

### Shader Compilation Hatası
```bash
# Kısa yol kullanın
mkdir C:\quickpdf
copy quickpdf_app C:\quickpdf\
cd C:\quickpdf\quickpdf_app
flutter build apk --debug
```

### Android SDK Bulunamadı
```bash
flutter config --android-sdk "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
```

### Cihaz Bulunamadı
```bash
# USB Debugging açık olduğundan emin olun
adb devices
flutter devices
```

## 📋 Build Çıktıları

### Debug APK'lar
- `app-arm64-v8a-debug.apk` (64-bit ARM - Modern cihazlar)
- `app-armeabi-v7a-debug.apk` (32-bit ARM - Eski cihazlar)
- `app-x86_64-debug.apk` (64-bit x86 - Emulator)

### Release APK'lar
- `app-arm64-v8a-release.apk` (Üretim - 64-bit)
- `app-armeabi-v7a-release.apk` (Üretim - 32-bit)
- `app-x86_64-release.apk` (Üretim - Emulator)

## ⚡ Hızlı Komutlar

```bash
# Hızlı debug build
quick-build-menu.bat

# Web'de test
cd quickpdf_app && flutter run -d chrome

# Cihazları listele
flutter devices

# Flutter durumu
flutter doctor

# APK klasörünü aç
explorer quickpdf_app\build\app\outputs\flutter-apk
```

## 🎯 Önerilen Workflow

1. **Geliştirme**: Web versiyonu kullanın (`flutter run -d chrome`)
2. **Test**: Debug APK ile test edin (`build-apk.bat debug`)
3. **Üretim**: GitHub Actions ile release APK oluşturun
4. **Dağıtım**: Release APK'yı kullanıcılara gönderin

## 📞 Destek

Sorun yaşarsanız:
1. `flutter doctor -v` çalıştırın
2. `quick-build-menu.bat` menüsünden "Flutter Doctor" seçin
3. GitHub Actions loglarını kontrol edin
4. Web versiyonunu test edin