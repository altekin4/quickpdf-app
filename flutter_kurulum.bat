@echo off
echo Flutter Kurulum Scripti
echo.

REM Flutter klasörünü oluştur
if not exist "C:\flutter" (
    echo C:\flutter klasörü oluşturuluyor...
    mkdir "C:\flutter"
)

echo.
echo Flutter SDK indiriliyor...
echo Lütfen şu adımları takip edin:
echo.
echo 1. https://docs.flutter.dev/get-started/install/windows adresine gidin
echo 2. "Get the Flutter SDK" bölümünden ZIP dosyasını indirin
echo 3. ZIP dosyasını C:\flutter klasörüne çıkarın
echo 4. Bu scripti tekrar çalıştırın
echo.

REM Flutter PATH kontrolü
echo PATH kontrol ediliyor...
echo %PATH% | findstr /i "flutter" >nul
if %errorlevel% equ 0 (
    echo Flutter PATH'te bulundu!
    flutter doctor
) else (
    echo Flutter PATH'te bulunamadı.
    echo.
    echo PATH'e eklemek için:
    echo 1. Windows + R tuşlarına basın
    echo 2. "sysdm.cpl" yazın ve Enter'a basın
    echo 3. "Advanced" sekmesine gidin
    echo 4. "Environment Variables" butonuna tıklayın
    echo 5. "System variables" bölümünde "Path" seçin ve "Edit" tıklayın
    echo 6. "New" tıklayın ve "C:\flutter\bin" ekleyin
    echo 7. Tüm pencereleri "OK" ile kapatın
    echo 8. Yeni bir Command Prompt açın
)

pause