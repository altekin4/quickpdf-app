const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Mock data
const mockTemplates = [
  {
    id: '1',
    title: 'İş Mektubu Şablonu',
    description: 'Profesyonel iş mektupları için hazır şablon',
    category: 'İş',
    price: 0,
    rating: 4.5,
    downloadCount: 1250,
    createdAt: '2024-01-15',
    placeholders: {
      company_name: { type: 'string', label: 'Şirket Adı', required: true },
      recipient_name: { type: 'string', label: 'Alıcı Adı', required: true },
      date: { type: 'date', label: 'Tarih', required: true },
      content: { type: 'text', label: 'Mektup İçeriği', required: true }
    }
  },
  {
    id: '2',
    title: 'Fatura Şablonu',
    description: 'Standart fatura formatı',
    category: 'Finans',
    price: 25,
    rating: 4.8,
    downloadCount: 890,
    createdAt: '2024-02-01',
    placeholders: {
      invoice_number: { type: 'string', label: 'Fatura No', required: true },
      customer_name: { type: 'string', label: 'Müşteri Adı', required: true },
      amount: { type: 'number', label: 'Tutar', required: true },
      due_date: { type: 'date', label: 'Vade Tarihi', required: true }
    }
  },
  {
    id: '3',
    title: 'CV Şablonu',
    description: 'Modern özgeçmiş şablonu',
    category: 'Kişisel',
    price: 15,
    rating: 4.3,
    downloadCount: 2100,
    createdAt: '2024-01-20',
    placeholders: {
      full_name: { type: 'string', label: 'Ad Soyad', required: true },
      email: { type: 'email', label: 'E-posta', required: true },
      phone: { type: 'string', label: 'Telefon', required: true },
      experience: { type: 'text', label: 'Deneyim', required: true }
    }
  }
];

const mockCategories = [
  { id: '1', name: 'İş', description: 'İş ile ilgili belgeler' },
  { id: '2', name: 'Finans', description: 'Mali belgeler' },
  { id: '3', name: 'Kişisel', description: 'Kişisel belgeler' },
  { id: '4', name: 'Eğitim', description: 'Eğitim belgeleri' }
];

// Routes
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'OK', message: 'QuickPDF Mock Server is running' });
});

// Template routes
app.get('/api/v1/templates', (req, res) => {
  const { category, search, page = 1, limit = 10 } = req.query;
  let filteredTemplates = [...mockTemplates];
  
  if (category) {
    filteredTemplates = filteredTemplates.filter(t => t.category === category);
  }
  
  if (search) {
    filteredTemplates = filteredTemplates.filter(t => 
      t.title.toLowerCase().includes(search.toLowerCase()) ||
      t.description.toLowerCase().includes(search.toLowerCase())
    );
  }
  
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginatedTemplates = filteredTemplates.slice(startIndex, endIndex);
  
  res.json({
    success: true,
    data: {
      templates: paginatedTemplates,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: filteredTemplates.length,
        pages: Math.ceil(filteredTemplates.length / limit)
      }
    }
  });
});

app.get('/api/v1/templates/:id', (req, res) => {
  const template = mockTemplates.find(t => t.id === req.params.id);
  if (!template) {
    return res.status(404).json({ success: false, message: 'Şablon bulunamadı' });
  }
  res.json({ success: true, data: template });
});

// Category routes
app.get('/api/v1/categories', (req, res) => {
  res.json({ success: true, data: mockCategories });
});

// Auth routes
app.post('/api/v1/auth/register', (req, res) => {
  const { email, password, name } = req.body;
  res.json({
    success: true,
    data: {
      user: { id: '1', email, name, role: 'user' },
      token: 'mock-jwt-token'
    }
  });
});

app.post('/api/v1/auth/login', (req, res) => {
  const { email, password } = req.body;
  res.json({
    success: true,
    data: {
      user: { id: '1', email, name: 'Test User', role: 'user' },
      token: 'mock-jwt-token'
    }
  });
});

// PDF generation
app.post('/api/v1/pdf/generate', (req, res) => {
  const { content, template_id, data } = req.body;
  
  // Simulate PDF generation
  setTimeout(() => {
    res.json({
      success: true,
      data: {
        pdf_url: '/api/v1/pdf/download/mock-pdf-id',
        filename: 'generated-document.pdf',
        size: 245760
      }
    });
  }, 1000);
});

app.post('/api/v1/pdf/generate-from-template', (req, res) => {
  const { template_id, data } = req.body;
  
  setTimeout(() => {
    res.json({
      success: true,
      data: {
        pdf_url: '/api/v1/pdf/download/template-pdf-id',
        filename: 'template-document.pdf',
        size: 189440
      }
    });
  }, 1500);
});

// Documents
app.get('/api/v1/documents', (req, res) => {
  res.json({
    success: true,
    data: {
      documents: [
        {
          id: '1',
          title: 'İş Mektubu - ABC Şirketi',
          created_at: '2024-12-10T15:30:00Z',
          size: 245760,
          type: 'business_letter'
        },
        {
          id: '2',
          title: 'Fatura #2024-001',
          created_at: '2024-12-09T10:15:00Z',
          size: 189440,
          type: 'invoice'
        }
      ]
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Sunucu hatası' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint bulunamadı' });
});

app.listen(PORT, () => {
  console.log(`🚀 QuickPDF Mock Server running on http://localhost:${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/api/v1/health`);
  console.log(`📄 Templates: http://localhost:${PORT}/api/v1/templates`);
});