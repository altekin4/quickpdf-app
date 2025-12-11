import { logger } from '@/utils/logger';

export interface SecurityEvent {
  type: 'failed_login' | 'suspicious_activity' | 'rate_limit_exceeded' | 'csrf_violation' | 'injection_attempt';
  severity: 'low' | 'medium' | 'high' | 'critical';
  ip: string;
  userAgent?: string;
  userId?: string;
  details: Record<string, any>;
  timestamp: Date;
}

export interface SecurityMetrics {
  failedLogins: number;
  suspiciousRequests: number;
  rateLimitViolations: number;
  csrfViolations: number;
  injectionAttempts: number;
  lastReset: Date;
}

export class SecurityMonitoringService {
  private static events: SecurityEvent[] = [];
  private static metrics: SecurityMetrics = {
    failedLogins: 0,
    suspiciousRequests: 0,
    rateLimitViolations: 0,
    csrfViolations: 0,
    injectionAttempts: 0,
    lastReset: new Date(),
  };

  private static readonly MAX_EVENTS = 10000;
  private static readonly ALERT_THRESHOLDS = {
    failed_login: 10, // per IP per hour
    suspicious_activity: 5, // per IP per hour
    rate_limit_exceeded: 3, // per IP per hour
    csrf_violation: 5, // per IP per hour
    injection_attempt: 1, // per IP per hour
  };

  /**
   * Records a security event
   */
  static recordEvent(event: Omit<SecurityEvent, 'timestamp'>): void {
    const securityEvent: SecurityEvent = {
      ...event,
      timestamp: new Date(),
    };

    this.events.push(securityEvent);
    this.updateMetrics(event.type);

    // Log the event
    logger.warn('Security event recorded', {
      type: event.type,
      severity: event.severity,
      ip: event.ip,
      userId: event.userId,
      details: event.details,
    });

    // Check for alerts
    this.checkAlerts(event);

    // Cleanup old events
    if (this.events.length > this.MAX_EVENTS) {
      this.events = this.events.slice(-this.MAX_EVENTS);
    }
  }

  /**
   * Updates security metrics
   */
  private static updateMetrics(eventType: SecurityEvent['type']): void {
    switch (eventType) {
      case 'failed_login':
        this.metrics.failedLogins++;
        break;
      case 'suspicious_activity':
        this.metrics.suspiciousRequests++;
        break;
      case 'rate_limit_exceeded':
        this.metrics.rateLimitViolations++;
        break;
      case 'csrf_violation':
        this.metrics.csrfViolations++;
        break;
      case 'injection_attempt':
        this.metrics.injectionAttempts++;
        break;
    }
  }

  /**
   * Checks if alerts should be triggered
   */
  private static checkAlerts(event: SecurityEvent): void {
    const oneHourAgo = new Date(Date.now() - 3600000);
    const recentEvents = this.events.filter(
      e => e.type === event.type && 
           e.ip === event.ip && 
           e.timestamp > oneHourAgo
    );

    const threshold = this.ALERT_THRESHOLDS[event.type];
    
    if (recentEvents.length >= threshold) {
      this.triggerAlert(event, recentEvents.length);
    }
  }

  /**
   * Triggers a security alert
   */
  private static triggerAlert(event: SecurityEvent, count: number): void {
    logger.error('SECURITY ALERT TRIGGERED', {
      type: event.type,
      ip: event.ip,
      count,
      threshold: this.ALERT_THRESHOLDS[event.type],
      severity: 'CRITICAL',
      timestamp: new Date().toISOString(),
    });

    // In a production environment, you would:
    // - Send notifications to security team
    // - Trigger automated responses (IP blocking, etc.)
    // - Update security dashboards
    // - Integrate with SIEM systems
  }

  /**
   * Gets security events for a specific IP
   */
  static getEventsForIP(ip: string, hours: number = 24): SecurityEvent[] {
    const cutoff = new Date(Date.now() - hours * 3600000);
    return this.events.filter(
      event => event.ip === ip && event.timestamp > cutoff
    );
  }

  /**
   * Gets security events by type
   */
  static getEventsByType(type: SecurityEvent['type'], hours: number = 24): SecurityEvent[] {
    const cutoff = new Date(Date.now() - hours * 3600000);
    return this.events.filter(
      event => event.type === type && event.timestamp > cutoff
    );
  }

  /**
   * Gets current security metrics
   */
  static getMetrics(): SecurityMetrics {
    return { ...this.metrics };
  }

  /**
   * Resets security metrics
   */
  static resetMetrics(): void {
    this.metrics = {
      failedLogins: 0,
      suspiciousRequests: 0,
      rateLimitViolations: 0,
      csrfViolations: 0,
      injectionAttempts: 0,
      lastReset: new Date(),
    };
  }

  /**
   * Gets security summary for the last 24 hours
   */
  static getSecuritySummary(): {
    totalEvents: number;
    eventsByType: Record<string, number>;
    topIPs: Array<{ ip: string; count: number }>;
    criticalEvents: SecurityEvent[];
  } {
    const last24Hours = new Date(Date.now() - 24 * 3600000);
    const recentEvents = this.events.filter(event => event.timestamp > last24Hours);

    const eventsByType: Record<string, number> = {};
    const ipCounts: Record<string, number> = {};

    recentEvents.forEach(event => {
      eventsByType[event.type] = (eventsByType[event.type] || 0) + 1;
      ipCounts[event.ip] = (ipCounts[event.ip] || 0) + 1;
    });

    const topIPs = Object.entries(ipCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([ip, count]) => ({ ip, count }));

    const criticalEvents = recentEvents.filter(
      event => event.severity === 'critical'
    );

    return {
      totalEvents: recentEvents.length,
      eventsByType,
      topIPs,
      criticalEvents,
    };
  }

  /**
   * Checks if an IP should be blocked based on security events
   */
  static shouldBlockIP(ip: string): boolean {
    const recentEvents = this.getEventsForIP(ip, 1); // Last hour
    
    // Block if too many critical events
    const criticalEvents = recentEvents.filter(e => e.severity === 'critical');
    if (criticalEvents.length >= 3) {
      return true;
    }

    // Block if too many injection attempts
    const injectionAttempts = recentEvents.filter(e => e.type === 'injection_attempt');
    if (injectionAttempts.length >= 1) {
      return true;
    }

    // Block if too many failed logins
    const failedLogins = recentEvents.filter(e => e.type === 'failed_login');
    if (failedLogins.length >= 20) {
      return true;
    }

    return false;
  }

  /**
   * Cleans up old events (older than 7 days)
   */
  static cleanupOldEvents(): void {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 3600000);
    const initialCount = this.events.length;
    
    this.events = this.events.filter(event => event.timestamp > sevenDaysAgo);
    
    const removedCount = initialCount - this.events.length;
    if (removedCount > 0) {
      logger.info(`Cleaned up ${removedCount} old security events`);
    }
  }
}

// Cleanup old events daily
setInterval(() => {
  SecurityMonitoringService.cleanupOldEvents();
}, 24 * 60 * 60 * 1000); // Every 24 hours

export default SecurityMonitoringService;