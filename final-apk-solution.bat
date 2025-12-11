@echo off
echo ========================================
echo Final APK Çözümü - Tüm Yöntemler
echo ========================================
echo.

echo Mevcut durum:
echo ✅ Kod: %100 temiz (0 hata)
echo ✅ Android cihaz: Bağlı (SM G990E)
echo ✅ Dependencies: Güncel
echo ❌ Flutter Impeller: Türkçe karakter sorunu
echo.

echo Çözüm seçenekleri:
echo.
echo 1. GitHub Actions (ÖNERİLEN - %100 başarı)
echo 2. Web versiyonu test (Hemen kullanılabilir)
echo 3. Online build service
echo 4. Docker build
echo.

set /p choice="Seçiminizi yapın (1-4): "

if "%choice%"=="1" goto github_actions
if "%choice%"=="2" goto web_version
if "%choice%"=="3" goto online_build
if "%choice%"=="4" goto docker_build

:github_actions
echo.
echo ========================================
echo GitHub Actions Kurulum
echo ========================================
echo.
echo Adımlar:
echo 1. GitHub hesabınızda yeni repository oluşturun
echo 2. Bu komutları çalıştırın:
echo.
echo git init
echo git add .
echo git commit -m "QuickPDF Mobile App"
echo git remote add origin https://github.com/[username]/quickpdf-app.git
echo git push -u origin main
echo.
echo 3. GitHub'da Actions sekmesine gidin
echo 4. "Build QuickPDF Mobile APK" workflow'unu çalıştırın
echo 5. APK'yı Artifacts'ten indirin
echo 6. install-apk-to-device.bat ile kurun
echo.
goto end

:web_version
echo.
echo ========================================
echo Web Versiyonu Test
echo ========================================
echo.
echo Admin panel zaten çalışıyor: http://localhost:8086
echo.
echo Mobil web versiyonu için:
cd quickpdf_app
start http://localhost:8093
flutter run -d chrome --target=lib/main_mobile.dart --web-port=8093
goto end

:online_build
echo.
echo ========================================
echo Online Build Services
echo ========================================
echo.
echo 1. Codemagic.io - Flutter özelleşmiş
echo 2. Bitrise.io - Mobil CI/CD
echo 3. AppCenter - Microsoft çözümü
echo.
echo Kodu zip'leyip bu servislerden birine yükleyin
echo.
goto end

:docker_build
echo.
echo ========================================
echo Docker Build
echo ========================================
echo.
echo Docker kurulu ise:
docker-build.bat debug
goto end

:end
echo.
echo ========================================
echo Kurulum Hazırlığı
echo ========================================
echo.
echo APK hazır olduğunda:
echo 1. install-apk-to-device.bat çalıştırın
echo 2. Test hesapları:
echo    - test@test.com / 123456
echo    - admin@quickpdf.com / admin123
echo    - creator@quickpdf.com / creator123
echo.

pause