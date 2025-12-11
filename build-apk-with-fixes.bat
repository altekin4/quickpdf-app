@echo off
echo ========================================
echo QuickPDF APK Build - Tüm Fixler
echo ========================================
echo.

cd /d quickpdf_clean

REM Environment variables set et
set FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false
set FLUTTER_WEB_USE_SKIA=true
set FLUTTER_DISABLE_SHADER_COMPILATION=true
set FLUTTER_FORCE_SKIA_RENDERER=true

echo Environment variables set edildi:
echo FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false
echo FLUTTER_WEB_USE_SKIA=true
echo FLUTTER_DISABLE_SHADER_COMPILATION=true
echo FLUTTER_FORCE_SKIA_RENDERER=true
echo.

echo Flutter cache temizleniyor...
flutter clean

echo Dependencies alınıyor...
flutter pub get

echo.
echo APK build başlatılıyor...
echo Target: lib/main_mobile.dart
echo.

REM Verbose build ile detaylı log
flutter build apk --debug --target=lib/main_mobile.dart --verbose

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ BAŞARILI! APK oluşturuldu!
    echo ========================================
    echo.
    
    echo APK konumu:
    echo %CD%\build\app\outputs\flutter-apk\
    echo.
    
    REM APK'ları ana klasöre kopyala
    cd ..
    if not exist "output" mkdir "output"
    copy "quickpdf_clean\build\app\outputs\flutter-apk\*.apk" "output\"
    
    echo APK dosyaları output klasörüne kopyalandı!
    echo.
    echo Android cihaza kurmak için:
    echo install-apk-to-device.bat
    echo.
    
    explorer "output"
    
) else (
    echo.
    echo ========================================
    echo ❌ HATA! APK build başarısız!
    echo ========================================
    echo.
    echo Hata kodu: %ERRORLEVEL%
    echo.
    echo Alternatif çözümler:
    echo 1. GitHub Actions kullanın
    echo 2. Online build service
    echo 3. Docker build
    echo.
)

pause