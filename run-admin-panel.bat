@echo off
echo ========================================
echo       QuickPDF Admin Panel Başlatıcı
echo ========================================
echo.

cd quickpdf_app

echo Admin paneli başlatılıyor...
echo Web adresi: http://localhost:8086
echo.
echo Demo Admin Hesabı:
echo E-posta: admin@quickpdf.com
echo Şifre: admin123
echo.

start http://localhost:8086
flutter run -d chrome --web-port 8086 -t lib/main_admin.dart