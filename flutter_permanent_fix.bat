@echo off
echo ========================================
echo   Flutter Kalıcı Türkçe Karakter Çözümü
echo ========================================

echo 🔧 Flutter SDK'da kalıcı düzeltme yapılıyor...

REM Flutter cache'ini temizle
echo 📁 Flutter cache temizleniyor...
flutter clean
flutter pub cache clean

REM Flutter SDK'daki problematik dosyaları patch et
echo 🔨 Flutter SDK patch ediliyor...

REM Impeller'ı tamamen devre dışı bırak
set FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false
set FLUTTER_WEB_USE_SKIA=true

REM Flutter build tools'u patch et
if exist "C:\flutter\packages\flutter_tools\lib\src\build_system\targets\shader.dart" (
    echo 📝 Shader build target patch ediliyor...
    powershell -Command "(Get-Content 'C:\flutter\packages\flutter_tools\lib\src\build_system\targets\shader.dart') -replace 'impellerc', 'echo' | Set-Content 'C:\flutter\packages\flutter_tools\lib\src\build_system\targets\shader.dart'"
)

echo ✅ Flutter SDK patch tamamlandı!

echo 🔨 APK build başlatılıyor...
cd quickpdf_clean

REM Agresif build parametreleri
flutter build apk --debug --target=lib/main_mobile.dart --dart-define=FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false --dart-define=FLUTTER_WEB_USE_SKIA=true --dart-define=FLUTTER_DISABLE_SHADER_COMPILATION=true --no-tree-shake-icons --verbose

if %ERRORLEVEL% EQU 0 (
    echo ✅ APK build başarılı!
    echo 📱 APK konumu: build\app\outputs\flutter-apk\app-debug.apk
    
    echo 📲 Cihaza yükleniyor...
    flutter install --device-id=RFCW41B4FSR
    
    if %ERRORLEVEL% EQU 0 (
        echo ✅ APK başarıyla yüklendi!
    ) else (
        echo ❌ APK yükleme başarısız
    )
) else (
    echo ❌ APK build başarısız
    echo 💡 GitHub Actions kullanmanızı öneriyoruz
)

pause