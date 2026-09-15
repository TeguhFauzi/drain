const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
require('dotenv').config();

function createPrismaClient() {
  try {
    const { Pool, neonConfig } = require('@neondatabase/serverless');
    const { PrismaNeon } = require('@prisma/adapter-neon');
    const ws = require('ws');
    neonConfig.webSocketConstructor = ws;
    const connectionString = process.env.DIRECT_URL || process.env.DATABASE_URL;
    if (connectionString) {
      const pool = new Pool({ connectionString });
      const adapter = new PrismaNeon(pool);
      return new PrismaClient({ adapter });
    }
  } catch (err) {
    // Fallback to standard PrismaClient
  }
  return new PrismaClient();
}

const prisma = createPrismaClient();

async function seed() {
  console.log('🌱 Seeding database...\n');

  // 1. Create admin user
  console.log('👤 Creating admin user...');
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@drianstore.com';
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
  const adminPhone = process.env.ADMIN_PHONE || '081234567890';

  const adminPasswordHash = await bcrypt.hash(adminPassword, 10);
  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      passwordHash: adminPasswordHash,
      name: 'Admin DrianStore',
      phone: adminPhone,
      role: 'admin',
    },
  });
  console.log('  ✅ Admin created successfully!');
  console.log(`  🔑 Email    : ${adminEmail}`);
  console.log(`  🔑 Password : ${adminPassword}\n`);

  // 2. Create games
  console.log('🎮 Creating games...');
  const gamesData = [
    {
      name: 'Mobile Legends: Bang Bang',
      slug: 'mobile-legends',
      description: 'Top up Diamond Mobile Legends: Bang Bang dengan harga termurah dan proses tercepat.',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1200&q=80',
      publisher: 'Moonton',
      inputLabel: 'User ID',
      inputPlaceholder: 'Masukkan User ID',
      inputLabel2: 'Zone ID',
      inputPlaceholder2: 'Masukkan Zone ID',
      sortOrder: 1,
      products: [
        { name: '86 Diamonds', price: 20000, sellPrice: 22000, sort: 1 },
        { name: '172 Diamonds', price: 38000, sellPrice: 42000, sort: 2 },
        { name: '257 Diamonds', price: 57000, sellPrice: 62000, sort: 3 },
        { name: '344 Diamonds', price: 75000, sellPrice: 82000, sort: 4 },
        { name: '429 Diamonds', price: 93000, sellPrice: 100000, sort: 5 },
        { name: '514 Diamonds', price: 111000, sellPrice: 120000, sort: 6 },
        { name: '600 Diamonds', price: 129000, sellPrice: 140000, sort: 7 },
        { name: '1050 Diamonds', price: 224000, sellPrice: 245000, sort: 8 },
        { name: '2195 Diamonds', price: 448000, sellPrice: 490000, sort: 9 },
        { name: 'Twilight Pass', price: 120000, sellPrice: 135000, category: 'pass', sort: 10 },
      ],
    },
    {
      name: 'Free Fire',
      slug: 'free-fire',
      description: 'Top up Diamond Free Fire dengan harga murah dan proses instan.',
      imageUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=1200&q=80',
      publisher: 'Garena',
      inputLabel: 'Player ID',
      inputPlaceholder: 'Masukkan Player ID',
      sortOrder: 2,
      products: [
        { name: '70 Diamonds', price: 10000, sellPrice: 12000, sort: 1 },
        { name: '140 Diamonds', price: 20000, sellPrice: 23000, sort: 2 },
        { name: '355 Diamonds', price: 50000, sellPrice: 56000, sort: 3 },
        { name: '720 Diamonds', price: 100000, sellPrice: 112000, sort: 4 },
        { name: '1450 Diamonds', price: 200000, sellPrice: 224000, sort: 5 },
        { name: 'Weekly Membership', price: 25000, sellPrice: 29000, category: 'membership', sort: 6 },
        { name: 'Monthly Membership', price: 80000, sellPrice: 90000, category: 'membership', sort: 7 },
      ],
    },
    {
      name: 'Genshin Impact',
      slug: 'genshin-impact',
      description: 'Top up Genesis Crystal Genshin Impact. Masukkan UID dan pilih server.',
      imageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=1200&q=80',
      publisher: 'HoYoverse',
      inputLabel: 'UID',
      inputPlaceholder: 'Masukkan UID',
      inputLabel2: 'Server',
      inputPlaceholder2: 'Pilih Server (Asia/America/Europe)',
      sortOrder: 3,
      products: [
        { name: '60 Genesis Crystals', price: 16000, sellPrice: 18000, sort: 1 },
        { name: '330 Genesis Crystals', price: 79000, sellPrice: 86000, sort: 2 },
        { name: '1090 Genesis Crystals', price: 249000, sellPrice: 270000, sort: 3 },
        { name: '2240 Genesis Crystals', price: 479000, sellPrice: 520000, sort: 4 },
        { name: '3880 Genesis Crystals', price: 799000, sellPrice: 870000, sort: 5 },
        { name: '8080 Genesis Crystals', price: 1599000, sellPrice: 1740000, sort: 6 },
        { name: 'Blessing of the Welkin Moon', price: 75000, sellPrice: 82000, category: 'pass', sort: 7 },
      ],
    },
    {
      name: 'PUBG Mobile',
      slug: 'pubg-mobile',
      description: 'Top up UC PUBG Mobile murah dan cepat.',
      imageUrl: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=1200&q=80',
      publisher: 'Krafton',
      inputLabel: 'Player ID',
      inputPlaceholder: 'Masukkan Player ID',
      sortOrder: 4,
      products: [
        { name: '60 UC', price: 15000, sellPrice: 17000, sort: 1 },
        { name: '325 UC', price: 75000, sellPrice: 82000, sort: 2 },
        { name: '660 UC', price: 149000, sellPrice: 165000, sort: 3 },
        { name: '1800 UC', price: 375000, sellPrice: 410000, sort: 4 },
        { name: '3850 UC', price: 749000, sellPrice: 820000, sort: 5 },
        { name: 'Royale Pass', price: 150000, sellPrice: 168000, category: 'pass', sort: 6 },
      ],
    },
    {
      name: 'Honkai: Star Rail',
      slug: 'honkai-star-rail',
      description: 'Top up Oneiric Shard Honkai: Star Rail.',
      imageUrl: 'https://images.unsplash.com/photo-1579373903781-fd5c0c30c4cd?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1579373903781-fd5c0c30c4cd?w=1200&q=80',
      publisher: 'HoYoverse',
      inputLabel: 'UID',
      inputPlaceholder: 'Masukkan UID',
      inputLabel2: 'Server',
      inputPlaceholder2: 'Pilih Server',
      sortOrder: 5,
      products: [
        { name: '60 Oneiric Shards', price: 16000, sellPrice: 18000, sort: 1 },
        { name: '330 Oneiric Shards', price: 79000, sellPrice: 86000, sort: 2 },
        { name: '1090 Oneiric Shards', price: 249000, sellPrice: 270000, sort: 3 },
        { name: '2240 Oneiric Shards', price: 479000, sellPrice: 520000, sort: 4 },
        { name: '3880 Oneiric Shards', price: 799000, sellPrice: 870000, sort: 5 },
        { name: '8080 Oneiric Shards', price: 1599000, sellPrice: 1740000, sort: 6 },
        { name: 'Express Supply Pass', price: 75000, sellPrice: 82000, category: 'pass', sort: 7 },
      ],
    },
    {
      name: 'Valorant',
      slug: 'valorant',
      description: 'Top up Valorant Points (VP) dengan harga terbaik.',
      imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1200&q=80',
      publisher: 'Riot Games',
      inputLabel: 'Riot ID',
      inputPlaceholder: 'Masukkan Riot ID (Name#TAG)',
      sortOrder: 6,
      products: [
        { name: '125 VP', price: 15000, sellPrice: 17000, sort: 1 },
        { name: '420 VP', price: 50000, sellPrice: 55000, sort: 2 },
        { name: '700 VP', price: 80000, sellPrice: 88000, sort: 3 },
        { name: '1375 VP', price: 150000, sellPrice: 165000, sort: 4 },
        { name: '2400 VP', price: 250000, sellPrice: 275000, sort: 5 },
        { name: '4000 VP', price: 400000, sellPrice: 440000, sort: 6 },
        { name: '8150 VP', price: 800000, sellPrice: 880000, sort: 7 },
      ],
    },
  ];

  for (const gameData of gamesData) {
    const { products, ...gameInfo } = gameData;
    const game = await prisma.game.upsert({
      where: { slug: gameInfo.slug },
      update: gameInfo,
      create: gameInfo,
    });
    console.log(`  ✅ ${game.name}`);

    const existingProducts = await prisma.product.findMany({ where: { gameId: game.id } });
    for (const p of products) {
      const existing = existingProducts.find(ep => ep.name === p.name);
      if (existing) {
        await prisma.product.update({
          where: { id: existing.id },
          data: {
            price: p.price,
            sellPrice: p.sellPrice,
            providerCode: `${gameInfo.slug}-${p.sort}`,
            category: p.category || 'topup',
            sortOrder: p.sort,
          },
        });
      } else {
        await prisma.product.create({
          data: {
            gameId: game.id,
            name: p.name,
            price: p.price,
            sellPrice: p.sellPrice,
            providerCode: `${gameInfo.slug}-${p.sort}`,
            category: p.category || 'topup',
            sortOrder: p.sort,
          },
        });
      }
    }
    console.log(`    💎 ${products.length} products processed`);
  }

  // 3. Admin settings
  console.log('\n⚙️ Creating admin settings...');
  const settings = [
    { key: 'site_name', value: 'DrianStore', description: 'Nama website' },
    { key: 'site_description', value: 'Top-Up Game Termurah & Tercepat', description: 'Deskripsi website' },
    { key: 'whatsapp_number', value: '6281234567890', description: 'Nomor WhatsApp CS' },
    { key: 'payment_enabled', value: 'true', description: 'Enable/disable payment' },
  ];

  for (const s of settings) {
    await prisma.adminSetting.upsert({
      where: { key: s.key },
      update: { value: s.value },
      create: s,
    });
  }
  console.log('  ✅ Admin settings created');

  console.log('\n🎉 Seeding completed successfully!');
  console.log('----------------------------------------------------');
  console.log('🔐 CREDENTIALS ADMIN LOG IN:');
  console.log('   Email    : admin@drianstore.com');
  console.log('   Password : admin123');
  console.log('----------------------------------------------------\n');
}

seed()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
