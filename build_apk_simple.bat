@echo off
echo QuickPDF APK Build Script
echo.

cd quickpdf_app

echo 1. Cache temizleniyor...
flutter clean
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

echo.
echo 2. Dependencies alınıyor...
flutter pub get

echo.
echo 3. APK build ediliyor (basit mod)...
flutter build apk --debug --verbose

echo.
echo 4. APK konumu kontrol ediliyor...
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ APK başarıyla oluşturuldu!
    echo Konum: build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo 5. Cihaza kuruluyor...
    flutter install --device-id RFCW41B4FSR
) else (
    echo ❌ APK oluşturulamadı
    echo.
    echo Alternatif: Web versiyonu çalıştırılıyor...
    start http://localhost:8081
)

pause