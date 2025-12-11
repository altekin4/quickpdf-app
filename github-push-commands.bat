@echo off
echo ========================================
echo GitHub Push Commands
echo ========================================
echo.

echo GitHub repository URL'nizi girin (örnek: https://github.com/username/quickpdf-app.git):
set /p REPO_URL="Repository URL: "

echo.
echo Remote repository bağlanıyor...
git remote add origin %REPO_URL%

echo.
echo Main branch oluşturuluyor...
git branch -M main

echo.
echo Kod GitHub'a push ediliyor...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ BAŞARILI! Kod GitHub'a yüklendi!
    echo ========================================
    echo.
    echo Şimdi GitHub'da Actions sekmesine gidin:
    echo %REPO_URL%/actions
    echo.
    echo "Build QuickPDF Mobile APK" workflow'unu çalıştırın!
    echo.
) else (
    echo.
    echo ========================================
    echo ❌ HATA! Push başarısız!
    echo ========================================
    echo.
    echo Olası çözümler:
    echo 1. GitHub hesabınıza giriş yaptığınızdan emin olun
    echo 2. Repository URL'sini doğru girdiğinizden emin olun
    echo 3. Repository'nin public olduğundan emin olun
    echo.
)

pause