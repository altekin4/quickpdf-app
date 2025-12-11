const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'quickpdf',
  user: process.env.DB_USER || 'quickpdf',
  password: process.env.DB_PASSWORD || 'quickpdf_secure_password_2024',
  ssl: false,
});

async function createMigrationsTable() {
  const query = `
    CREATE TABLE IF NOT EXISTS migrations (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) UNIQUE NOT NULL,
      executed_at TIMESTAMP DEFAULT NOW()
    );
  `;
  
  try {
    await pool.query(query);
    console.log('✅ Migrations table created or already exists');
  } catch (error) {
    console.error('❌ Error creating migrations table:', error.message);
    throw error;
  }
}

async function getExecutedMigrations() {
  try {
    const result = await pool.query(
      'SELECT filename FROM migrations ORDER BY id'
    );
    return result.rows.map(row => row.filename);
  } catch (error) {
    console.error('❌ Error getting executed migrations:', error.message);
    return [];
  }
}

async function executeMigration(filename) {
  const filePath = path.join(__dirname, 'src/migrations', filename);
  
  try {
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // Start transaction
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Execute migration SQL
      await client.query(sql);
      
      // Record migration as executed
      await client.query(
        'INSERT INTO migrations (filename) VALUES ($1)',
        [filename]
      );
      
      await client.query('COMMIT');
      console.log(`✅ Migration executed successfully: ${filename}`);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error(`❌ Error executing migration ${filename}:`, error.message);
    throw error;
  }
}

async function runMigrations() {
  try {
    console.log('🚀 Starting database migrations...');
    
    // Test connection
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    console.log('✅ Database connected:', result.rows[0].now);
    
    // Create migrations table
    await createMigrationsTable();
    
    // Get executed migrations
    const executedMigrations = await getExecutedMigrations();
    
    // Get all migration files
    const migrationsPath = path.join(__dirname, 'src/migrations');
    const migrationFiles = fs.readdirSync(migrationsPath)
      .filter(file => file.endsWith('.sql'))
      .sort();
    
    console.log(`📋 Found ${migrationFiles.length} migration files`);
    console.log(`📋 Already executed: ${executedMigrations.length} migrations`);
    
    // Find pending migrations
    const pendingMigrations = migrationFiles.filter(
      filename => !executedMigrations.includes(filename)
    );
    
    if (pendingMigrations.length === 0) {
      console.log('✅ No pending migrations found');
      return;
    }
    
    console.log(`📋 Found ${pendingMigrations.length} pending migrations:`);
    pendingMigrations.forEach(filename => {
      console.log(`  - ${filename}`);
    });
    
    // Execute pending migrations
    for (const filename of pendingMigrations) {
      await executeMigration(filename);
    }
    
    console.log('🎉 All migrations completed successfully');
  } catch (error) {
    console.error('💥 Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run migrations
runMigrations();