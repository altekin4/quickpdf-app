@echo off
echo ========================================
echo QuickPDF APK Android Cihaza Kurulum
echo ========================================
echo.

REM Android cihaz kontrolü
echo Android cihaz kontrol ediliyor...
adb devices
echo.

REM APK dosyası kontrolü
set APK_FILE=""
if exist "quickpdf_app\build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" (
    set APK_FILE=quickpdf_app\build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk
    echo APK bulundu: ARM64 Debug
) else if exist "quickpdf_app\build\app\outputs\flutter-apk\app-debug.apk" (
    set APK_FILE=quickpdf_app\build\app\outputs\flutter-apk\app-debug.apk
    echo APK bulundu: Universal Debug
) else if exist "output\app-arm64-v8a-debug.apk" (
    set APK_FILE=output\app-arm64-v8a-debug.apk
    echo APK bulundu: Docker Output ARM64
) else if exist "output\app-debug.apk" (
    set APK_FILE=output\app-debug.apk
    echo APK bulundu: Docker Output Universal
) else (
    echo HATA: APK dosyası bulunamadı!
    echo.
    echo APK build almak için şu seçeneklerden birini kullanın:
    echo 1. GitHub Actions (Önerilen)
    echo 2. Docker Build: docker-build.bat
    echo 3. Online Build Service
    echo.
    pause
    exit /b 1
)

echo.
echo APK Kurulumu Başlatılıyor...
echo Dosya: %APK_FILE%
echo.

REM Eski sürümü kaldır (isteğe bağlı)
echo Eski uygulama sürümü kaldırılıyor...
adb uninstall com.quickpdf.app 2>nul

REM APK'yı kur
echo APK kuruluyor...
adb install -r "%APK_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ BAŞARILI! APK başarıyla kuruldu!
    echo ========================================
    echo.
    echo Uygulama cihazınızda "QuickPDF" adıyla görünecek.
    echo.
    echo Test hesapları:
    echo - test@test.com / 123456
    echo - admin@quickpdf.com / admin123
    echo - creator@quickpdf.com / creator123
    echo.
) else (
    echo.
    echo ========================================
    echo ❌ HATA! APK kurulumu başarısız!
    echo ========================================
    echo.
    echo Olası çözümler:
    echo 1. USB Debugging açık olduğundan emin olun
    echo 2. Cihazda "Bilinmeyen kaynaklardan kurulum" izni verin
    echo 3. Cihazı yeniden bağlayın
    echo 4. ADB driver'larını güncelleyin
    echo.
)

pause