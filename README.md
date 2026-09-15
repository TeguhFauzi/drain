# DrianStore - Platform Top-Up Game (Flutter + Prisma + Neon DB)

Aplikasi Web & Android E-Commerce Top-Up Game seperti [drianstore.com](https://www.drianstore.com/id-id) dibangun menggunakan **Flutter** (Web & Android), **Prisma ORM** + **Neon DB PostgreSQL**, dan **GitHub Actions** untuk CI/CD otomatis.

---

## ⚡ Fitur Utama

- 🎮 **Katalog Game Populer**: Mobile Legends, Free Fire, Genshin Impact, PUBG Mobile, Honkai: Star Rail, Valorant.
- 💎 **Voucher & Diamond**: Berbagai pilihan paket nominal top-up dengan harga terupdate.
- 💳 **Metode Pembayaran**: QRIS, Bank Transfer (BCA/Mandiri/BNI), E-Wallet (Gopay/OVO/Dana).
- 🚀 **Pengiriman Otomatis**: Simulasi callback webhook pembayaran & update status realtime.
- 🔐 **Autentikasi & Akun**: Register, Login dengan JWT, dan Riwayat Transaksi per pengguna.
- 🛡️ **Admin Dashboard**: Statistik total pendapatan, total user, kelola transaksi (konfirmasi/batal).
- 📱 **Multiplatform**: Web (Responsive Desktop & Mobile) dan APK Android Native.

---

## 📁 Struktur Project

```text
drians/
├── api/                          # Vercel Serverless API Functions
│   ├── auth/                     # Register, Login, Profile
│   ├── games/                    # List Games, Detail Game + Products
│   ├── transactions/             # Checkout, Detail, Callback Webhook
│   ├── admin/                    # Dashboard Stats, Transaction Management
│   └── _lib/                     # Prisma singleton, JWT Auth, Response helpers
├── prisma/
│   ├── schema.prisma             # PostgreSQL Database Schema
│   └── seed.js                   # Seed data game & produk
├── frontend/                     # Flutter App (Web + Android)
│   ├── lib/
│   │   ├── main.dart             # Entry point
│   │   ├── app.dart              # App Theme & Routing
│   │   ├── core/                 # Colors, Constants, Models, ApiService, Widgets
│   │   └── features/             # Home, Game Detail, Checkout, Auth, Admin
│   ├── web/                      # HTML5 template & SEO meta
│   └── android/                  # Native Android configuration
├── .github/workflows/
│   ├── deploy.yml                # CI/CD: Build Web & API -> Vercel
│   └── build-android.yml         # CI/CD: Build APK -> GitHub Releases
├── package.json                  # Node.js dependencies
├── vercel.json                   # Vercel unified routing config
└── .env                          # Environment variables
```

---

## 🛠️ Cara Menjalankan Secara Lokal (Development)

### 1. Prasyarat
- Node.js >= 18.x
- Flutter SDK >= 3.19.x
- Database Neon DB PostgreSQL

### 2. Setup Environment Variable
Pastikan file `.env` di folder utama berisi:
```env
DATABASE_URL="postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
JWT_SECRET="netprovider_super_secret_key_2026"
```

### 3. Migrasi Database & Seed Data
```bash
npm install
npx prisma db push
npx prisma db seed
```

### 4. Menjalankan Backend API & Serverless Local (Vercel CLI)
```bash
npx vercel dev
```

### 5. Menjalankan Flutter Frontend (Web)
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 🚀 CI/CD & Deployment Guide

### GitHub Secrets Setup
Tambahkan secret berikut di Repository GitHub Anda (`Settings -> Secrets and variables -> Actions`):

| Secret Name | Deskripsi |
|---|---|
| `DATABASE_URL` | Neon DB Connection String |
| `JWT_SECRET` | Secret key JWT Token |
| `VERCEL_TOKEN` | Token API Vercel |
| `VERCEL_ORG_ID` | Org ID Vercel |
| `VERCEL_PROJECT_ID` | Project ID Vercel |

### Alur Deployment Automatis
1. **Push ke `main`**: Workflow `.github/workflows/deploy.yml` akan berjalan otomatis:
   - Meng-compile Flutter Web ke folder `public/`
   - Meng-generate Prisma Client
   - Mung-deploy Web + Serverless API Functions sekaligus ke **Vercel**
2. **Push Tag `v*` (misal `v1.0.0`)**: Workflow `.github/workflows/build-android.yml` akan berjalan:
   - Mem-build file `.apk` Android Release
   - Mengunggah APK ke **GitHub Releases** secara otomatis
