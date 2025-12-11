# QuickPDF Backend API

QuickPDF uygulamasının backend API servisi. PDF oluşturma, şablon pazaryeri ve kullanıcı yönetimi işlevlerini sağlar.

## Özellikler

### Tamamlanan Özellikler
- ✅ Express.js server kurulumu
- ✅ TypeScript konfigürasyonu
- ✅ Güvenlik middleware'leri (Helmet, CORS, Rate Limiting)
- ✅ JWT kimlik doğrulama
- ✅ Request validation
- ✅ Error handling
- ✅ Logging sistemi
- ✅ API route yapısı

### API Endpoints

#### Authentication (`/api/v1/auth`)
- `POST /register` - Kullanıcı kaydı
- `POST /login` - Kullanıcı girişi
- `POST /refresh` - Token yenileme
- `POST /logout` - Çıkış
- `POST /forgot-password` - Şifre sıfırlama
- `POST /reset-password` - Şifre yenileme

#### Users (`/api/v1/users`)
- `GET /profile` - Kullanıcı profili
- `PUT /profile` - Profil güncelleme
- `PUT /password` - Şifre değiştirme
- `GET /stats` - Kullanıcı istatistikleri
- `POST /profile-picture` - Profil fotoğrafı yükleme
- `DELETE /account` - Hesap silme

#### Templates (`/api/v1/templates`)
- `GET /` - Şablon listesi (filtreleme, arama)
- `GET /:id` - Şablon detayı
- `POST /` - Yeni şablon oluşturma (creator)
- `PUT /:id` - Şablon güncelleme (creator)
- `DELETE /:id` - Şablon silme (creator)
- `GET /my/templates` - Kullanıcının şablonları

#### PDF Generation (`/api/v1/pdf`)
- `POST /generate` - Metinden PDF oluşturma
- `POST /generate-from-template` - Şablondan PDF oluşturma
- `GET /download/:documentId` - PDF indirme
- `GET /documents` - Kullanıcı belgeleri
- `DELETE /documents/:documentId` - Belge silme
- `POST /preview-template` - Şablon önizleme

#### Marketplace (`/api/v1/marketplace`)
- `GET /categories` - Kategori listesi
- `POST /purchase` - Şablon satın alma
- `GET /purchases` - Kullanıcı satın alımları
- `POST /rate` - Şablon değerlendirme
- `GET /templates/:templateId/ratings` - Şablon değerlendirmeleri
- `GET /featured` - Öne çıkan şablonlar
- `GET /popular` - Popüler şablonlar
- `GET /earnings` - Creator kazançları

#### Admin (`/api/v1/admin`)
- `GET /dashboard` - Admin dashboard
- `GET /templates/pending` - Onay bekleyen şablonlar
- `PUT /templates/:templateId/approve` - Şablon onaylama
- `PUT /templates/:templateId/reject` - Şablon reddetme
- `GET /users` - Kullanıcı listesi
- `PUT /users/:userId/ban` - Kullanıcı engelleme
- `GET /categories` - Kategori yönetimi
- `POST /categories` - Yeni kategori
- `GET /payments` - Ödeme istatistikleri

## Kurulum

### Gereksinimler
- Node.js 18+
- PostgreSQL 13+
- Redis 6+

### Adımlar

1. Bağımlılıkları yükleyin:
```bash
npm install
```

2. Environment dosyasını oluşturun:
```bash
cp .env.example .env
```

3. Environment değişkenlerini düzenleyin:
```bash
nano .env
```

4. TypeScript'i derleyin:
```bash
npm run build
```

5. Geliştirme modunda çalıştırın:
```bash
npm run dev
```

## Geliştirme

### Komutlar
```bash
npm run dev                    # Geliştirme modu (nodemon)
npm run build                  # TypeScript derleme
npm start                      # Production modu
npm test                       # Tüm testleri çalıştır
npm run test:properties        # Property-based testleri çalıştır
npm run test:properties:run    # Property test runner ile detaylı rapor
npm run test:coverage          # Test coverage raporu
npm run lint                   # ESLint kontrolü
npm run lint:fix               # ESLint otomatik düzeltme
npm run migrate:up             # Veritabanı migration'larını çalıştır
npm run migrate:status         # Migration durumunu kontrol et
```

### Proje Yapısı
```
src/
├── middleware/      # Express middleware'leri
├── routes/          # API route'ları
├── controllers/     # İş mantığı (gelecekte)
├── services/        # Servis katmanı (gelecekte)
├── models/          # Veri modelleri (gelecekte)
├── utils/           # Yardımcı fonksiyonlar
├── types/           # TypeScript tip tanımları (gelecekte)
└── server.ts        # Ana server dosyası
```

### Güvenlik Özellikleri
- **Helmet**: HTTP güvenlik başlıkları
- **CORS**: Cross-origin resource sharing
- **Rate Limiting**: İstek sınırlama (Property-based test ile doğrulanmış)
- **JWT**: Token tabanlı kimlik doğrulama
- **Input Validation**: Giriş doğrulama
- **Error Handling**: Güvenli hata yönetimi

### Property-Based Testing
Sistem doğruluğu property-based testler ile garanti edilir:
- **Property 18**: Rate limiting enforcement - 100+ iterasyon ile test edilir
- **System Setup Properties**: Sistem kurulumu ve kararlılık testleri
- **Fast-check** kütüphanesi ile rastgele test verisi üretimi
- Minimum 100 iterasyon ile kapsamlı test coverage

### Logging
Winston kullanılarak kapsamlı loglama:
- Console output (development)
- File output (production)
- Error tracking
- Request logging

## API Kullanımı

### Kimlik Doğrulama
```bash
# Kayıt
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123456","fullName":"Test User"}'

# Giriş
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123456"}'
```

### Korumalı Endpoint'ler
```bash
# Authorization header ile
curl -X GET http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Deployment

### Production Hazırlığı
1. Environment değişkenlerini production için ayarlayın
2. SSL sertifikası yapılandırın
3. Reverse proxy (nginx) kurun
4. Process manager (PM2) kullanın
5. Monitoring ve logging ayarlayın

### Docker (Gelecekte)
```bash
docker build -t quickpdf-backend .
docker run -p 3000:3000 quickpdf-backend
```

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun
3. Değişiklikleri commit edin
4. Push yapın
5. Pull Request oluşturun

## Lisans

MIT