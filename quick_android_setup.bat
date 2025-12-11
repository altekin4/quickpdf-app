@echo off
echo QuickPDF Android Kurulum
echo.

REM Android klasörü oluştur
if not exist "C:\Android" mkdir "C:\Android"
if not exist "C:\Android\Sdk" mkdir "C:\Android\Sdk"

echo Android SDK Platform Tools indiriliyor...
echo.

REM PowerShell ile platform tools indir
powershell -Command "& {
    $url = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
    $output = 'C:\Android\platform-tools.zip'
    Write-Host 'Platform Tools indiriliyor...'
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Host 'Dosya çıkarılıyor...'
    Expand-Archive -Path $output -DestinationPath 'C:\Android\Sdk\' -Force
    Remove-Item $output
    Write-Host 'Platform Tools kuruldu!'
}"

REM PATH'e ekle (geçici)
set PATH=%PATH%;C:\Android\Sdk\platform-tools

REM Flutter Android SDK ayarı
echo.
echo Flutter Android SDK ayarlanıyor...
C:\flutter\bin\flutter.bat config --android-sdk "C:\Android\Sdk"

echo.
echo Kurulum tamamlandı!
echo.
echo Şimdi şu komutları çalıştırın:
echo 1. flutter devices (cihazı kontrol edin)
echo 2. flutter build apk --debug (APK oluşturun)
echo 3. flutter install (cihaza kurun)

pause