@echo off
echo ========================================
echo GitHub Actions Workflow Rehberi
echo ========================================
echo.

echo ✅ Workflow GitHub'a yüklendi!
echo.
echo Şimdi şu adımları takip edin:
echo.
echo 1. GitHub repository'nize gidin:
echo    https://github.com/altekin4/quickpdf-app
echo.
echo 2. "Actions" sekmesine tıklayın
echo.
echo 3. "Build QuickPDF Mobile APK" workflow'unu bulun
echo.
echo 4. "Run workflow" butonuna tıklayın
echo.
echo 5. Build type: "debug" seçin
echo.
echo 6. Yeşil "Run workflow" butonuna tıklayın
echo.
echo 7. Build tamamlanana kadar bekleyin (5-10 dakika)
echo.
echo 8. "Artifacts" bölümünden APK'yı indirin
echo.
echo 9. APK'yı cihazınıza kurmak için:
echo    install-apk-to-device.bat
echo.

echo GitHub repository'yi açmak için Enter'a basın...
pause >nul
start https://github.com/altekin4/quickpdf-app/actions

echo.
echo APK hazır olduğunda bu klasöre koyun ve kurulum script'ini çalıştırın!
echo.

pause