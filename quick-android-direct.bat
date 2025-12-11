@echo off
chcp 65001 >nul
echo ========================================
echo    QuickPDF Android Direkt Build
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

echo 🔍 Flutter durumu kontrol ediliyor...
flutter doctor --android-licenses >nul 2>&1
flutter doctor

echo.
echo 📱 Bağlı cihazlar kontrol ediliyor...
flutter devices

echo.
echo 🧹 Önbellek temizleniyor...
flutter clean

echo.
echo 📦 Bağımlılıklar indiriliyor...
flutter pub get

echo.
echo 🔨 APK build ediliyor (shader sorununu önlemek için özel parametreler)...
flutter build apk --debug -t lib/main_mobile.dart --no-tree-shake-icons --dart-define=FLUTTER_WEB_USE_SKIA=false --verbose

if errorlevel 1 (
    echo.
    echo ❌ APK build başarısız!
    echo.
    echo 🔧 Alternatif build parametreleri deneniyor...
    flutter build apk --debug -t lib/main_mobile.dart --no-shrink --no-obfuscate
    
    if errorlevel 1 (
        echo.
        echo ❌ Alternatif build de başarısız!
        echo.
        echo 💡 Öneriler:
        echo 1. Web versiyonunu test edin: flutter run -d chrome -t lib/main_mobile.dart
        echo 2. GitHub Actions kullanın
        echo 3. Flutter sürümünü güncelleyin: flutter upgrade
        echo.
        pause
        exit /b 1
    )
)

echo.
echo ✅ APK başarıyla oluşturuldu!
echo 📍 Konum: build\app\outputs\flutter-apk\app-debug.apk
echo.

REM APK dosyasının varlığını kontrol et
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo 📱 Android cihaz kontrolü...
    flutter devices | findstr "android" >nul
    if not errorlevel 1 (
        echo ✅ Android cihaz bulundu!
        echo.
        set /p INSTALL_CHOICE=Cihaza kurmak ister misiniz? (y/n): 
        if /i "%INSTALL_CHOICE%"=="y" (
            echo.
            echo 📲 Cihaza kuruluyor...
            flutter install -t lib/main_mobile.dart
            if not errorlevel 1 (
                echo.
                echo 🎉 Uygulama başarıyla kuruldu!
                echo.
                echo 📋 Test hesapları:
                echo • test@test.com / 123456 (Normal kullanıcı)
                echo • admin@quickpdf.com / admin123 (Admin)
                echo • creator@quickpdf.com / creator123 (İçerik üreticisi)
                echo.
                echo 🚀 Uygulamayı cihazınızda açabilirsiniz!
            ) else (
                echo ❌ Kurulum başarısız!
                echo.
                echo 📋 Manuel kurulum için:
                echo 1. APK dosyasını cihaza kopyalayın
                echo 2. Dosya yöneticisinden açın
                echo 3. "Bilinmeyen kaynaklardan kurulum"a izin verin
                echo 4. Kurulumu tamamlayın
            )
        )
    ) else (
        echo ⚠️ Android cihaz bulunamadı
        echo.
        echo 📋 Manuel kurulum için:
        echo 1. APK dosyasını USB ile cihaza kopyalayın
        echo 2. Cihazda dosya yöneticisini açın
        echo 3. APK dosyasına tıklayın
        echo 4. "Bilinmeyen kaynaklardan kurulum"a izin verin
        echo 5. Kurulumu tamamlayın
    )
) else (
    echo ❌ APK dosyası oluşturulamadı!
)

echo.
echo ✅ İşlem tamamlandı!
cd ..
pause