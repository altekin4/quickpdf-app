@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:MENU
cls
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    QuickPDF Build Menüsü                    ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║                                                              ║
echo ║  1. 🔨 Debug APK Build                                       ║
echo ║  2. 🚀 Release APK Build                                     ║
echo ║  3. 📱 Debug APK Build + Cihaza Kur                         ║
echo ║  4. 🌐 Web Versiyonu Çalıştır                               ║
echo ║  5. 🧹 Cache Temizle + Debug Build                          ║
echo ║  6. 📋 Flutter Doctor                                        ║
echo ║  7. 📱 Bağlı Cihazları Göster                               ║
echo ║  8. 📂 APK Klasörünü Aç                                     ║
echo ║  9. 🔄 GitHub Actions Status                                 ║
echo ║  0. ❌ Çıkış                                                 ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
set /p choice="Seçiminizi yapın (0-9): "

if "%choice%"=="1" goto DEBUG_BUILD
if "%choice%"=="2" goto RELEASE_BUILD
if "%choice%"=="3" goto DEBUG_INSTALL
if "%choice%"=="4" goto WEB_RUN
if "%choice%"=="5" goto CLEAN_BUILD
if "%choice%"=="6" goto FLUTTER_DOCTOR
if "%choice%"=="7" goto SHOW_DEVICES
if "%choice%"=="8" goto OPEN_APK_FOLDER
if "%choice%"=="9" goto GITHUB_STATUS
if "%choice%"=="0" goto EXIT

echo Geçersiz seçim! Tekrar deneyin...
timeout /t 2 >nul
goto MENU

:DEBUG_BUILD
echo.
echo 🔨 Debug APK build ediliyor...
call build-apk.bat debug
pause
goto MENU

:RELEASE_BUILD
echo.
echo 🚀 Release APK build ediliyor...
call build-apk.bat release
pause
goto MENU

:DEBUG_INSTALL
echo.
echo 📱 Debug APK build + install...
cd quickpdf_app
flutter clean >nul 2>&1
flutter pub get >nul 2>&1
flutter run --device-id RFCW41B4FSR
pause
goto MENU

:WEB_RUN
echo.
echo 🌐 Web versiyonu başlatılıyor...
cd quickpdf_app
start http://localhost:8080
flutter run -d chrome --web-port 8080
pause
goto MENU

:CLEAN_BUILD
echo.
echo 🧹 Cache temizleniyor ve debug build...
cd quickpdf_app
flutter clean
flutter pub get
flutter build apk --debug
pause
goto MENU

:FLUTTER_DOCTOR
echo.
echo 📋 Flutter Doctor çalıştırılıyor...
flutter doctor -v
pause
goto MENU

:SHOW_DEVICES
echo.
echo 📱 Bağlı cihazlar:
flutter devices
pause
goto MENU

:OPEN_APK_FOLDER
echo.
echo 📂 APK klasörü açılıyor...
if exist "quickpdf_app\build\app\outputs\flutter-apk" (
    explorer "quickpdf_app\build\app\outputs\flutter-apk"
) else (
    echo APK klasörü bulunamadı! Önce build yapın.
)
pause
goto MENU

:GITHUB_STATUS
echo.
echo 🔄 GitHub Actions için:
echo 1. Projeyi GitHub'a push edin
echo 2. Actions sekmesine gidin
echo 3. "Build QuickPDF APK" workflow'unu çalıştırın
echo 4. Artifacts'tan APK'ları indirin
echo.
echo GitHub Repository URL'nizi buraya ekleyin:
echo https://github.com/KULLANICI_ADI/quickpdf_app
pause
goto MENU

:EXIT
echo.
echo 👋 Görüşürüz!
timeout /t 2 >nul
exit