const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'quickpdf',
  user: process.env.DB_USER || 'quickpdf',
  password: process.env.DB_PASSWORD || 'quickpdf_secure_password_2024',
  ssl: false,
});

async function checkDatabase() {
  try {
    const client = await pool.connect();
    
    // Check if tables exist
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    
    console.log('📋 Existing tables:');
    tablesResult.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
    // Check if we have any templates
    try {
      const templatesResult = await client.query('SELECT COUNT(*) as count FROM templates');
      console.log(`\n📄 Templates in database: ${templatesResult.rows[0].count}`);
    } catch (error) {
      console.log('\n❌ Templates table not accessible:', error.message);
    }
    
    // Check if we have any categories
    try {
      const categoriesResult = await client.query('SELECT COUNT(*) as count FROM categories');
      console.log(`📂 Categories in database: ${categoriesResult.rows[0].count}`);
    } catch (error) {
      console.log('❌ Categories table not accessible:', error.message);
    }
    
    client.release();
  } catch (error) {
    console.error('❌ Database check failed:', error.message);
  } finally {
    await pool.end();
  }
}

checkDatabase();