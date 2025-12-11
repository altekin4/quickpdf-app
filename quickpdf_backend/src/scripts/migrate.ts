#!/usr/bin/env ts-node

import dotenv from 'dotenv';
import { migrationRunner } from '@/utils/migrationRunner';
import { testConnection, closePool } from '@/config/database';
import { logger } from '@/utils/logger';

// Load environment variables
dotenv.config();

async function main() {
  const command = process.argv[2];
  
  try {
    // Test database connection
    const connected = await testConnection();
    if (!connected) {
      logger.error('Cannot connect to database. Please check your configuration.');
      process.exit(1);
    }
    
    switch (command) {
      case 'up':
        await migrationRunner.runMigrations();
        break;
        
      case 'down':
        await migrationRunner.rollbackLastMigration();
        break;
        
      case 'status':
        await migrationRunner.getMigrationStatus();
        break;
        
      default:
        logger.info('Usage: npm run migrate [up|down|status]');
        logger.info('  up     - Run pending migrations');
        logger.info('  down   - Rollback last migration');
        logger.info('  status - Show migration status');
        break;
    }
  } catch (error) {
    logger.error('Migration script failed:', error);
    process.exit(1);
  } finally {
    await closePool();
  }
}

main();