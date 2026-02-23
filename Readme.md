

# 🐾 AniCareTrack - Peace of mind in every update.

### *A Trusted Discovery & Monitoring Platform for Urban Pet Care*

---

## 📌 Problem Statement

Pet owners in urban environments often struggle to find trustworthy walkers or caregivers.

Current challenges include:

* ❌ Lack of verified identity for caregivers
* ❌ No transparent review or trust system
* ❌ Limited real-time updates during care sessions
* ❌ Anxiety about pet safety when away
* ❌ No centralized monitoring platform

**How might we create a trusted discovery and monitoring system for pet care?**

---

## 💡 About the Project

AniCareTrack is a Flutter-based mobile application designed to provide:

### 🧑‍🤝‍🧑 Trusted Discovery

* Verified caregiver profiles
* Identity validation
* Ratings & reviews
* Transparent service history

### 🐶 Real-Time Monitoring

* Live session updates
* Activity logs (walk started, completed, location updates)
* Photo/video uploads
* Health & behavior notes

### 🔐 Security & Trust

* Verified accounts
* Secure data handling
* Session tracking
* Clear communication between pet owners and caregivers

The goal is to create **peace of mind through transparency, accountability, and real-time visibility.**

---

## 🏗 Architecture Vision

This project follows a **scalable feature-first Flutter architecture**, designed to support:

* Authentication system
* User roles (Owner / Caregiver)
* Booking management
* Real-time updates
* Notification system
* Backend API integration (future phase)

---

## 🛠 Tech Stack

| Technology                     | Purpose                               |
| ------------------------------ | ------------------------------------- |
| **Flutter**                    | Cross-platform mobile app development |
| **Dart**                       | Programming language                  |
| **Android SDK**                | Android build & emulator              |
| **Gradle**                     | Android build system                  |
| **Git & GitHub**               | Version control & collaboration       |
| **Feature-first Architecture** | Scalable project structure            |

---

## 📂 Project Structure

```
lib/
│
├── main.dart
├── core/                # App themes, constants, utilities
├── features/            # Feature-based modules
│   ├── authentication/
│   ├── user_profiles/
│   ├── booking/
│   ├── live_tracking/
│   └── notifications/
├── shared/              # Reusable widgets
└── services/            # API & data services
```

This structure ensures:

* Separation of concerns
* Clean scalability
* Easy team collaboration
* Maintainable codebase

---

## 🚀 Getting Started

### 1️⃣ Clone the Repository

```bash
git clone <your-repo-url>
cd anicaretrack
```

---

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

---

### 3️⃣ Run the Application

To run on Android emulator:

```bash
flutter run -d emulator-5554
```

To run on connected physical device:

```bash
flutter run
```

---

## 📦 Build Release APK

```bash
flutter build apk
```

---

## 🧪 Run Tests

```bash
flutter test
```

---

## 🔧 Requirements

* Flutter SDK (latest stable)
* Android Studio
* Android Emulator or Physical Android Device
* Minimum 8GB RAM recommended
* USB Debugging enabled (for real device testing)

---

## 🎯 Roadmap

* [ ] User authentication (Owner & Caregiver roles)
* [ ] Verified profile system
* [ ] Booking & scheduling system
* [ ] Real-time session tracking
* [ ] Secure messaging
* [ ] Push notifications
* [ ] Backend API integration
* [ ] Deployment to Play Store


---

## 🌍 Vision

AniCareTrack aims to bridge the trust gap in urban pet care by combining:

* Transparency
* Identity verification
* Real-time monitoring
* Secure communication

Delivering true **peace of mind in every update.**
