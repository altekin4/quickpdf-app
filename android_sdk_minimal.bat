@echo off
echo Minimal Android SDK Kurulumu
echo.

REM Android SDK klasörü oluştur
if not exist "C:\Android" (
    mkdir "C:\Android"
    mkdir "C:\Android\Sdk"
    mkdir "C:\Android\Sdk\platform-tools"
)

echo.
echo Android SDK Platform Tools indiriliyor...
echo.
echo Lütfen şu adımları takip edin:
echo.
echo 1. https://developer.android.com/studio/releases/platform-tools adresine gidin
echo 2. "Download SDK Platform-Tools for Windows" linkine tıklayın
echo 3. ZIP dosyasını C:\Android\Sdk\ klasörüne çıkarın
echo 4. PATH'e C:\Android\Sdk\platform-tools ekleyin
echo.

REM Flutter Android SDK ayarı
echo Flutter Android SDK ayarlanıyor...
C:\flutter\bin\flutter.bat config --android-sdk "C:\Android\Sdk"

echo.
echo Kurulum tamamlandıktan sonra:
echo flutter devices
echo komutunu çalıştırın.

pause