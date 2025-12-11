// Simple database connection test
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'quickpdf_db',
  user: 'postgres',
  password: 'postgres',
});

async function testConnection() {
  try {
    console.log('🔄 Testing database connection...');
    
    const client = await pool.connect();
    const result = await client.query('SELECT NOW() as current_time, version() as pg_version');
    
    console.log('✅ Database connection successful!');
    console.log('📅 Current time:', result.rows[0].current_time);
    console.log('🐘 PostgreSQL version:', result.rows[0].pg_version.split(' ')[0] + ' ' + result.rows[0].pg_version.split(' ')[1]);
    
    client.release();
    await pool.end();
    
    console.log('🎉 Database test completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection failed:');
    console.error('Error:', error.message);
    console.error('');
    console.error('💡 Troubleshooting:');
    console.error('1. Make sure PostgreSQL is installed and running');
    console.error('2. Check if database "quickpdf_db" exists');
    console.error('3. Verify username/password: postgres/postgres');
    console.error('4. Ensure PostgreSQL is listening on port 5432');
    console.error('');
    console.error('🔧 Quick fixes:');
    console.error('- Create database: createdb -U postgres quickpdf_db');
    console.error('- Start service: net start postgresql-x64-17');
    console.error('- Check service: Get-Service -Name postgresql*');
    
    process.exit(1);
  }
}

testConnection();