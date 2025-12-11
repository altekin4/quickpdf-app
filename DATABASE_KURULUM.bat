@echo off
chcp 65001 >nul
color 0E
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██           🏥 QuickPDF Database Kurulumu                ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.

echo 📋 Database Kurulum Adımları:
echo.
echo 1️⃣ PostgreSQL Kurulumu Kontrol Ediliyor...
echo.

REM PostgreSQL kurulu mu kontrol et
where psql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ PostgreSQL bulunamadı!
    echo.
    echo 📥 PostgreSQL kuruluyor...
    winget install PostgreSQL.PostgreSQL.17
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ PostgreSQL kurulumu başarısız!
        echo 💡 Manuel kurulum: https://www.postgresql.org/download/windows/
        pause
        exit /b 1
    )
    echo ✅ PostgreSQL kuruldu!
    echo ⚠️  Sistem yeniden başlatılması gerekebilir.
    echo.
) else (
    echo ✅ PostgreSQL zaten kurulu!
)

echo.
echo 2️⃣ Database Oluşturuluyor...
echo.

REM Database oluştur
echo CREATE DATABASE quickpdf_db; | psql -U postgres -h localhost
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database 'quickpdf_db' oluşturuldu!
) else (
    echo ⚠️  Database zaten mevcut veya oluşturma hatası
)

echo.
echo 3️⃣ Backend Dependencies Kuruluyor...
echo.

cd quickpdf_backend
if not exist "node_modules" (
    echo 📦 npm install çalıştırılıyor...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ npm install başarısız!
        pause
        exit /b 1
    )
    echo ✅ Dependencies kuruldu!
) else (
    echo ✅ Dependencies zaten kurulu!
)

echo.
echo 4️⃣ Database Schema Oluşturuluyor...
echo.

REM Migration çalıştır
echo 🔄 Migration çalıştırılıyor...
call npm run migrate:up
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database schema oluşturuldu!
) else (
    echo ❌ Migration başarısız!
    echo 💡 Manuel migration: npm run migrate:up
)

echo.
echo 5️⃣ Backend Server Test Ediliyor...
echo.

REM Backend'i test modunda başlat
echo 🚀 Backend server başlatılıyor...
start "" cmd /c "npm run dev"

REM 5 saniye bekle
timeout /t 5 >nul

REM Health check
echo 🏥 Health check yapılıyor...
curl -s http://localhost:3000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Backend server çalışıyor!
    echo 🔗 Health Check: http://localhost:3000/health
    echo 📚 API Docs: http://localhost:3000/api/v1
) else (
    echo ⚠️  Backend server henüz hazır değil (5 saniye daha bekleyin)
)

echo.
echo ========================================
echo           Kurulum Tamamlandı!
echo ========================================
echo.
echo 🎯 Backend Bilgileri:
echo • URL: http://localhost:3000
echo • Database: quickpdf_db
echo • User: postgres
echo • Password: postgres
echo.
echo 📋 Test Komutları:
echo • Health Check: curl http://localhost:3000/health
echo • API Test: curl http://localhost:3000/api/v1
echo.
echo 🚀 Frontend Bağlantısı:
echo • Frontend'de API_BASE_URL: http://localhost:3000/api/v1
echo • CORS ayarları: ✅ Yapılandırıldı
echo.
echo 💡 Sorun Giderme:
echo • Backend log: quickpdf_backend/logs/app.log
echo • Database bağlantı: psql -U postgres -d quickpdf_db
echo • Migration tekrar: npm run migrate:up
echo.

REM Browser'da health check aç
start "" http://localhost:3000/health

echo ✅ Database kurulumu başarıyla tamamlandı!
echo.
pause