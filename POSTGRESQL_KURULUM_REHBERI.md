# 🐘 PostgreSQL Kurulum Rehberi

## 📥 Hızlı Kurulum

### **Seçenek 1: Winget ile Kurulum (Önerilen)**
```bash
# PowerShell'i yönetici olarak açın
winget install PostgreSQL.PostgreSQL.17
```

### **Seçenek 2: Manuel İndirme**
1. https://www.postgresql.org/download/windows/ adresine gidin
2. "Download the installer" butonuna tıklayın
3. PostgreSQL 17.x sürümünü indirin
4. İndirilen .exe dosyasını çalıştırın

## ⚙️ Kurulum Ayarları

### **Kurulum Sırasında:**
- **Port**: 5432 (varsayılan)
- **Superuser Password**: `postgres` (basit tutun)
- **Locale**: Turkish, Turkey (veya English)
- **Components**: Tümünü seçin

### **Kurulum Sonrası Kontrol:**
```bash
# PostgreSQL servisini kontrol edin
Get-Service -Name postgresql*

# psql komutunu test edin
psql --version
```

## 🗄️ Database Oluşturma

### **Yöntem 1: psql ile**
```bash
# PostgreSQL'e bağlan
psql -U postgres -h localhost

# Database oluştur
CREATE DATABASE quickpdf_db;

# Çıkış
\q
```

### **Yöntem 2: pgAdmin ile**
1. pgAdmin'i açın (Start Menu → PostgreSQL → pgAdmin)
2. Servers → PostgreSQL → Databases
3. Sağ tık → Create → Database
4. Name: `quickpdf_db`
5. Save

## 🔧 Backend Konfigürasyonu

### **.env Dosyası Kontrolü**
```env
# quickpdf_backend/.env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/quickpdf_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=quickpdf_db
DB_USER=postgres
DB_PASSWORD=postgres
```

### **Bağlantı Testi**
```bash
cd quickpdf_backend
npm run test:db
# veya
node -e "require('./dist/config/database').testConnection()"
```

## 🚀 Hızlı Başlatma

### **Otomatik Kurulum Scripti**
```bash
# Ana klasörde çalıştırın
DATABASE_KURULUM.bat
```

### **Manuel Adımlar**
```bash
# 1. Database oluştur
createdb -U postgres quickpdf_db

# 2. Backend dependencies
cd quickpdf_backend
npm install

# 3. Migration çalıştır
npm run migrate:up

# 4. Backend başlat
npm run dev

# 5. Test et
curl http://localhost:3000/health
```

## 🔍 Sorun Giderme

### **PostgreSQL Başlamıyor**
```bash
# Servisi başlat
net start postgresql-x64-17

# Veya Services.msc'den manuel başlat
```

### **Bağlantı Hatası**
```bash
# Port kontrolü
netstat -an | findstr :5432

# Firewall kontrolü
# Windows Defender Firewall → Allow an app
# PostgreSQL'i ekleyin
```

### **Password Hatası**
```bash
# Password sıfırla
psql -U postgres
ALTER USER postgres PASSWORD 'postgres';
```

### **Database Bulunamıyor**
```bash
# Mevcut database'leri listele
psql -U postgres -l

# Database oluştur
createdb -U postgres quickpdf_db
```

## 📊 Kurulum Doğrulama

### **Kontrol Listesi**
- [ ] PostgreSQL servisi çalışıyor
- [ ] psql komutu çalışıyor
- [ ] quickpdf_db database'i oluşturuldu
- [ ] Backend .env dosyası doğru
- [ ] Migration'lar çalıştırıldı
- [ ] Backend server başladı
- [ ] Health check başarılı

### **Test Komutları**
```bash
# PostgreSQL versiyonu
psql --version

# Database bağlantısı
psql -U postgres -d quickpdf_db -c "SELECT version();"

# Backend health check
curl http://localhost:3000/health

# API test
curl http://localhost:3000/api/v1
```

## 🎯 Başarı Kriterleri

### **PostgreSQL Hazır**
```json
{
  "status": "OK",
  "database": "connected",
  "version": "PostgreSQL 17.x"
}
```

### **Backend Hazır**
```json
{
  "status": "OK",
  "timestamp": "2024-12-11T...",
  "uptime": 123.45,
  "environment": "development",
  "version": "1.0.0"
}
```

---

**💡 Not**: Kurulum tamamlandıktan sonra `HIZLI_BASLATMA_REHBERI.bat` ile full stack test yapabilirsiniz.