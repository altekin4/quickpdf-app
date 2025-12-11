@echo off
echo ========================================
echo GitHub Actions - Final Test
echo ========================================
echo.

echo ✅ Dependency sorunları çözüldü!
echo.
echo Şimdi şu workflow'ları dene:
echo.
echo 1. "Build APK Minimal" (ÖNERİLEN)
echo    ✅ Minimal dependencies
echo    ✅ Kendi pubspec.yaml oluşturur
echo    ✅ Conflict'leri önler
echo.
echo 2. "Build QuickPDF App"
echo    ✅ quickpdf_app klasörü
echo    ✅ Mevcut pubspec.yaml
echo    ✅ Daha hızlı
echo.

echo GitHub Actions sayfasını açmak için Enter'a basın...
pause >nul
start https://github.com/altekin4/quickpdf-app/actions

echo.
echo "Build APK Minimal" workflow'unu dene!
echo Bu sefer çalışması gerekir.
echo.

pause