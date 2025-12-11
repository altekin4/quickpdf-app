@echo off
chcp 65001 >nul
color 0B
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██        🐳 Docker PostgreSQL Kurulumu                   ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.

echo 📋 Docker ile PostgreSQL kurulumu - En hızlı yöntem!
echo.

REM Docker kurulu mu kontrol et
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker bulunamadı!
    echo.
    echo 📥 Docker Desktop kuruluyor...
    winget install Docker.DockerDesktop
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Docker kurulumu başarısız!
        echo 💡 Manuel kurulum: https://www.docker.com/products/docker-desktop/
        pause
        exit /b 1
    )
    echo ✅ Docker Desktop kuruldu!
    echo ⚠️  Docker Desktop'ı başlatın ve WSL2'yi etkinleştirin.
    echo.
    pause
) else (
    echo ✅ Docker zaten kurulu!
)

echo.
echo 🔄 Docker daemon kontrol ediliyor...
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker daemon çalışmıyor!
    echo 💡 Docker Desktop'ı başlatın ve tekrar deneyin.
    echo.
    set /p WAIT=Docker Desktop başlatıldıktan sonra Enter'a basın...
)

echo.
echo 🐳 PostgreSQL container başlatılıyor...
echo.

REM Eski container'ı temizle
docker stop quickpdf-postgres >nul 2>&1
docker rm quickpdf-postgres >nul 2>&1

REM PostgreSQL container'ını başlat
docker run --name quickpdf-postgres ^
    -e POSTGRES_PASSWORD=postgres ^
    -e POSTGRES_DB=quickpdf_db ^
    -e POSTGRES_USER=postgres ^
    -p 5432:5432 ^
    -d postgres:17

if %ERRORLEVEL% EQU 0 (
    echo ✅ PostgreSQL container başlatıldı!
    echo.
    echo 📋 Container Bilgileri:
    echo • Container Name: quickpdf-postgres
    echo • Database: quickpdf_db
    echo • User: postgres
    echo • Password: postgres
    echo • Port: 5432
    echo.
    
    echo 🔄 Container'ın hazır olması bekleniyor...
    timeout /t 10 >nul
    
    echo 🧪 Database bağlantısı test ediliyor...
    docker exec quickpdf-postgres psql -U postgres -d quickpdf_db -c "SELECT version();" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Database bağlantısı başarılı!
    ) else (
        echo ⚠️  Database henüz hazır değil (birkaç saniye daha bekleyin)
    )
    
) else (
    echo ❌ Container başlatma başarısız!
    echo 💡 Docker Desktop'ın çalıştığından emin olun.
    pause
    exit /b 1
)

echo.
echo 🔧 Backend konfigürasyonu kontrol ediliyor...
if exist "quickpdf_backend\.env" (
    echo ✅ .env dosyası mevcut
) else (
    echo ⚠️  .env dosyası oluşturuluyor...
    echo NODE_ENV=development > quickpdf_backend\.env
    echo PORT=3000 >> quickpdf_backend\.env
    echo DATABASE_URL=postgresql://postgres:postgres@localhost:5432/quickpdf_db >> quickpdf_backend\.env
    echo JWT_SECRET=quickpdf-secret-key >> quickpdf_backend\.env
    echo CORS_ORIGIN=http://localhost:8080,http://localhost:3000 >> quickpdf_backend\.env
    echo ✅ .env dosyası oluşturuldu
)

echo.
echo 📦 Backend dependencies kontrol ediliyor...
cd quickpdf_backend
if not exist "node_modules" (
    echo 🔄 npm install çalıştırılıyor...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ npm install başarısız!
        cd ..
        pause
        exit /b 1
    )
    echo ✅ Dependencies kuruldu!
) else (
    echo ✅ Dependencies zaten kurulu!
)

echo.
echo 🗄️ Database schema oluşturuluyor...
timeout /t 5 >nul
docker exec quickpdf-postgres psql -U postgres -d quickpdf_db -f /dev/stdin < ../quickpdf_backend/src/migrations/001_initial_schema.sql >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database schema oluşturuldu!
) else (
    echo ⚠️  Schema oluşturma hatası (manuel migration gerekebilir)
)

echo.
echo 🚀 Backend server test ediliyor...
cd quickpdf_backend
node test-db.js
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database bağlantısı test başarılı!
) else (
    echo ⚠️  Database bağlantı testi başarısız
)

cd ..

echo.
echo ========================================
echo           Kurulum Tamamlandı!
echo ========================================
echo.
echo 🐳 Docker PostgreSQL:
echo • Container: quickpdf-postgres
echo • Status: docker ps
echo • Logs: docker logs quickpdf-postgres
echo • Connect: docker exec -it quickpdf-postgres psql -U postgres -d quickpdf_db
echo.
echo 🔧 Backend:
echo • Start: cd quickpdf_backend && npm run dev
echo • Test: node test-db.js
echo • Health: http://localhost:3000/health
echo.
echo 📋 Yönetim Komutları:
echo • Container durdur: docker stop quickpdf-postgres
echo • Container başlat: docker start quickpdf-postgres
echo • Container sil: docker rm quickpdf-postgres
echo.
echo 🎯 Sonraki Adım:
echo HIZLI_BASLATMA_REHBERI.bat ile full stack test yapın!
echo.
pause