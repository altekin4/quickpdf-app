# Online Flutter APK Builder Rehberi

## 1. GitHub Repository Oluşturma

1. GitHub'da yeni repository oluşturun
2. Proje dosyalarını upload edin
3. GitHub Actions ile otomatik build

## 2. Alternatif Online Builders

### FlutterFlow
- https://flutterflow.io/
- Drag & drop interface
- APK export özelliği

### Codemagic
- https://codemagic.io/
- GitHub entegrasyonu
- Ücretsiz build dakikaları

### GitHub Actions (Önerilen)
```yaml
name: Build APK
on:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    - run: flutter pub get
    - run: flutter build apk --debug
    - uses: actions/upload-artifact@v2
      with:
        name: apk
        path: build/app/outputs/flutter-apk/app-debug.apk
```

## 3. Manuel APK Oluşturma

Eğer Flutter kurulumu tamamlanırsa:
```bash
cd quickpdf_app
flutter pub get
flutter build apk --debug
```

APK dosyası: `build/app/outputs/flutter-apk/app-debug.apk`