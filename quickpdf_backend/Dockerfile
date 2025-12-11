# QuickPDF Backend Dockerfile (Simple Server)

FROM node:18-alpine

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S quickpdf -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application files
COPY simple-server.js ./
COPY run-migrations.js ./
COPY check-db.js ./
COPY .env ./
COPY src/migrations ./src/migrations

# Create necessary directories
RUN mkdir -p uploads logs temp && \
    chown -R quickpdf:nodejs uploads logs temp

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Switch to non-root user
USER quickpdf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Start the application with dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "simple-server.js"]