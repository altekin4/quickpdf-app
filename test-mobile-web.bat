@echo off
chcp 65001 >nul
echo ========================================
echo    QuickPDF Mobil Web Test
echo ========================================
echo.

REM Mevcut dizini kontrol et
if not exist "quickpdf_app\pubspec.yaml" (
    echo ❌ quickpdf_app klasörü bulunamadı!
    echo Bu scripti ana proje klasöründe çalıştırın
    pause
    exit /b 1
)

echo ✅ Proje klasörü bulundu
echo.

REM quickpdf_app klasörüne geç
cd quickpdf_app

echo 📦 Bağımlılıklar kontrol ediliyor...
flutter pub get

echo.
echo 🌐 Mobil uygulama web versiyonu başlatılıyor...
echo.
echo 📱 Tarayıcınızda mobil görünüm için:
echo 1. F12 tuşuna basın (Geliştirici araçları)
echo 2. Mobil simgesine tıklayın (📱)
echo 3. Cihaz seçin (iPhone, Samsung vb.)
echo.
echo 🔗 Adres: http://localhost:8089
echo.
echo 📋 Test hesapları:
echo • test@test.com / 123456 (Normal kullanıcı)
echo • admin@quickpdf.com / admin123 (Admin)
echo • creator@quickpdf.com / creator123 (İçerik üreticisi)
echo.
echo ⏹️ Durdurmak için Ctrl+C tuşlarına basın
echo.

REM Web sunucusunu başlat
flutter run -d chrome --web-port 8089 -t lib/main_mobile.dart

cd ..
pause