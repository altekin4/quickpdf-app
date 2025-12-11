@echo off
echo ========================================
echo   QuickPDF APK Build - Turkish Fix
echo ========================================

cd quickpdf_clean

echo 🔧 Setting environment variables...
set FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false
set FLUTTER_WEB_USE_SKIA=true
set FLUTTER_DISABLE_SHADER_COMPILATION=true
set JAVA_OPTS=-Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US

echo 🧹 Cleaning project...
flutter clean

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building APK with Turkish character fix...
flutter build apk --debug --target=lib/main_mobile.dart --dart-define=FLUTTER_ENGINE_SWITCH_TO_IMPELLER=false --dart-define=FLUTTER_WEB_USE_SKIA=true --dart-define=FLUTTER_DISABLE_SHADER_COMPILATION=true --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo ✅ APK build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-debug.apk
    
    echo 📲 Installing to connected device...
    flutter install --device-id=RFCW41B4FSR
    
    if %ERRORLEVEL% EQU 0 (
        echo ✅ APK installed successfully!
    ) else (
        echo ❌ APK installation failed
    )
) else (
    echo ❌ APK build failed
)

pause