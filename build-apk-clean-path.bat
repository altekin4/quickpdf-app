@echo off
echo ========================================
echo QuickPDF APK Build - Temiz Path
echo ========================================
echo.

echo Temiz path'e kopyalaniyor...
if not exist "C:\temp\quickpdf" mkdir "C:\temp\quickpdf"
xcopy "quickpdf_clean\*" "C:\temp\quickpdf\" /E /I /Y /Q

echo.
echo Flutter dependencies aliniyor...
cd /d "C:\temp\quickpdf"
call flutter pub get

echo.
echo APK build ediliyor...
call flutter build apk --debug --target=lib/main_mobile.dart

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ BAŞARILI! APK oluşturuldu!
    echo ========================================
    echo.
    echo APK Konumu:
    echo C:\temp\quickpdf\build\app\outputs\flutter-apk\
    echo.
    
    REM APK'yı ana klasöre kopyala
    if not exist "output" mkdir "output"
    copy "C:\temp\quickpdf\build\app\outputs\flutter-apk\*.apk" "output\"
    
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
    echo Türkçe karakter sorunu devam ediyor.
    echo.
    echo Alternatif çözümler:
    echo 1. GitHub Actions kullanın (Önerilen)
    echo 2. Web versiyonunu test edin: http://localhost:8091
    echo 3. Online build service kullanın
    echo.
)

pause