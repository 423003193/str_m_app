# 🌌 SecureCloud Task & Resource Manager (STRM)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)

**STRM** is a high-end, premium task management application featuring a state-of-the-art **Dark Neon Aesthetic**. Built with Flutter, it seamlessly blends offline local persistence with real-time Firebase synchronization and live API data integration.

---

## ✨ Features & Visuals

### 🎀 Modern "Girly" Dark Aesthetic
*   **Deep Contrast**: A rich deep purple-black background (`#1A1025`) paired with neon accents.
*   **Vibrant Gradients**: Sleek **Hot Pink to Violet** gradients (`#FF6B9D` → `#C851E6`) used for progress rings, icons, and interactive elements.
*   **Glassmorphism**: Translucent cards with subtle violet borders for a premium, lightweight feel.

### 🎭 Animation & Interaction "Beyond"
*   **Staggered Entrance**: Task cards slide and fade in sequentially for a dynamic load experience.
*   **Hero Transitions**: Visual continuity as icons morph from the dashboard into detail badges.
*   **Micro-Interactions**: Haptic feedback paired with scale-on-press buttons for a tactile, responsive feel.
*   **Gesture Driven**: Intuitive **Swipe-to-Complete** (Mint) and **Swipe-to-Delete** (Pink) actions on every task.
*   **Animated Progress**: Real-time custom-painted progress rings with gradient arcs.

### ⚙️ Core Functionality
*   **Hybrid Storage**: SQLite for instantaneous local access and Firestore for cloud redundancy.
*   **Smart Sync**: Automatic detection of connectivity to bridge local drafts with your cloud account.
*   **Live Data HUD**: Dedicated "Insights" tab with live **Weather** forecasting and **Currency Exchange** rates.
*   **State Management**: Robust architecture using `flutter_riverpod` for scalable, testable code.

---

## 🚀 Getting Started

### Prerequisites
1.  **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
2.  **Firebase Project**:
    *   Create a project on [Firebase Console](https://console.firebase.google.com/).
    *   Enable **Authentication** (Email/Password) and **Cloud Firestore**.
    *   Download `google-services.json` and place it in `android/app/`.

### Installation
```bash
# Clone the repository
git clone [your-repo-link]

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🛠 Tech Stack
*   **UI**: Flutter (Vanilla CSS-inspired Dark Mode)
*   **State**: Riverpod (StateNotifier)
*   **Auth**: Firebase Authentication
*   **Cloud DB**: Firestore (Cloud NoSQL)
*   **Local DB**: SQFlite (SQLite)
*   **API**: REST Integration (JSONPlaceholder, Open-ER API)
*   **Fonts**: Google Fonts (Poppins)

---

## 📊 Database Schema (SQLite)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key (Auto-increment) |
| `title` | `TEXT` | Task title (Not Null) |
| `description`| `TEXT` | Supporting details |
| `status` | `TEXT` | `pending` or `done` |
| `timestamp` | `INTEGER` | Unix timestamp |
| `synced` | `INTEGER` | 0 = Local Only, 1 = Cloud Synced |

---

## 📜 License
Developed as part of the **Advanced Mobile Development** curriculum. 🌟
