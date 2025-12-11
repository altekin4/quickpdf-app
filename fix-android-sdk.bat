@echo off
echo ========================================
echo Android SDK Cmdline Tools Kurulum
echo ========================================
echo.

set ANDROID_HOME=C:\Users\AnılTekin\AppData\Local\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%

echo Android SDK Path: %ANDROID_HOME%
echo.

REM Cmdline tools klasörü oluştur
if not exist "%ANDROID_HOME%\cmdline-tools" mkdir "%ANDROID_HOME%\cmdline-tools"
if not exist "%ANDROID_HOME%\cmdline-tools\latest" mkdir "%ANDROID_HOME%\cmdline-tools\latest"

echo Cmdline tools indiriliyor...
echo.

REM Cmdline tools URL (en son sürüm)
set CMDTOOLS_URL=https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip
set CMDTOOLS_ZIP=%TEMP%\cmdline-tools.zip

echo URL: %CMDTOOLS_URL%
echo Hedef: %CMDTOOLS_ZIP%
echo.

REM PowerShell ile indir
powershell -Command "& {Invoke-WebRequest -Uri '%CMDTOOLS_URL%' -OutFile '%CMDTOOLS_ZIP%'}"

if exist "%CMDTOOLS_ZIP%" (
    echo ✅ İndirme başarılı!
    echo.
    
    echo Çıkarılıyor...
    powershell -Command "& {Expand-Archive -Path '%CMDTOOLS_ZIP%' -DestinationPath '%TEMP%\cmdtools' -Force}"
    
    REM Dosyaları doğru yere taşı
    xcopy "%TEMP%\cmdtools\cmdline-tools\*" "%ANDROID_HOME%\cmdline-tools\latest\" /E /I /Y
    
    echo ✅ Kurulum tamamlandı!
    echo.
    
    REM Temizlik
    del "%CMDTOOLS_ZIP%"
    rmdir /s /q "%TEMP%\cmdtools"
    
) else (
    echo ❌ İndirme başarısız!
    echo.
    echo Manuel kurulum için:
    echo 1. https://developer.android.com/studio#command-line-tools-only
    echo 2. commandlinetools-win-*_latest.zip indir
    echo 3. %ANDROID_HOME%\cmdline-tools\latest\ klasörüne çıkar
    echo.
    pause
    exit /b 1
)

echo.
echo PATH güncelleniyor...
setx ANDROID_HOME "%ANDROID_HOME%"
setx ANDROID_SDK_ROOT "%ANDROID_HOME%"

echo.
echo ========================================
echo ✅ Android SDK Cmdline Tools Kuruldu!
echo ========================================
echo.
echo Şimdi lisansları kabul edin:
echo flutter doctor --android-licenses
echo.
echo Sonra Flutter doctor kontrol edin:
echo flutter doctor
echo.

pause