@echo off
chcp 65001 >nul
echo ========================================
echo    QuickPDF APK Build Workaround
echo ========================================
echo.

REM Türkçe karakter sorunu için geçici çözüm
echo 🔧 Türkçe karakter sorunu tespit edildi
echo 💡 GitHub Actions ile build öneriliyor
echo.

echo 📋 Mevcut seçenekler:
echo.
echo 1. 🌐 Web versiyonunu test et (Hemen çalışır)
echo 2. 🚀 GitHub Actions ile APK build et (Önerilen)
echo 3. 📱 Codemagic ile online build
echo 4. 🔄 Flutter sürümünü güncelle ve tekrar dene
echo.

set /p CHOICE=Seçiminizi yapın (1-4): 

if "%CHOICE%"=="1" (
    echo.
    echo 🌐 Web versiyonu başlatılıyor...
    cd quickpdf_app
    start "" flutter run -d chrome --web-port 8090 -t lib/main_mobile.dart
    echo.
    echo ✅ Web versiyonu başlatıldı!
    echo 🔗 Adres: http://localhost:8090
    echo 📱 Tarayıcıda F12 → Mobil görünüm seçin
    echo.
    echo 📋 Test hesapları:
    echo • test@test.com / 123456
    echo • admin@quickpdf.com / admin123
    echo • creator@quickpdf.com / creator123
    goto :end
)

if "%CHOICE%"=="2" (
    echo.
    echo 🚀 GitHub Actions kurulumu...
    echo.
    echo 📋 Adımlar:
    echo 1. GitHub'da yeni repository oluşturun
    echo 2. Proje dosyalarını yükleyin
    echo 3. Actions otomatik çalışacak
    echo 4. APK'yı Artifacts'ten indirin
    echo.
    echo 📁 GitHub Actions dosyası hazır: .github/workflows/build-apk.yml
    echo.
    explorer .github\workflows
    goto :end
)

if "%CHOICE%"=="3" (
    echo.
    echo 📱 Codemagic online build...
    echo.
    echo 📋 Adımlar:
    echo 1. https://codemagic.io/ adresine gidin
    echo 2. GitHub hesabınızla giriş yapın
    echo 3. Repository'nizi bağlayın
    echo 4. Build başlatın
    echo.
    start "" https://codemagic.io/
    goto :end
)

if "%CHOICE%"=="4" (
    echo.
    echo 🔄 Flutter güncelleniyor...
    flutter upgrade
    echo.
    echo ✅ Flutter güncellendi!
    echo 🔄 Tekrar build deneniyor...
    cd quickpdf_app
    flutter clean
    flutter pub get
    flutter build apk --debug -t lib/main_mobile.dart --verbose
    goto :end
)

echo ❌ Geçersiz seçim!

:end
echo.
echo 💡 Sorun: Türkçe karakterli dosya yolu shader compilation'ı engelliyor
echo 🔧 Çözüm: GitHub Actions veya online build servisleri kullanın
echo.
pause