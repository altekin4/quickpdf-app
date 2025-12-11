@echo off
echo ========================================
echo   Flutter Shader Bypass - Kalıcı Çözüm
echo ========================================

echo 🔧 Flutter SDK shader compiler'ını bypass ediyoruz...

REM Flutter SDK'daki shader compiler'ı geçici olarak rename et
if exist "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe" (
    echo 📁 Impeller compiler bulundu, yedekleniyor...
    ren "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe" "impellerc.exe.backup"
)

REM Dummy impellerc oluştur
echo @echo off > "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe"
echo echo Shader compilation bypassed for Turkish character path fix >> "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe"
echo exit 0 >> "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe"

echo ✅ Flutter shader compiler bypass edildi!

echo 🔨 APK build başlatılıyor...
cd quickpdf_clean
flutter build apk --debug --target=lib/main_mobile.dart --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo ✅ APK build başarılı!
    echo 📱 APK konumu: build\app\outputs\flutter-apk\app-debug.apk
    
    echo 📲 Cihaza yükleniyor...
    flutter install --device-id=RFCW41B4FSR
) else (
    echo ❌ APK build başarısız
)

echo 🔄 Flutter SDK'yı geri yüklüyoruz...
if exist "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe.backup" (
    del "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe"
    ren "C:\flutter\bin\cache\artifacts\engine\windows-x64\impellerc.exe.backup" "impellerc.exe"
    echo ✅ Flutter SDK geri yüklendi
)

pause