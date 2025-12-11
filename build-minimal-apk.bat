@echo off
chcp 65001 >nul
color 0E
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██        📱 Minimal APK Build - USB Install              ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.

echo 🎯 Minimal APK build stratejisi...
echo.

cd quickpdf_app

REM Check device
echo 📱 Cihaz kontrolü...
flutter devices | findstr "SM G990E"
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Android cihaz bulunamadı!
    echo 💡 USB debugging aktif mi kontrol edin.
    pause
    exit /b 1
)

echo ✅ Cihaz bulundu: SM G990E
echo.

REM Clean build
echo 🧹 Build temizliği...
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Clean işlemi tamamlanamadı, devam ediliyor...
)

REM Get dependencies
echo 📦 Dependencies alınıyor...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Dependencies alınamadı!
    pause
    exit /b 1
)

echo.
echo 🔨 APK Build (Minimal)...
echo ⏳ Bu işlem birkaç dakika sürebilir...
echo.

REM Try minimal build first
flutter build apk --debug --target-platform android-arm64

if %ERRORLEVEL% EQU 0 (
    echo ✅ Debug APK build başarılı!
    set APK_FILE=build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo ⚠️  Debug build başarısız, release deneniyor...
    flutter build apk --release --target-platform android-arm64
    
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Release APK build başarılı!
        set APK_FILE=build\app\outputs\flutter-apk\app-release.apk
    ) else (
        echo ❌ APK build başarısız!
        echo.
        echo 🔍 Hata detayları için verbose build:
        flutter build apk --debug --verbose
        pause
        exit /b 1
    )
)

echo.
echo 📱 APK cihaza yükleniyor...
if exist "%APK_FILE%" (
    adb install "%APK_FILE%"
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✅ APK başarıyla yüklendi!
        echo 🎉 Cihazınızda "QuickPDF" uygulamasını açabilirsiniz.
        echo.
        echo 📋 APK Bilgileri:
        echo • Dosya: %APK_FILE%
        dir "%APK_FILE%" | findstr "app-"
    ) else (
        echo.
        echo ⚠️  Otomatik yükleme başarısız!
        echo 💡 Manuel yükleme için:
        echo 1. APK dosyasını telefona kopyalayın: %APK_FILE%
        echo 2. Dosya yöneticisinden APK'ya tıklayın
        echo 3. "Bilinmeyen kaynaklardan kuruluma izin ver"
        echo 4. Kur butonuna basın
    )
) else (
    echo ❌ APK dosyası bulunamadı: %APK_FILE%
)

echo.
echo ========================================
echo           İşlem Tamamlandı!
echo ========================================
echo.
pause