import fs from 'fs';
import path from 'path';
import { pool } from '@/config/database';
import { logger } from '@/utils/logger';

interface Migration {
  id: number;
  filename: string;
  executed_at: Date;
}

export class MigrationRunner {
  private migrationsPath: string;

  constructor() {
    this.migrationsPath = path.join(__dirname, '../migrations');
  }

  async createMigrationsTable(): Promise<void> {
    const query = `
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT NOW()
      );
    `;
    
    try {
      await pool.query(query);
      logger.info('Migrations table created or already exists');
    } catch (error) {
      logger.error('Error creating migrations table:', error);
      throw error;
    }
  }

  async getExecutedMigrations(): Promise<Migration[]> {
    try {
      const result = await pool.query(
        'SELECT id, filename, executed_at FROM migrations ORDER BY id'
      );
      return result.rows;
    } catch (error) {
      logger.error('Error getting executed migrations:', error);
      throw error;
    }
  }

  async getMigrationFiles(): Promise<string[]> {
    try {
      const files = fs.readdirSync(this.migrationsPath);
      return files
        .filter(file => file.endsWith('.sql'))
        .sort();
    } catch (error) {
      logger.error('Error reading migration files:', error);
      throw error;
    }
  }

  async executeMigration(filename: string): Promise<void> {
    const filePath = path.join(this.migrationsPath, filename);
    
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
        logger.info(`✅ Migration executed successfully: ${filename}`);
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      logger.error(`❌ Error executing migration ${filename}:`, error);
      throw error;
    }
  }

  async runMigrations(): Promise<void> {
    try {
      logger.info('🚀 Starting database migrations...');
      
      // Create migrations table if it doesn't exist
      await this.createMigrationsTable();
      
      // Get executed migrations
      const executedMigrations = await this.getExecutedMigrations();
      const executedFilenames = executedMigrations.map(m => m.filename);
      
      // Get all migration files
      const migrationFiles = await this.getMigrationFiles();
      
      // Find pending migrations
      const pendingMigrations = migrationFiles.filter(
        filename => !executedFilenames.includes(filename)
      );
      
      if (pendingMigrations.length === 0) {
        logger.info('✅ No pending migrations found');
        return;
      }
      
      logger.info(`📋 Found ${pendingMigrations.length} pending migrations`);
      
      // Execute pending migrations
      for (const filename of pendingMigrations) {
        await this.executeMigration(filename);
      }
      
      logger.info('🎉 All migrations completed successfully');
    } catch (error) {
      logger.error('💥 Migration failed:', error);
      throw error;
    }
  }

  async rollbackLastMigration(): Promise<void> {
    try {
      const executedMigrations = await this.getExecutedMigrations();
      
      if (executedMigrations.length === 0) {
        logger.info('No migrations to rollback');
        return;
      }
      
      const lastMigration = executedMigrations[executedMigrations.length - 1];
      
      // Remove from migrations table
      await pool.query(
        'DELETE FROM migrations WHERE filename = $1',
        [lastMigration.filename]
      );
      
      logger.info(`⏪ Rolled back migration: ${lastMigration.filename}`);
      logger.warn('Note: This only removes the migration record. Manual cleanup may be required.');
    } catch (error) {
      logger.error('Error rolling back migration:', error);
      throw error;
    }
  }

  async getMigrationStatus(): Promise<void> {
    try {
      const executedMigrations = await this.getExecutedMigrations();
      const migrationFiles = await this.getMigrationFiles();
      
      logger.info('📊 Migration Status:');
      logger.info(`Total migration files: ${migrationFiles.length}`);
      logger.info(`Executed migrations: ${executedMigrations.length}`);
      
      if (executedMigrations.length > 0) {
        logger.info('Executed migrations:');
        executedMigrations.forEach(migration => {
          logger.info(`  ✅ ${migration.filename} (${migration.executed_at})`);
        });
      }
      
      const pendingMigrations = migrationFiles.filter(
        filename => !executedMigrations.map(m => m.filename).includes(filename)
      );
      
      if (pendingMigrations.length > 0) {
        logger.info('Pending migrations:');
        pendingMigrations.forEach(filename => {
          logger.info(`  ⏳ ${filename}`);
        });
      }
    } catch (error) {
      logger.error('Error getting migration status:', error);
      throw error;
    }
  }
}

export const migrationRunner = new MigrationRunner();