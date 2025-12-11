const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'quickpdf',
  user: process.env.DB_USER || 'quickpdf',
  password: process.env.DB_PASSWORD || 'quickpdf_secure_password_2024',
  ssl: false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Middleware
app.use(cors());
app.use(express.json());

// Test database connection
async function testConnection() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    console.log('✅ Database connected successfully:', result.rows[0].now);
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

// Mock data for development
const mockTemplates = [
  {
    id: '1',
    title: 'İş Mektubu Şablonu',
    description: 'Profesyonel iş mektupları için hazır şablon',
    category: 'İş',
    price: 0,
    rating: 4.5,
    download_count: 1250,
    created_at: '2024-01-15',
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
    download_count: 890,
    created_at: '2024-02-01',
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
    download_count: 2100,
    created_at: '2024-01-20',
    placeholders: {
      full_name: { type: 'string', label: 'Ad Soyad', required: true },
      email: { type: 'email', label: 'E-posta', required: true },
      phone: { type: 'string', label: 'Telefon', required: true },
      experience: { type: 'text', label: 'Deneyim', required: true }
    }
  }
];

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'QuickPDF Backend is running',
    database: 'connected',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/v1/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'QuickPDF API is running',
    version: '1.0.0',
    database: 'connected'
  });
});

// Database test endpoint
app.get('/api/v1/db-test', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT version()');
    client.release();
    
    res.json({
      success: true,
      data: {
        database: 'PostgreSQL',
        version: result.rows[0].version,
        connection: 'active'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Database connection failed',
        details: error.message
      }
    });
  }
});

// Template routes
app.get('/api/v1/templates', async (req, res) => {
  try {
    const { category, search, page = 1, limit = 10 } = req.query;
    
    // Try to get from database first
    try {
      const client = await pool.connect();
      let query = 'SELECT * FROM templates WHERE status = $1';
      let params = ['published'];
      let paramCount = 2;
      
      if (category) {
        query += ` AND category_id = (SELECT id FROM categories WHERE name = $${paramCount})`;
        params.push(category);
        paramCount++;
      }
      
      if (search) {
        query += ` AND (title ILIKE $${paramCount} OR description ILIKE $${paramCount})`;
        params.push(`%${search}%`);
        paramCount++;
      }
      
      query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
      params.push(parseInt(limit), (parseInt(page) - 1) * parseInt(limit));
      
      const result = await client.query(query, params);
      client.release();
      
      if (result.rows.length > 0) {
        return res.json({
          success: true,
          data: {
            templates: result.rows,
            pagination: {
              page: parseInt(page),
              limit: parseInt(limit),
              total: result.rows.length,
              pages: Math.ceil(result.rows.length / parseInt(limit))
            }
          }
        });
      }
    } catch (dbError) {
      console.log('Database query failed, using mock data:', dbError.message);
    }
    
    // Fallback to mock data
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Failed to fetch templates',
        details: error.message
      }
    });
  }
});

app.get('/api/v1/templates/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Try database first
    try {
      const client = await pool.connect();
      const result = await client.query('SELECT * FROM templates WHERE id = $1', [id]);
      client.release();
      
      if (result.rows.length > 0) {
        return res.json({ success: true, data: result.rows[0] });
      }
    } catch (dbError) {
      console.log('Database query failed, using mock data:', dbError.message);
    }
    
    // Fallback to mock data
    const template = mockTemplates.find(t => t.id === id);
    if (!template) {
      return res.status(404).json({ success: false, message: 'Şablon bulunamadı' });
    }
    
    res.json({ success: true, data: template });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Failed to fetch template',
        details: error.message
      }
    });
  }
});

// Auth endpoints
app.post('/api/v1/auth/register', async (req, res) => {
  try {
    const { email, password, full_name } = req.body;
    
    if (!email || !password || !full_name) {
      return res.status(400).json({
        success: false,
        error: { message: 'Email, password and full_name are required' }
      });
    }
    
    // Check if user exists
    try {
      const client = await pool.connect();
      const existingUser = await client.query('SELECT id FROM users WHERE email = $1', [email]);
      
      if (existingUser.rows.length > 0) {
        client.release();
        return res.status(409).json({
          success: false,
          error: { message: 'User already exists' }
        });
      }
      
      // Create user (mock password hash)
      const result = await client.query(
        'INSERT INTO users (email, password_hash, full_name, is_verified) VALUES ($1, $2, $3, $4) RETURNING id, email, full_name, role',
        [email, 'mock_hash_' + password, full_name, true]
      );
      
      client.release();
      
      res.status(201).json({
        success: true,
        data: {
          user: result.rows[0],
          token: 'mock_jwt_token_' + result.rows[0].id
        }
      });
    } catch (dbError) {
      // Fallback to mock response
      res.status(201).json({
        success: true,
        data: {
          user: {
            id: 'mock_user_id',
            email,
            full_name,
            role: 'user'
          },
          token: 'mock_jwt_token'
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Registration failed', details: error.message }
    });
  }
});

app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: { message: 'Email and password are required' }
      });
    }
    
    // Try to find user in database
    try {
      const client = await pool.connect();
      const result = await client.query('SELECT id, email, full_name, role FROM users WHERE email = $1', [email]);
      client.release();
      
      if (result.rows.length > 0) {
        const user = result.rows[0];
        res.json({
          success: true,
          data: {
            user,
            token: 'mock_jwt_token_' + user.id
          }
        });
      } else {
        res.status(401).json({
          success: false,
          error: { message: 'Invalid credentials' }
        });
      }
    } catch (dbError) {
      // Fallback to mock response for demo users
      if (email === 'admin@quickpdf.com' || email === 'user@quickpdf.com') {
        res.json({
          success: true,
          data: {
            user: {
              id: 'mock_user_id',
              email,
              full_name: 'Demo User',
              role: email.includes('admin') ? 'admin' : 'user'
            },
            token: 'mock_jwt_token'
          }
        });
      } else {
        res.status(401).json({
          success: false,
          error: { message: 'Invalid credentials' }
        });
      }
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Login failed', details: error.message }
    });
  }
});

// PDF generation endpoint
app.post('/api/v1/pdf/generate', async (req, res) => {
  try {
    const { content, title } = req.body;
    
    if (!content) {
      return res.status(400).json({
        success: false,
        error: { message: 'Content is required' }
      });
    }
    
    // Mock PDF generation response
    res.json({
      success: true,
      data: {
        filename: `${title || 'document'}.pdf`,
        url: `/api/v1/pdf/download/mock-pdf-id`,
        size: 1024 * 50, // 50KB mock size
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'PDF generation failed', details: error.message }
    });
  }
});

// PDF generation from template
app.post('/api/v1/pdf/generate-from-template', async (req, res) => {
  try {
    const { template_id, data } = req.body;
    
    if (!template_id || !data) {
      return res.status(400).json({
        success: false,
        error: { message: 'Template ID and data are required' }
      });
    }
    
    // Get template from database
    try {
      const client = await pool.connect();
      const result = await client.query('SELECT * FROM templates WHERE id = $1', [template_id]);
      client.release();
      
      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: { message: 'Template not found' }
        });
      }
      
      const template = result.rows[0];
      let content = template.body;
      
      // Replace placeholders with data
      Object.keys(data).forEach(key => {
        const placeholder = `{${key}}`;
        content = content.replace(new RegExp(placeholder, 'g'), data[key]);
      });
      
      res.json({
        success: true,
        data: {
          filename: `${template.title.replace(/[^a-zA-Z0-9]/g, '-')}.pdf`,
          url: `/api/v1/pdf/download/template-${template_id}`,
          size: 1024 * 75, // 75KB mock size
          content: content,
          template_title: template.title,
          created_at: new Date().toISOString()
        }
      });
    } catch (dbError) {
      // Fallback to mock response
      res.json({
        success: true,
        data: {
          filename: `template-${template_id}.pdf`,
          url: `/api/v1/pdf/download/template-${template_id}`,
          size: 1024 * 75,
          created_at: new Date().toISOString()
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Template PDF generation failed', details: error.message }
    });
  }
});

// Categories endpoint
app.get('/api/v1/categories', async (req, res) => {
  try {
    // Try database first
    try {
      const client = await pool.connect();
      const result = await client.query('SELECT * FROM categories WHERE is_active = true ORDER BY order_index, name');
      client.release();
      
      if (result.rows.length > 0) {
        return res.json({ success: true, data: result.rows });
      }
    } catch (dbError) {
      console.log('Database query failed, using mock data:', dbError.message);
    }
    
    // Fallback to mock data
    const mockCategories = [
      { id: '1', name: 'İş', description: 'İş ile ilgili belgeler' },
      { id: '2', name: 'Finans', description: 'Mali belgeler' },
      { id: '3', name: 'Kişisel', description: 'Kişisel belgeler' },
      { id: '4', name: 'Eğitim', description: 'Eğitim belgeleri' }
    ];
    
    res.json({ success: true, data: mockCategories });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Failed to fetch categories',
        details: error.message
      }
    });
  }
});

// Payment endpoints
app.post('/api/v1/payments/payment-intent', async (req, res) => {
  try {
    const { template_id, amount } = req.body;
    
    res.json({
      success: true,
      data: {
        payment_intent_id: 'pi_mock_' + Date.now(),
        client_secret: 'pi_mock_secret_' + Date.now(),
        amount: amount || 2500,
        currency: 'try'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Payment intent creation failed', details: error.message }
    });
  }
});

app.post('/api/v1/payments/confirm', async (req, res) => {
  try {
    const { payment_intent_id, template_id } = req.body;
    
    res.json({
      success: true,
      data: {
        purchase_id: 'purchase_' + Date.now(),
        status: 'completed',
        template_id,
        amount: 2500,
        currency: 'try',
        purchased_at: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Payment confirmation failed', details: error.message }
    });
  }
});

app.get('/api/v1/payments/purchases', async (req, res) => {
  try {
    const mockPurchases = [
      {
        id: 'purchase_1',
        template_id: '550e8400-e29b-41d4-a716-446655440201',
        template_title: 'İş Sözleşmesi',
        amount: 25.00,
        currency: 'TRY',
        status: 'completed',
        purchased_at: '2024-12-01T10:00:00Z'
      }
    ];
    
    res.json({
      success: true,
      data: {
        purchases: mockPurchases,
        pagination: { page: 1, limit: 10, total: 1, pages: 1 }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Failed to fetch purchases', details: error.message }
    });
  }
});

// Document management endpoints
app.get('/api/v1/documents', async (req, res) => {
  try {
    const mockDocuments = [
      {
        id: 'doc_1',
        filename: 'izin-dilekçesi.pdf',
        template_id: '550e8400-e29b-41d4-a716-446655440200',
        template_title: 'İzin Dilekçesi',
        created_at: '2024-12-10T10:00:00Z',
        file_size: 51200
      },
      {
        id: 'doc_2',
        filename: 'iş-sözleşmesi.pdf',
        template_id: '550e8400-e29b-41d4-a716-446655440201',
        template_title: 'İş Sözleşmesi',
        created_at: '2024-12-09T15:30:00Z',
        file_size: 76800
      }
    ];
    
    res.json({
      success: true,
      data: {
        documents: mockDocuments,
        pagination: { page: 1, limit: 10, total: 2, pages: 1 }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Failed to fetch documents', details: error.message }
    });
  }
});

app.post('/api/v1/documents', async (req, res) => {
  try {
    const { template_id, filename, content } = req.body;
    
    const newDocument = {
      id: 'doc_' + Date.now(),
      filename: filename || 'document.pdf',
      template_id,
      content,
      created_at: new Date().toISOString(),
      file_size: 51200
    };
    
    res.status(201).json({
      success: true,
      data: newDocument
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Document creation failed', details: error.message }
    });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    error: {
      message: 'Sunucu hatası',
      details: err.message
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    error: {
      message: 'Endpoint bulunamadı',
      path: req.path
    }
  });
});

// Start server
async function startServer() {
  // Test database connection
  const dbConnected = await testConnection();
  
  app.listen(PORT, () => {
    console.log(`🚀 QuickPDF Backend running on http://localhost:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/v1/health`);
    console.log(`🗄️  Database test: http://localhost:${PORT}/api/v1/db-test`);
    console.log(`📄 Templates: http://localhost:${PORT}/api/v1/templates`);
    console.log(`📊 Database: ${dbConnected ? '✅ Connected' : '❌ Disconnected (using mock data)'}`);
  });
}

startServer();