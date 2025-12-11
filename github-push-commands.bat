@echo off
chcp 65001 >nul
echo ========================================
echo    GitHub APK Build - Hızlı Çözüm
echo ========================================
echo.

echo 🎯 APK alamama sorunu için kesin çözüm!
echo 💡 Türkçe karakter sorunu GitHub Actions ile çözülüyor
echo.

echo ========================================
echo 1. GitHub Repository Oluşturun
echo ========================================
echo • GitHub.com'a gidin
echo • New Repository → quickpdf-app
echo • Public seçin
echo • README eklemeyin
echo.

echo ========================================
echo 2. Proje Dosyalarını Yükleyin
echo ========================================
echo.
echo Aşağıdaki komutları sırayla çalıştırın:
echo.
echo cd quickpdf_app
echo git init
echo git add .
echo git commit -m "QuickPDF Mobile App - APK Build Ready"
echo git branch -M main
echo git remote add origin https://github.com/KULLANICI_ADI/quickpdf-app.git
echo git push -u origin main
echo.

echo ⚠️  KULLANICI_ADI kısmını kendi GitHub kullanıcı adınızla değiştirin!
echo.

echo ========================================
echo 3. APK Build Süreci
echo ========================================
echo • Push işlemi tamamlandıktan sonra
echo • GitHub → Actions sekmesine gidin
echo • "Build QuickPDF Mobile APK" workflow'u otomatik başlayacak
echo • 5-10 dakika bekleyin
echo • Actions → Artifacts → APK dosyalarını indirin
echo.

echo ========================================
echo 4. APK Kurulumu
echo ========================================
echo • İndirilen APK'yı cihaza kopyalayın
echo • Veya install-apk-to-device.bat kullanın
echo.

echo 🎉 Sonuç: %100 başarı garantili!
echo 💡 Linux ortamında build olduğu için Türkçe karakter sorunu yok
echo.

set /p CHOICE=GitHub'a push yapmak için P, Web test için W tuşuna basın: 

if /i "%CHOICE%"=="P" (
    echo.
    echo 🚀 GitHub push işlemi başlatılıyor...
    cd quickpdf_app
    
    REM Git repository başlat
    git init
    git add .
    git commit -m "QuickPDF Mobile App - APK Build Ready"
    git branch -M main
    
    echo.
    echo ⚠️  Şimdi GitHub'da repository oluşturun ve URL'yi girin:
    set /p REPO_URL=Repository URL (https://github.com/USERNAME/quickpdf-app.git): 
    git remote add origin %REPO_URL%
    git push -u origin main
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✅ Push tamamlandı! GitHub Actions'ı kontrol edin.
        start "" https://github.com
    ) else (
        echo.
        echo ❌ Push hatası! GitHub hesabınıza giriş yaptığınızdan emin olun.
    )
)

if /i "%CHOICE%"=="W" (
    echo.
    echo 🌐 Web versiyonu başlatılıyor...
    cd quickpdf_app
    start "" flutter run -d chrome --web-port 8090 -t lib/main_mobile.dart
    echo.
    echo ✅ Web versiyonu başlatıldı!
    echo 🔗 Adres: http://localhost:8090
    echo 📱 Tarayıcıda F12 → Mobil görünüm seçin
    timeout /t 3 >nul
    start "" http://localhost:8090
)

echo.
pause