const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'quickpdf_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:8080', 'http://localhost:3000']
}));
app.use(express.json());

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW() as current_time, COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = \'public\'');
    client.release();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        current_time: result.rows[0].current_time,
        tables_count: result.rows[0].table_count
      },
      server: {
        port: port,
        node_version: process.version,
        uptime: process.uptime()
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      database: {
        connected: false
      }
    });
  }
});

// API info endpoint
app.get('/api/v1/info', (req, res) => {
  res.json({
    name: 'QuickPDF Backend API',
    version: '1.0.0',
    description: 'PDF generation and template marketplace backend',
    endpoints: {
      health: '/health',
      info: '/api/v1/info',
      database_test: '/api/v1/test/database'
    }
  });
});

// Database test endpoint
app.get('/api/v1/test/database', async (req, res) => {
  try {
    const client = await pool.connect();
    
    // Test basic queries
    const versionResult = await client.query('SELECT version()');
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    // Test a simple insert/select (users table)
    const testUserResult = await client.query(`
      SELECT COUNT(*) as user_count FROM users
    `);
    
    client.release();
    
    res.json({
      status: 'success',
      database: {
        version: versionResult.rows[0].version,
        tables: tablesResult.rows.map(row => row.table_name),
        user_count: testUserResult.rows[0].user_count
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: error.code
    });
  }
});

// Start server
app.listen(port, () => {
  console.log(`🚀 QuickPDF Backend Server started on port ${port}`);
  console.log(`📋 Health check: http://localhost:${port}/health`);
  console.log(`📋 API info: http://localhost:${port}/api/v1/info`);
  console.log(`📋 Database test: http://localhost:${port}/api/v1/test/database`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    process.exit(0);
  });
});
// Tags endpoints
app.get('/api/v1/tags', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query(`
      SELECT id, name, slug, usage_count, created_at 
      FROM tags 
      ORDER BY usage_count DESC, name ASC
    `);
    client.release();
    
    res.json({
      status: 'success',
      data: {
        tags: result.rows
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Get template tags
app.get('/api/v1/templates/:templateId/tags', async (req, res) => {
  try {
    const { templateId } = req.params;
    const client = await pool.connect();
    
    const result = await client.query(`
      SELECT t.id, t.name, t.slug, t.usage_count, t.created_at
      FROM tags t
      JOIN template_tags tt ON t.id = tt.tag_id
      WHERE tt.template_id = $1
      ORDER BY t.name ASC
    `, [templateId]);
    
    client.release();
    
    res.json({
      status: 'success',
      data: {
        tags: result.rows
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Email verification endpoints
app.post('/api/v1/auth/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;
    
    // In real app, this would send email
    console.log(`Verification email would be sent to: ${email}`);
    
    res.json({
      status: 'success',
      message: 'Verification email sent'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

app.get('/api/v1/auth/verify-email/:token', async (req, res) => {
  try {
    const { token } = req.params;
    
    // In real app, this would verify token and update user
    console.log(`Email verification token: ${token}`);
    
    res.json({
      status: 'success',
      message: 'Email verified successfully'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Password reset endpoints
app.post('/api/v1/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    // In real app, this would send reset email
    console.log(`Password reset email would be sent to: ${email}`);
    
    res.json({
      status: 'success',
      message: 'Password reset email sent'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

app.post('/api/v1/auth/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;
    
    // In real app, this would verify token and update password
    console.log(`Password reset with token: ${token}`);
    
    res.json({
      status: 'success',
      message: 'Password reset successfully'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});