#!/usr/bin/env ts-node

/**
 * Property-based test runner for QuickPDF backend
 * 
 * This script runs all property-based tests and provides detailed reporting.
 * It's designed to validate system properties and ensure correctness guarantees.
 */

import { execSync } from 'child_process';
import { logger } from '@/utils/logger';

interface TestResult {
  testSuite: string;
  passed: boolean;
  duration: number;
  details: string;
}

class PropertyTestRunner {
  private results: TestResult[] = [];

  async runAllPropertyTests(): Promise<void> {
    logger.info('🧪 Starting Property-Based Test Suite');
    logger.info('=====================================');

    const testSuites = [
      'rateLimiting.property.test.ts',
      'systemSetup.property.test.ts',
      'pdfGeneration.property.test.ts',
      'textFormatting.property.test.ts',
      'turkishSupport.property.test.ts',
    ];

    for (const testSuite of testSuites) {
      await this.runTestSuite(testSuite);
    }

    this.generateReport();
  }

  private async runTestSuite(testSuite: string): Promise<void> {
    logger.info(`\n📋 Running test suite: ${testSuite}`);
    
    const startTime = Date.now();
    let passed = false;
    let details = '';

    try {
      const output = execSync(
        `npx jest --testPathPattern=${testSuite} --verbose --no-coverage`,
        { 
          encoding: 'utf8',
          cwd: process.cwd(),
          timeout: 120000, // 2 minutes timeout
        }
      );
      
      passed = true;
      details = this.extractTestDetails(output);
      logger.info(`✅ ${testSuite} - PASSED`);
    } catch (error: any) {
      passed = false;
      details = error.stdout || error.message || 'Unknown error';
      logger.error(`❌ ${testSuite} - FAILED`);
      logger.error(details);
    }

    const duration = Date.now() - startTime;
    
    this.results.push({
      testSuite,
      passed,
      duration,
      details,
    });
  }

  private extractTestDetails(output: string): string {
    // Extract key information from Jest output
    const lines = output.split('\n');
    const relevantLines = lines.filter(line => 
      line.includes('PASS') || 
      line.includes('FAIL') || 
      line.includes('Tests:') ||
      line.includes('Time:') ||
      line.includes('property')
    );
    
    return relevantLines.join('\n');
  }

  private generateReport(): void {
    logger.info('\n📊 Property-Based Test Report');
    logger.info('==============================');

    const totalTests = this.results.length;
    const passedTests = this.results.filter(r => r.passed).length;
    const failedTests = totalTests - passedTests;
    const totalDuration = this.results.reduce((sum, r) => sum + r.duration, 0);

    logger.info(`\n📈 Summary:`);
    logger.info(`  Total Test Suites: ${totalTests}`);
    logger.info(`  Passed: ${passedTests}`);
    logger.info(`  Failed: ${failedTests}`);
    logger.info(`  Total Duration: ${totalDuration}ms`);
    logger.info(`  Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);

    logger.info(`\n📋 Detailed Results:`);
    this.results.forEach(result => {
      const status = result.passed ? '✅ PASS' : '❌ FAIL';
      logger.info(`  ${status} ${result.testSuite} (${result.duration}ms)`);
    });

    if (failedTests > 0) {
      logger.info(`\n🔍 Failed Test Details:`);
      this.results
        .filter(r => !r.passed)
        .forEach(result => {
          logger.info(`\n❌ ${result.testSuite}:`);
          logger.info(result.details);
        });
    }

    // Property-specific reporting
    logger.info(`\n🎯 Property Validation Status:`);
    logger.info(`  Property 1 (PDF Generation Performance): ${this.getPropertyStatus('pdfGeneration')}`);
    logger.info(`  Property 2 (Text Formatting Preservation): ${this.getPropertyStatus('textFormatting')}`);
    logger.info(`  Property 3 (Turkish Character Support): ${this.getPropertyStatus('turkishSupport')}`);
    logger.info(`  Property 18 (Rate Limiting): ${this.getPropertyStatus('rateLimiting')}`);
    logger.info(`  System Setup Properties: ${this.getPropertyStatus('systemSetup')}`);

    if (failedTests === 0) {
      logger.info(`\n🎉 All property-based tests passed!`);
      logger.info(`   System correctness properties are validated.`);
    } else {
      logger.error(`\n💥 ${failedTests} test suite(s) failed!`);
      logger.error(`   System correctness properties may be violated.`);
      process.exit(1);
    }
  }

  private getPropertyStatus(testType: string): string {
    const result = this.results.find(r => r.testSuite.includes(testType));
    return result ? (result.passed ? '✅ VALIDATED' : '❌ FAILED') : '⚠️ NOT FOUND';
  }
}

// Main execution
async function main() {
  try {
    const runner = new PropertyTestRunner();
    await runner.runAllPropertyTests();
  } catch (error) {
    logger.error('💥 Property test runner failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

export { PropertyTestRunner };