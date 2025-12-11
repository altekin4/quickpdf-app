@echo off
echo ========================================
echo       QuickPDF Mobile APK Builder
echo ========================================
echo.

cd quickpdf_app

echo Mobil uygulama APK'sı build ediliyor...
echo Target: lib/main_mobile.dart
echo.

REM Cache temizle
flutter clean

REM Dependencies al
flutter pub get

REM APK build et
flutter build apk --debug -t lib/main_mobile.dart

if errorlevel 1 (
    echo.
    echo ❌ APK build başarısız!
    echo.
    echo Alternatif çözümler:
    echo 1. Web versiyonu test edin: flutter run -d chrome -t lib/main_mobile.dart
    echo 2. GitHub Actions kullanın
    echo 3. Android SDK'yı kontrol edin
    pause
    exit /b 1
)

echo.
echo ✅ Mobil APK başarıyla oluşturuldu!
echo.
echo APK Konumu:
echo %cd%\build\app\outputs\flutter-apk\app-debug.apk
echo.

REM Cihaza kurulum seçeneği
flutter devices | findstr "android" >nul
if not errorlevel 1 (
    echo Android cihaz bulundu. Kurmak ister misiniz? (y/n)
    set /p INSTALL_CHOICE=
    if /i "%INSTALL_CHOICE%"=="y" (
        echo Cihaza kuruluyor...
        flutter install -t lib/main_mobile.dart
        if not errorlevel 1 (
            echo ✅ Uygulama cihaza kuruldu!
        )
    )
)

echo.
echo İşlem tamamlandı!
pause