# Flutter Kurulum Rehberi

## 1. Flutter SDK İndirme

1. https://docs.flutter.dev/get-started/install/windows adresine gidin
2. "Get the Flutter SDK" bölümünden ZIP dosyasını indirin
3. ZIP dosyasını `C:\flutter` klasörüne çıkarın

## 2. PATH Ayarları

1. Windows + R tuşlarına basın
2. `sysdm.cpl` yazın ve Enter'a basın
3. "Advanced" sekmesine gidin
4. "Environment Variables" butonuna tıklayın
5. "System variables" bölümünde "Path" seçin ve "Edit" tıklayın
6. "New" tıklayın ve `C:\flutter\bin` ekleyin
7. Tüm pencereleri "OK" ile kapatın

## 3. Kurulumu Doğrulama

Yeni bir Command Prompt açın ve şu komutu çalıştırın:
```
flutter doctor
```

## 4. Android Studio (İsteğe Bağlı)

Eğer Android Studio kurulu değilse:
1. https://developer.android.com/studio adresinden indirin
2. Kurun ve ilk açılışta SDK'ları indirin

## 5. USB Debugging

Android cihazınızda:
1. Ayarlar > Telefon Hakkında > Yapı Numarası'na 7 kez tıklayın
2. Ayarlar > Geliştirici Seçenekleri > USB Hata Ayıklama'yı açın
3. Cihazı USB ile bilgisayara bağlayın