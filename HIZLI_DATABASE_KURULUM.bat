@echo off
chcp 65001 >nul
color 0C
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██        🚨 PostgreSQL Kurulum Gerekli                   ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.

echo 📋 Backend database kurulumu için PostgreSQL gerekli!
echo.
echo ========================================
echo           Kurulum Seçenekleri
echo ========================================
echo.
echo 1. 🚀 Otomatik Kurulum (Winget)
echo    • PostgreSQL 17 otomatik kurulur
echo    • 5-10 dakika sürer
echo    • Yönetici yetkisi gerekir
echo.
echo 2. 📥 Manuel İndirme
echo    • PostgreSQL.org'dan indir
echo    • Kurulum sihirbazını takip et
echo    • Daha kontrollü kurulum
echo.
echo 3. 🐳 Docker ile Kurulum
echo    • Docker container olarak çalıştır
echo    • Hafif ve izole
echo    • Docker gerekli
echo.
echo 4. 📖 Detaylı Rehber Görüntüle
echo    • Adım adım kurulum rehberi
echo    • Sorun giderme ipuçları
echo    • Konfigürasyon örnekleri
echo.
echo 5. ❌ Çıkış
echo.

set /p CHOICE=Seçiminizi yapın (1-5): 

if "%CHOICE%"=="1" (
    cls
    echo.
    echo 🚀 PostgreSQL Otomatik Kurulum
    echo.
    echo ⚠️  Bu işlem yönetici yetkisi gerektirir!
    echo.
    set /p CONFIRM=Devam etmek istiyor musunuz? (Y/N): 
    if /i "%CONFIRM%"=="Y" (
        echo.
        echo 📥 PostgreSQL 17 kuruluyor...
        winget install PostgreSQL.PostgreSQL.17
        if %ERRORLEVEL% EQU 0 (
            echo ✅ PostgreSQL kuruldu!
            echo.
            echo 🔄 Database oluşturuluyor...
            timeout /t 5 >nul
            echo CREATE DATABASE quickpdf_db; | psql -U postgres -h localhost
            echo.
            echo ✅ Kurulum tamamlandı!
            echo 🔗 Test: DATABASE_KURULUM.bat
        ) else (
            echo ❌ Kurulum başarısız! Manuel kurulum deneyin.
        )
    )
    goto :end
)

if "%CHOICE%"=="2" (
    cls
    echo.
    echo 📥 Manuel Kurulum Rehberi
    echo.
    echo 1️⃣ PostgreSQL İndir:
    echo    https://www.postgresql.org/download/windows/
    echo.
    echo 2️⃣ Kurulum Ayarları:
    echo    • Port: 5432
    echo    • Password: postgres
    echo    • Locale: Turkish, Turkey
    echo.
    echo 3️⃣ Kurulum Sonrası:
    echo    • pgAdmin açılacak
    echo    • Database oluştur: quickpdf_db
    echo    • Test: psql --version
    echo.
    start "" https://www.postgresql.org/download/windows/
    goto :end
)

if "%CHOICE%"=="3" (
    cls
    echo.
    echo 🐳 Docker ile PostgreSQL
    echo.
    echo 📋 Gereksinimler:
    echo • Docker Desktop kurulu olmalı
    echo • WSL2 aktif olmalı
    echo.
    echo 🚀 Kurulum Komutları:
    echo.
    echo docker pull postgres:17
    echo docker run --name quickpdf-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=quickpdf_db -p 5432:5432 -d postgres:17
    echo.
    echo 📋 Test:
    echo docker exec -it quickpdf-postgres psql -U postgres -d quickpdf_db
    echo.
    set /p RUN_DOCKER=Docker komutlarını çalıştırmak istiyor musunuz? (Y/N): 
    if /i "%RUN_DOCKER%"=="Y" (
        echo.
        echo 🐳 Docker container başlatılıyor...
        docker pull postgres:17
        docker run --name quickpdf-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=quickpdf_db -p 5432:5432 -d postgres:17
        if %ERRORLEVEL% EQU 0 (
            echo ✅ PostgreSQL Docker container başlatıldı!
            echo 🔗 Test: docker exec -it quickpdf-postgres psql -U postgres -d quickpdf_db
        ) else (
            echo ❌ Docker kurulumu başarısız! Docker Desktop'ın çalıştığından emin olun.
        )
    )
    goto :end
)

if "%CHOICE%"=="4" (
    cls
    echo.
    echo 📖 Detaylı Rehber Açılıyor...
    start "" notepad "POSTGRESQL_KURULUM_REHBERI.md"
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
echo           Sonraki Adımlar
echo ========================================
echo.
echo 1️⃣ PostgreSQL kurulumunu tamamlayın
echo 2️⃣ DATABASE_KURULUM.bat çalıştırın
echo 3️⃣ Backend server'ı test edin
echo 4️⃣ HIZLI_BASLATMA_REHBERI.bat ile full stack test yapın
echo.
echo 💡 Sorun yaşarsanız:
echo • POSTGRESQL_KURULUM_REHBERI.md dosyasını inceleyin
echo • quickpdf_backend/test-db.js ile bağlantıyı test edin
echo.
pause