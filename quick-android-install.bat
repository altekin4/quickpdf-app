@echo off
echo ========================================
echo    QuickPDF Android Hızlı Kurulum
echo ========================================
echo.

REM Yönetici yetkisi kontrolü
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Bu script yönetici yetkisi gerektirir!
    echo Sağ tık → "Yönetici olarak çalıştır" seçin
    pause
    exit /b 1
)

echo ✅ Yönetici yetkisi var
echo.

REM Kısa yol oluştur
echo 📁 Kısa yol oluşturuluyor...
if not exist "C:\quickpdf" mkdir "C:\quickpdf"

echo 📋 Proje dosyaları kopyalanıyor...

REM Önce hedef klasörü temizle
if exist "C:\quickpdf\app" rmdir /s /q "C:\quickpdf\app" >nul 2>&1

REM Robocopy ile kopyala (daha güvenilir)
robocopy "quickpdf_app" "C:\quickpdf\app" /E /R:3 /W:1 /NFL /NDL /NJH /NJS

REM Robocopy exit kodları: 0-7 başarılı, 8+ hata
if %errorlevel% geq 8 (
    echo ❌ Dosya kopyalama başarısız! (Hata kodu: %errorlevel%)
    echo.
    echo Alternatif çözüm deneniyor...
    
    REM Alternatif: Doğrudan mevcut klasörden çalış
    echo 🔄 Mevcut klasörden build deneniyor...
    cd /d "%~dp0quickpdf_app"
    goto :build_apk
)

echo ✅ Dosyalar kopyalandı

echo ✅ Dosyalar kopyalandı
echo.

REM Kısa yoldan build et
echo 🔨 APK build ediliyor...
cd /d "C:\quickpdf\app"

:build_apk
REM Cache temizle
echo Önbellek temizleniyor...
flutter clean >nul 2>&1

REM Dependencies al
echo Bağımlılıklar indiriliyor...
flutter pub get >nul 2>&1

REM APK build et (shader sorununu önlemek için ek parametreler)
echo Mobil APK build ediliyor...
flutter build apk --debug -t lib/main_mobile.dart --no-tree-shake-icons --dart-define=FLUTTER_WEB_USE_SKIA=false

if errorlevel 1 (
    echo ❌ APK build başarısız!
    echo.
    echo Alternatif çözümler:
    echo 1. GitHub Actions kullanın
    echo 2. Online build servisi kullanın
    echo 3. Web versiyonu test edin
    pause
    exit /b 1
)

echo.
echo ✅ APK başarıyla oluşturuldu!
echo 📍 Konum: C:\quickpdf\app\build\app\outputs\flutter-apk\app-debug.apk
echo.

REM Cihaz kontrolü
flutter devices | findstr "android" >nul
if not errorlevel 1 (
    echo 📱 Android cihaz bulundu!
    echo Cihaza kurmak ister misiniz? (y/n)
    set /p INSTALL_CHOICE=
    if /i "%INSTALL_CHOICE%"=="y" (
        echo 📲 Cihaza kuruluyor...
        flutter install -t lib/main_mobile.dart
        if not errorlevel 1 (
            echo ✅ Uygulama başarıyla kuruldu!
            echo.
            echo 🎉 QuickPDF uygulaması cihazınızda hazır!
            echo Test hesapları:
            echo - test@test.com / 123456
            echo - admin@quickpdf.com / admin123
        ) else (
            echo ❌ Kurulum başarısız!
            echo Manuel kurulum için APK dosyasını cihaza kopyalayın
        )
    )
) else (
    echo ⚠️ Android cihaz bulunamadı
    echo APK dosyasını manuel olarak cihaza kopyalayıp kurun
)

echo.
echo 🧹 Temizlik yapılıyor...
cd /d "%~dp0"
rmdir /s /q "C:\quickpdf" >nul 2>&1

echo.
echo ✅ İşlem tamamlandı!
pause