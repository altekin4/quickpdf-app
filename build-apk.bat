@echo off
setlocal enabledelayedexpansion

echo ========================================
echo       QuickPDF APK Builder v1.0
echo ========================================
echo.

REM Renk kodları
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Parametreleri kontrol et
set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=debug

echo %BLUE%Build Type: %BUILD_TYPE%%NC%
echo.

REM Proje klasörüne git
cd /d "%~dp0quickpdf_app"
if errorlevel 1 (
    echo %RED%Hata: quickpdf_app klasörü bulunamadı!%NC%
    pause
    exit /b 1
)

echo %YELLOW%1. Flutter kurulumu kontrol ediliyor...%NC%
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %RED%Hata: Flutter kurulu değil!%NC%
    pause
    exit /b 1
)
echo %GREEN%✓ Flutter kurulu%NC%

echo.
echo %YELLOW%2. Android cihaz kontrol ediliyor...%NC%
flutter devices | findstr "android" >nul
if errorlevel 1 (
    echo %YELLOW%⚠ Android cihaz bulunamadı (sadece APK oluşturulacak)%NC%
) else (
    echo %GREEN%✓ Android cihaz bulundu%NC%
)

echo.
echo %YELLOW%3. Cache temizleniyor...%NC%
flutter clean >nul 2>&1
echo %GREEN%✓ Cache temizlendi%NC%

echo.
echo %YELLOW%4. Dependencies alınıyor...%NC%
flutter pub get
if errorlevel 1 (
    echo %RED%Hata: Dependencies alınamadı!%NC%
    pause
    exit /b 1
)
echo %GREEN%✓ Dependencies alındı%NC%

echo.
echo %YELLOW%5. APK build ediliyor (%BUILD_TYPE%)...%NC%
if "%BUILD_TYPE%"=="release" (
    flutter build apk --release --split-per-abi
) else (
    flutter build apk --debug --split-per-abi
)

if errorlevel 1 (
    echo %RED%Hata: APK build edilemedi!%NC%
    echo.
    echo %YELLOW%Alternatif çözümler:%NC%
    echo 1. GitHub Actions kullanın
    echo 2. Web versiyonu test edin: flutter run -d chrome
    echo 3. Proje yolunu kısaltın
    pause
    exit /b 1
)

echo.
echo %GREEN%========================================%NC%
echo %GREEN%       APK BUILD BAŞARILI!%NC%
echo %GREEN%========================================%NC%
echo.

REM APK dosyalarını listele
echo %BLUE%Oluşturulan APK dosyaları:%NC%
if "%BUILD_TYPE%"=="release" (
    dir "build\app\outputs\flutter-apk\*release.apk" /b 2>nul
) else (
    dir "build\app\outputs\flutter-apk\*debug.apk" /b 2>nul
)

echo.
echo %BLUE%APK Konumu:%NC%
echo %cd%\build\app\outputs\flutter-apk\
echo.

REM Cihaza kurulum seçeneği
flutter devices | findstr "android" >nul
if not errorlevel 1 (
    echo %YELLOW%Cihaza kurmak ister misiniz? (y/n)%NC%
    set /p INSTALL_CHOICE=
    if /i "!INSTALL_CHOICE!"=="y" (
        echo %YELLOW%Cihaza kuruluyor...%NC%
        flutter install
        if not errorlevel 1 (
            echo %GREEN%✓ Uygulama cihaza kuruldu!%NC%
        )
    )
)

echo.
echo %GREEN%İşlem tamamlandı!%NC%
pause