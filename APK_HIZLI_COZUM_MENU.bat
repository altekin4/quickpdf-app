@echo off
chcp 65001 >nul
color 0A
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██           🚀 QuickPDF APK Hızlı Çözüm Menüsü          ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.
echo 🎯 Sorun: Türkçe karakter nedeniyle APK build başarısız
echo 💡 Çözüm: GitHub Actions ile Linux ortamında build
echo.
echo ========================================
echo           Çözüm Seçenekleri
echo ========================================
echo.
echo 1. 🚀 GitHub Actions (ÖNERİLEN - %100 Başarı)
echo    • 5-10 dakikada hazır APK
echo    • Linux ortamında build
echo    • Otomatik multi-arch support
echo.
echo 2. 🌐 Web Versiyonu Test (Hemen Çalışır)
echo    • Anında test edilebilir
echo    • Mobil görünümde çalışır
echo    • Tüm özellikler mevcut
echo.
echo 3. 📱 Online Build Service (Codemagic)
echo    • Profesyonel CI/CD
echo    • GitHub entegrasyonu
echo    • Ücretsiz plan mevcut
echo.
echo 4. 📋 Detaylı Analiz Raporu Görüntüle
echo    • Teknik detaylar
echo    • Denenen çözümler
echo    • Sistem analizi
echo.
echo 5. ❌ Çıkış
echo.

set /p CHOICE=Seçiminizi yapın (1-5): 

if "%CHOICE%"=="1" (
    cls
    echo.
    echo 🚀 GitHub Actions Çözümü Başlatılıyor...
    echo.
    echo ========================================
    echo           Adım Adım Rehber
    echo ========================================
    echo.
    echo 1️⃣ GitHub'da repository oluşturun:
    echo    • GitHub.com → New Repository
    echo    • İsim: quickpdf-app
    echo    • Public seçin
    echo    • README eklemeyin
    echo.
    echo 2️⃣ Proje dosyalarını yükleyin:
    echo.
    cd quickpdf_app
    echo    git init
    git init
    echo    git add .
    git add .
    echo    git commit -m "QuickPDF APK Build Ready"
    git commit -m "QuickPDF APK Build Ready"
    echo    git branch -M main
    git branch -M main
    echo.
    echo 3️⃣ Repository URL'nizi girin:
    set /p REPO_URL=GitHub Repository URL: 
    echo    git remote add origin %REPO_URL%
    git remote add origin %REPO_URL%
    echo    git push -u origin main
    git push -u origin main
    echo.
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Başarılı! GitHub Actions otomatik başlayacak.
        echo 🔗 Actions: %REPO_URL%/actions
        start "" %REPO_URL%/actions
    ) else (
        echo ❌ Hata! GitHub hesabınıza giriş yaptığınızdan emin olun.
    )
    goto :end
)

if "%CHOICE%"=="2" (
    cls
    echo.
    echo 🌐 Web Versiyonu Başlatılıyor...
    echo.
    cd quickpdf_app
    echo ✅ Flutter web server başlatılıyor...
    start "" flutter run -d chrome --web-port 8090 -t lib/main_mobile.dart
    echo.
    echo 🔗 Adres: http://localhost:8090
    echo 📱 Tarayıcıda F12 → Device Toolbar → Mobil görünüm
    echo.
    echo 📋 Test Hesapları:
    echo • test@test.com / 123456
    echo • admin@quickpdf.com / admin123
    echo • creator@quickpdf.com / creator123
    echo.
    timeout /t 5 >nul
    start "" http://localhost:8090
    goto :end
)

if "%CHOICE%"=="3" (
    cls
    echo.
    echo 📱 Online Build Service - Codemagic
    echo.
    echo ========================================
    echo           Codemagic Kurulumu
    echo ========================================
    echo.
    echo 1️⃣ Codemagic hesabı oluşturun
    echo 2️⃣ GitHub hesabınızı bağlayın
    echo 3️⃣ quickpdf-app repository'sini seçin
    echo 4️⃣ Flutter workflow'unu seçin
    echo 5️⃣ Build'i başlatın
    echo.
    echo 🎯 Avantajlar:
    echo • Profesyonel CI/CD
    echo • Otomatik build
    echo • Play Store deployment
    echo • Ücretsiz 500 build/ay
    echo.
    start "" https://codemagic.io/
    goto :end
)

if "%CHOICE%"=="4" (
    cls
    echo.
    echo 📋 Detaylı Analiz Raporu Açılıyor...
    start "" notepad "DERINLEMESINE_APK_HATA_ANALIZI_VE_COZUM.md"
    goto :end
)

if "%CHOICE%"=="5" (
    exit
)

echo ❌ Geçersiz seçim! Lütfen 1-5 arası bir sayı girin.
pause
goto :start

:end
echo.
echo ========================================
echo           İşlem Tamamlandı
echo ========================================
echo.
echo 💡 Sorunuz mu var?
echo • GitHub Actions: 5-10 dakika bekleyin
echo • Web versiyonu: Hemen test edilebilir
echo • Codemagic: Hesap oluşturun ve bağlayın
echo.
echo 🎯 Sonuç: APK'nız hazır olduğunda bildirim alacaksınız!
echo.
pause