#!/bin/bash

echo "========================================="
echo "    QuickPDF Docker APK Builder"
echo "========================================="

BUILD_TYPE=${1:-debug}

echo "Build Type: $BUILD_TYPE"
echo ""

# Proje dosyalarını kopyala
echo "📁 Proje dosyaları kopyalanıyor..."
cp -r /app/source/* /app/

# Dependencies al
echo "📦 Dependencies alınıyor..."
flutter pub get

# APK build et
echo "🔨 APK build ediliyor..."
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release --split-per-abi
else
    flutter build apk --debug --split-per-abi
fi

# APK dosyalarını output klasörüne kopyala
echo "📤 APK dosyaları kopyalanıyor..."
mkdir -p /app/output
cp build/app/outputs/flutter-apk/*.apk /app/output/

echo ""
echo "✅ Build tamamlandı!"
echo "📂 APK dosyaları: /app/output/"
ls -la /app/output/