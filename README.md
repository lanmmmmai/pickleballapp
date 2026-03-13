# 🏓 Pickleball App

A **full-stack Pickleball management application** including:

-   📱 **Flutter mobile app**
-   ⚙️ **Node.js + Express backend**
-   🖥 **React admin dashboard**

This system allows users to **book courts, join classes, watch training
videos, earn coins, redeem vouchers, and interact with the club
community.**

------------------------------------------------------------------------

# 📌 Getting Started

This repository contains **three main components**:

-   📱 **Flutter mobile app** for players\
-   ⚙️ **Node.js + Express backend** for APIs and database\
-   🖥 **React admin dashboard** for system management

If you are new to Flutter or this project, the following guide will help
you run the application locally.

------------------------------------------------------------------------

# 📂 Project Structure

``` text
pickleballapp
│
├── lib/                     # Flutter mobile app source code
├── android/                 # Android configuration
├── ios/                     # iOS configuration
│
├── admin-web/               # React admin dashboard
│   ├── src/
│   ├── public/
│   └── package.json
│
├── pickleball-backend/      # Node.js backend
│   ├── src/
│   ├── prisma/
│   └── package.json
│
├── pubspec.yaml             # Flutter dependencies
└── README.md
```

------------------------------------------------------------------------

# ⚙️ Requirements

Before running the project, make sure you have installed:

-   Flutter SDK\
-   Dart SDK\
-   Node.js (LTS recommended)\
-   npm\
-   PostgreSQL or MySQL database\
-   Prisma CLI

------------------------------------------------------------------------

# 🚀 Running the Backend

Navigate to the backend folder:

``` bash
cd pickleball-backend
```

Install dependencies:

``` bash
npm install
```

Generate Prisma client:

``` bash
npx prisma generate
```

Run database migrations:

``` bash
npx prisma migrate dev
```

Start the backend server:

``` bash
npm run dev
```

The backend will run on:

    http://127.0.0.1:3000

API base URL:

    http://127.0.0.1:3000/api

------------------------------------------------------------------------

# 🖥 Running the Admin Dashboard

Navigate to the admin dashboard:

``` bash
cd admin-web
```

Install dependencies:

``` bash
npm install
```

Run the development server:

``` bash
npm run dev
```

Admin dashboard will run on:

    http://localhost:5173

------------------------------------------------------------------------

# 📱 Running the Flutter App

From the root project directory:

``` bash
flutter clean
flutter pub get
flutter run
```

This will build and run the mobile application on your emulator or
device.

------------------------------------------------------------------------

# ✨ Features

## 👤 User Features

-   Register and login\
-   Email verification\
-   Profile management\
-   Upload avatar and cover images

------------------------------------------------------------------------

## 🏓 Court Booking

-   View courts\
-   Book courts\
-   Booking history\
-   Payment OTP verification

------------------------------------------------------------------------

## 🎓 Classes

-   Browse classes\
-   Register for classes\
-   Coach class management

------------------------------------------------------------------------

## 🌐 Community

-   Posts\
-   Notifications\
-   Chatbot support

------------------------------------------------------------------------

## 🎥 Video System

-   Short video feed\
-   Training videos

------------------------------------------------------------------------

## 🪙 Coin System

-   Earn coins from tasks\
-   Spin rewards\
-   Redeem vouchers

------------------------------------------------------------------------

# ⚙️ Backend Modules

The backend API includes the following modules:

-   Authentication\
-   Booking\
-   Chatbot\
-   Classes\
-   Coaches\
-   Coins\
-   Courts\
-   Dashboard\
-   Notifications\
-   Posts\
-   Products\
-   Spin rewards\
-   Users\
-   Videos\
-   Vouchers

------------------------------------------------------------------------

# 🧰 Technologies Used

## 📱 Mobile

-   Flutter\
-   Provider\
-   HTTP

------------------------------------------------------------------------

## 🖥 Admin Web

-   React\
-   Vite\
-   Axios\
-   React Router

------------------------------------------------------------------------

## ⚙️ Backend

-   Node.js\
-   Express\
-   Prisma ORM\
-   Socket.IO\
-   JWT\
-   Nodemailer\
-   OpenAI API

------------------------------------------------------------------------

# 🔐 Environment Configuration

Create a `.env` file inside:

    pickleball-backend

Example configuration:

``` env
PORT=3000

DATABASE_URL=your_database_url

JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

OPENAI_API_KEY=your_openai_key
OPENAI_CHAT_MODEL=gpt-4.1-mini

MAIL_USER=your_email
MAIL_APP_PASSWORD=your_password

OTP_EXPIRE_MINUTES=5
PUBLIC_BASE_URL=http://127.0.0.1:3000
```

