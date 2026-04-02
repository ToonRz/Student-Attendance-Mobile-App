# 📚 Student Attendance Mobile App

A mobile application for student attendance tracking using **QR Code + GPS Location Verification** to prevent cheating.

## ✨ Features

### 👨‍🏫 Teacher
- Create and manage classes
- Open attendance sessions with QR codes
- QR codes rotate every 30 seconds (anti-cheat)
- View real-time attendance reports
- See who's present and absent with statistics

### 👨‍🎓 Student
- Join classes using class codes
- Scan QR code to check in
- GPS location verified (must be within 50m of teacher)
- View personal attendance history

### 🔒 Security
- JWT authentication
- Password hashing (bcrypt)
- QR tokens expire and rotate every 30s
- Location verification (≤50m radius)
- No duplicate check-ins
- Server-side time validation

## 🏗️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | PostgreSQL + Prisma ORM |
| Auth | JWT |
| Notifications | Firebase Cloud Messaging |

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- Flutter 3.x
- Android Studio / Xcode

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database URL and secrets
npx prisma generate
npx prisma db push
npm run dev
```

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

## 📡 API Documentation

See [backend/README.md](backend/README.md) for full API documentation.

## 📄 License

MIT
