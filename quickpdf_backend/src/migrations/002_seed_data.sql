-- Seed data for QuickPDF database
-- Insert initial categories, admin user, and sample templates

-- Insert main categories
INSERT INTO categories (id, name, slug, description, icon, order_index) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Hukuk', 'hukuk', 'Hukuki belgeler ve dilekçeler', 'gavel', 1),
    ('550e8400-e29b-41d4-a716-446655440002', 'Eğitim', 'egitim', 'Eğitim kurumları için belgeler', 'school', 2),
    ('550e8400-e29b-41d4-a716-446655440003', 'İş Dünyası', 'is-dunyasi', 'İş ve ticaret belgeleri', 'business', 3),
    ('550e8400-e29b-41d4-a716-446655440004', 'Tutanaklar', 'tutanaklar', 'Toplantı ve görüşme tutanakları', 'description', 4),
    ('550e8400-e29b-41d4-a716-446655440005', 'Sözleşmeler', 'sozlesmeler', 'Çeşitli sözleşme türleri', 'assignment', 5),
    ('550e8400-e29b-41d4-a716-446655440006', 'İnsan Kaynakları', 'insan-kaynaklari', 'İK süreçleri için belgeler', 'people', 6),
    ('550e8400-e29b-41d4-a716-446655440007', 'Kamu/Resmi Belgeler', 'kamu-resmi', 'Devlet kurumları için belgeler', 'account_balance', 7),
    ('550e8400-e29b-41d4-a716-446655440008', 'Serbest Kategori', 'serbest', 'Diğer belge türleri', 'folder_open', 8);

-- Insert subcategories
INSERT INTO categories (id, name, slug, parent_id, description, order_index) VALUES
    -- Hukuk alt kategorileri
    ('550e8400-e29b-41d4-a716-446655440011', 'Dilekçeler', 'dilekce', '550e8400-e29b-41d4-a716-446655440001', 'Çeşitli dilekçe türleri', 1),
    ('550e8400-e29b-41d4-a716-446655440012', 'Vekâletnameler', 'vekaletname', '550e8400-e29b-41d4-a716-446655440001', 'Vekâletname şablonları', 2),
    ('550e8400-e29b-41d4-a716-446655440013', 'Dava Dilekçeleri', 'dava-dilekce', '550e8400-e29b-41d4-a716-446655440001', 'Mahkeme dilekçeleri', 3),
    
    -- Eğitim alt kategorileri
    ('550e8400-e29b-41d4-a716-446655440021', 'Öğrenci Dilekçeleri', 'ogrenci-dilekce', '550e8400-e29b-41d4-a716-446655440002', 'Öğrenci başvuru ve dilekçeleri', 1),
    ('550e8400-e29b-41d4-a716-446655440022', 'Veli Görüşme Tutanakları', 'veli-gorusme', '550e8400-e29b-41d4-a716-446655440002', 'Veli görüşme kayıtları', 2),
    ('550e8400-e29b-41d4-a716-446655440023', 'Staj Başvuruları', 'staj-basvuru', '550e8400-e29b-41d4-a716-446655440002', 'Staj başvuru formları', 3),
    
    -- İş Dünyası alt kategorileri
    ('550e8400-e29b-41d4-a716-446655440031', 'İş Sözleşmeleri', 'is-sozlesme', '550e8400-e29b-41d4-a716-446655440003', 'Çalışan sözleşmeleri', 1),
    ('550e8400-e29b-41d4-a716-446655440032', 'Teklif Formları', 'teklif-form', '550e8400-e29b-41d4-a716-446655440003', 'İş teklif belgeleri', 2),
    ('550e8400-e29b-41d4-a716-446655440033', 'Faturalar', 'fatura', '550e8400-e29b-41d4-a716-446655440003', 'Fatura şablonları', 3);

-- Insert common tags
INSERT INTO tags (name, slug) VALUES
    ('izin', 'izin'),
    ('dilekçe', 'dilekce'),
    ('resmi', 'resmi'),
    ('sözleşme', 'sozlesme'),
    ('başvuru', 'basvuru'),
    ('iş', 'is'),
    ('eğitim', 'egitim'),
    ('hukuk', 'hukuk'),
    ('fatura', 'fatura'),
    ('tutanak', 'tutanak'),
    ('vekâletname', 'vekaletname'),
    ('staj', 'staj'),
    ('burs', 'burs'),
    ('özgeçmiş', 'ozgecmis'),
    ('teklif', 'teklif');

-- Create admin user (password: admin123)
INSERT INTO users (id, email, password_hash, full_name, role, is_verified, is_active) VALUES
    ('550e8400-e29b-41d4-a716-446655440100', 'admin@quickpdf.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PqhEIe', 'QuickPDF Admin', 'admin', true, true);

-- Create sample creator user (password: creator123)
INSERT INTO users (id, email, password_hash, full_name, role, is_verified, is_active) VALUES
    ('550e8400-e29b-41d4-a716-446655440101', 'creator@quickpdf.com', '$2a$12$8HqAPvNNp02PzNCeSOl./.ViFo.H54.4IzAWmy/Hs/Ag1.Hy.Sma6', 'Sample Creator', 'creator', true, true);

-- Create sample regular user (password: user123)
INSERT INTO users (id, email, password_hash, full_name, role, is_verified, is_active) VALUES
    ('550e8400-e29b-41d4-a716-446655440102', 'user@quickpdf.com', '$2a$12$6BNUOWmnLGX4f7ErXHv/OOHd01c2HZuFqjAM4NiYzr1.dF25C/K/W', 'Sample User', 'user', true, true);

-- Insert sample templates
INSERT INTO templates (
    id, title, description, category_id, sub_category_id, body, placeholders, 
    created_by, price, is_admin_template, is_verified, is_featured, status, 
    rating, total_ratings, download_count
) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440200',
        'İzin Dilekçesi',
        'Genel amaçlı izin dilekçesi şablonu. Her türlü izin talebi için kullanılabilir.',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440011',
        'Sayın Yetkili,

Ben {ad_soyad}, {tarih} tarihinde aşağıdaki talebimi sunmak isterim:

{talep}

İletişim bilgilerim:
Adres: {adres}
Telefon: {telefon}

Saygılarımla,
{ad_soyad}',
        '{
            "ad_soyad": {
                "type": "string",
                "label": "Ad Soyad",
                "required": true,
                "maxLength": 100,
                "order": 1
            },
            "tarih": {
                "type": "date",
                "label": "Tarih",
                "required": true,
                "defaultValue": "today",
                "order": 2
            },
            "adres": {
                "type": "text",
                "label": "Adres",
                "required": false,
                "maxLength": 200,
                "order": 3
            },
            "talep": {
                "type": "textarea",
                "label": "Talep Detayı",
                "required": true,
                "minLength": 50,
                "maxLength": 1000,
                "order": 4
            },
            "telefon": {
                "type": "phone",
                "label": "Telefon",
                "required": false,
                "format": "TR",
                "order": 5
            }
        }',
        '550e8400-e29b-41d4-a716-446655440100',
        0.00,
        true,
        true,
        true,
        'published',
        4.8,
        245,
        1250
    ),
    (
        '550e8400-e29b-41d4-a716-446655440201',
        'İş Sözleşmesi',
        'Standart iş sözleşmesi şablonu. Çalışan ve işveren bilgilerini içerir.',
        '550e8400-e29b-41d4-a716-446655440003',
        '550e8400-e29b-41d4-a716-446655440031',
        'İŞ SÖZLEŞMESİ

İşveren: {isveren_adi}
Adres: {isveren_adres}

Çalışan: {calisan_adi}
T.C. No: {tc_no}
Adres: {calisan_adres}

Pozisyon: {pozisyon}
Maaş: {maas} TL
Başlangıç Tarihi: {baslangic_tarihi}

Bu sözleşme {baslangic_tarihi} tarihinde yürürlüğe girer.

İşveren                    Çalışan
_____________              _____________',
        '{
            "isveren_adi": {
                "type": "string",
                "label": "İşveren Adı",
                "required": true,
                "maxLength": 100,
                "order": 1
            },
            "isveren_adres": {
                "type": "text",
                "label": "İşveren Adresi",
                "required": true,
                "maxLength": 200,
                "order": 2
            },
            "calisan_adi": {
                "type": "string",
                "label": "Çalışan Adı",
                "required": true,
                "maxLength": 100,
                "order": 3
            },
            "tc_no": {
                "type": "string",
                "label": "T.C. Kimlik No",
                "required": true,
                "pattern": "^[0-9]{11}$",
                "order": 4
            },
            "calisan_adres": {
                "type": "text",
                "label": "Çalışan Adresi",
                "required": true,
                "maxLength": 200,
                "order": 5
            },
            "pozisyon": {
                "type": "string",
                "label": "Pozisyon",
                "required": true,
                "maxLength": 100,
                "order": 6
            },
            "maas": {
                "type": "number",
                "label": "Maaş (TL)",
                "required": true,
                "minValue": 0,
                "order": 7
            },
            "baslangic_tarihi": {
                "type": "date",
                "label": "Başlangıç Tarihi",
                "required": true,
                "order": 8
            }
        }',
        '550e8400-e29b-41d4-a716-446655440101',
        25.00,
        false,
        true,
        false,
        'published',
        4.5,
        89,
        456
    ),
    (
        '550e8400-e29b-41d4-a716-446655440202',
        'Staj Başvuru Formu',
        'Üniversite öğrencileri için staj başvuru formu şablonu.',
        '550e8400-e29b-41d4-a716-446655440002',
        '550e8400-e29b-41d4-a716-446655440023',
        'STAJ BAŞVURU FORMU

Öğrenci Bilgileri:
Ad Soyad: {ogrenci_adi}
Öğrenci No: {ogrenci_no}
Üniversite: {universite}
Bölüm: {bolum}
Sınıf: {sinif}

İletişim Bilgileri:
E-posta: {email}
Telefon: {telefon}

Staj Bilgileri:
Staj Türü: {staj_turu}
Başlangıç Tarihi: {baslangic_tarihi}
Bitiş Tarihi: {bitis_tarihi}
Staj Süresi: {staj_suresi} gün

Başvuru Tarihi: {baslangic_tarihi}

Öğrenci İmzası: ________________',
        '{
            "ogrenci_adi": {
                "type": "string",
                "label": "Öğrenci Adı Soyadı",
                "required": true,
                "maxLength": 100,
                "order": 1
            },
            "ogrenci_no": {
                "type": "string",
                "label": "Öğrenci Numarası",
                "required": true,
                "maxLength": 20,
                "order": 2
            },
            "universite": {
                "type": "string",
                "label": "Üniversite",
                "required": true,
                "maxLength": 100,
                "order": 3
            },
            "bolum": {
                "type": "string",
                "label": "Bölüm",
                "required": true,
                "maxLength": 100,
                "order": 4
            },
            "sinif": {
                "type": "select",
                "label": "Sınıf",
                "required": true,
                "options": ["1", "2", "3", "4", "Yüksek Lisans", "Doktora"],
                "order": 5
            },
            "email": {
                "type": "email",
                "label": "E-posta",
                "required": true,
                "order": 6
            },
            "telefon": {
                "type": "phone",
                "label": "Telefon",
                "required": true,
                "format": "TR",
                "order": 7
            },
            "staj_turu": {
                "type": "select",
                "label": "Staj Türü",
                "required": true,
                "options": ["Zorunlu Staj", "Gönüllü Staj", "Yaz Stajı"],
                "order": 8
            },
            "baslangic_tarihi": {
                "type": "date",
                "label": "Başlangıç Tarihi",
                "required": true,
                "order": 9
            },
            "bitis_tarihi": {
                "type": "date",
                "label": "Bitiş Tarihi",
                "required": true,
                "order": 10
            },
            "staj_suresi": {
                "type": "number",
                "label": "Staj Süresi (Gün)",
                "required": true,
                "minValue": 1,
                "maxValue": 365,
                "order": 11
            }
        }',
        '550e8400-e29b-41d4-a716-446655440100',
        0.00,
        true,
        true,
        false,
        'published',
        4.2,
        67,
        234
    );

-- Link templates with tags
INSERT INTO template_tags (template_id, tag_id) VALUES
    ('550e8400-e29b-41d4-a716-446655440200', (SELECT id FROM tags WHERE name = 'izin')),
    ('550e8400-e29b-41d4-a716-446655440200', (SELECT id FROM tags WHERE name = 'dilekçe')),
    ('550e8400-e29b-41d4-a716-446655440200', (SELECT id FROM tags WHERE name = 'resmi')),
    
    ('550e8400-e29b-41d4-a716-446655440201', (SELECT id FROM tags WHERE name = 'sözleşme')),
    ('550e8400-e29b-41d4-a716-446655440201', (SELECT id FROM tags WHERE name = 'iş')),
    
    ('550e8400-e29b-41d4-a716-446655440202', (SELECT id FROM tags WHERE name = 'staj')),
    ('550e8400-e29b-41d4-a716-446655440202', (SELECT id FROM tags WHERE name = 'başvuru')),
    ('550e8400-e29b-41d4-a716-446655440202', (SELECT id FROM tags WHERE name = 'eğitim'));

-- Update category template counts
UPDATE categories SET template_count = (
    SELECT COUNT(*) FROM templates 
    WHERE category_id = categories.id AND status = 'published'
);

-- Update tag usage counts
UPDATE tags SET usage_count = (
    SELECT COUNT(*) FROM template_tags 
    WHERE tag_id = tags.id
);