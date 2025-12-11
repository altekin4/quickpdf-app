@echo off
chcp 65001 >nul
color 0A
echo.
echo ████████████████████████████████████████████████████████████
echo ██                                                        ██
echo ██        🚀 APK Build - Türkçe Karakter Bypass          ██
echo ██                                                        ██
echo ████████████████████████████████████████████████████████████
echo.

echo 🔧 Türkçe karakter sorunu için environment bypass...
echo.

REM Set English locale temporarily
set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8

REM Set Flutter cache to temp directory
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
set PUB_CACHE=%TEMP%\pub_cache
set FLUTTER_ROOT=C:\flutter

echo 📱 Android cihaz kontrolü...
flutter devices

echo.
echo 🧹 Temizlik işlemleri...
cd quickpdf_app
flutter clean

echo.
echo 📦 Dependencies...
flutter pub get

echo.
echo 🔨 APK Build başlatılıyor...
echo ⚠️  Bu işlem 5-10 dakika sürebilir...
echo.

REM Try different build approaches
echo 🎯 Deneme 1: Normal release build...
flutter build apk --release --verbose

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 🎯 Deneme 2: Debug build...
    flutter build apk --debug --verbose
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo 🎯 Deneme 3: Profile build...
        flutter build apk --profile --verbose
        
        if %ERRORLEVEL% NEQ 0 (
            echo.
            echo 🎯 Deneme 4: Split per ABI...
            flutter build apk --release --split-per-abi --verbose
            
            if %ERRORLEVEL% NEQ 0 (
                echo.
                echo 🎯 Deneme 5: No tree shake...
                flutter build apk --release --no-tree-shake-icons --verbose
                
                if %ERRORLEVEL% NEQ 0 (
                    echo.
                    echo ❌ Tüm build denemeleri başarısız!
                    echo 💡 GitHub Actions kullanmanız öneriliyor.
                    echo.
                    pause
                    exit /b 1
                )
            )
        )
    )
)

echo.
echo ✅ APK Build başarılı!
echo.

REM Find APK file
for /r "build\app\outputs\flutter-apk" %%f in (*.apk) do (
    echo 📱 APK bulundu: %%f
    set APK_PATH=%%f
)

if defined APK_PATH (
    echo.
    echo 🔄 Android cihaza yükleniyor...
    adb install "%APK_PATH%"
    
    if %ERRORLEVEL% EQU 0 (
        echo ✅ APK başarıyla yüklendi!
        echo 🎉 Cihazınızda QuickPDF uygulamasını açabilirsiniz.
    ) else (
        echo ⚠️  Otomatik yükleme başarısız.
        echo 💡 Manuel yükleme için APK dosyası: %APK_PATH%
    )
) else (
    echo ❌ APK dosyası bulunamadı!
)

echo.
echo ========================================
echo           İşlem Tamamlandı!
echo ========================================
echo.
pause