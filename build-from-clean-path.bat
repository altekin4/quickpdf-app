@echo off
echo ========================================
echo QuickPDF APK Build - Clean Path
echo ========================================
echo.

cd /d "C:\temp\quickpdf"

echo Checking main_mobile.dart...
if exist "lib\main_mobile.dart" (
    echo ✅ main_mobile.dart found
) else (
    echo ❌ main_mobile.dart not found
    echo Listing lib contents:
    dir lib
    pause
    exit /b 1
)

echo.
echo Building APK...
flutter build apk --debug --target=lib/main_mobile.dart

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ BAŞARILI! APK oluşturuldu!
    echo ========================================
    echo.
    
    REM APK'yı ana klasöre kopyala
    cd /d "C:\Users\AnılTekin\Desktop\dilekcego"
    if not exist "output" mkdir "output"
    copy "C:\temp\quickpdf\build\app\outputs\flutter-apk\*.apk" "output\"
    
    echo APK dosyaları output klasörüne kopyalandı!
    echo.
    echo Android cihaza kurmak için:
    echo install-apk-to-device.bat
    echo.
    
) else (
    echo.
    echo ========================================
    echo ❌ HATA! APK build başarısız!
    echo ========================================
    echo.
)

pause