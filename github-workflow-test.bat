@echo off
echo ========================================
echo GitHub Workflow Test Rehberi
echo ========================================
echo.

echo ✅ 4 farklı workflow yüklendi!
echo.
echo Şimdi GitHub'da şu workflow'ları dene:
echo.
echo 1. "Build APK Fixed" (ÖNERİLEN)
echo    - En basit ve güvenilir
echo    - quickpdf_clean klasörü
echo.
echo 2. "Build Clean APK"
echo    - Debug/Release seçeneği
echo    - Daha detaylı
echo.
echo 3. "Build APK Simple"
echo    - Otomatik çalışır
echo    - quickpdf_app klasörü
echo.
echo 4. "Build QuickPDF Mobile APK"
echo    - Orijinal workflow
echo    - Split APK'lar
echo.

echo GitHub Actions sayfasını açmak için Enter'a basın...
pause >nul
start https://github.com/altekin4/quickpdf-app/actions

echo.
echo Hangi workflow'u denediğini ve ne hatası aldığını söyle!
echo.

pause