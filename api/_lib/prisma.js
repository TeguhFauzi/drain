const { PrismaClient } = require('@prisma/client');

let prisma;

function createNeonPrismaClient() {
  try {
    const { Pool, neonConfig } = require('@neondatabase/serverless');
    const { PrismaNeon } = require('@prisma/adapter-neon');
    const ws = require('ws');
    neonConfig.webSocketConstructor = ws;

    const connectionString = process.env.DATABASE_URL;
    if (connectionString) {
      const pool = new Pool({ connectionString });
      const adapter = new PrismaNeon(pool);
      return new PrismaClient({ adapter });
    }
  } catch (err) {
    console.warn('Falling back to standard PrismaClient:', err.message);
  }
  return new PrismaClient();
}

if (process.env.NODE_ENV === 'production') {
  prisma = createNeonPrismaClient();
} else {
  if (!global.prisma) {
    global.prisma = createNeonPrismaClient();
  }
  prisma = global.prisma;
}

module.exports = prisma;
