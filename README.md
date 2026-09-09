# LifeTrack 🚀

**LifeTrack** is a comprehensive, all-in-one lifestyle and productivity tracking application built with **Flutter** and **Supabase**. Designed to help you stay on top of your daily routines, LifeTrack allows you to manage tasks, log workouts, monitor your diet, track coding progress, and earn achievements all from a single, intuitive dashboard.

---

## 🌟 Features

* **📊 Comprehensive Dashboard:** Get a bird's-eye view of your daily progress, upcoming tasks, and overall stats.
* **✅ To-Do & Task Management:** Organize your day efficiently with a built-in task tracker.
* **🏋️‍♂️ Workout Tracker:** Log your exercises with visual guidance (includes integrated workout GIFs like push-ups, planks, squats, and more).
* **📈 Progress & Achievements:** Stay motivated with gamified achievements and visual progress tracking.
* **☁️ Cloud Syncing:** Real-time data synchronization across devices using **Supabase**.
* **🔔 Notifications:** Stay on track with built-in reminder notifications.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend & Database:** [Supabase](https://supabase.com/) (PostgreSQL, Auth)
* **State Management:** Dart Providers (`data_providers.dart`)
* **Code Generation:** `build_runner` / `json_serializable` (for generating model serialization)

---

## 📁 Project Structure

The core source code is located in the `lib/` directory:

    lib/
    ├── core/               # Core configurations (e.g., Supabase config)
    ├── models/             # Data models (Coding, Meal, Task, UserProfile, Workout)
    ├── providers/          # State management providers
    ├── screens/            # UI Screens (Dashboard, Diet, Workout, Coding, etc.)
    ├── services/           # External services (Supabase Sync, Notifications)
    ├── utils/              # Utility classes and theming (AppTheme)
    └── main.dart           # Application entry point

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
* A [Supabase](https://supabase.com/) project to handle database and backend services.
* An IDE like VS Code or Android Studio.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/tanishsarkar28/lifetrack.git](https://github.com/tanishsarkar28/lifetrack.git)
    cd lifetrack
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate data models:**
    Since the project uses generated files (`*.g.dart`) for data models, run the build runner if you make changes to the models:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Configure Supabase:**
    Update your Supabase URL and Anon Key in the `lib/core/supabase_config.dart` file (or your `.env` file if configured).

5.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🎨 Assets & Design

The app includes tailored visual assets located in the `assets/` folder:
* App logos and icons.
* `gif/` directory containing animated exercise demonstrations (e.g., `diamond_pushup.gif`, `mountain_climbers.gif`, `lunges.gif`).

---

## 🧑‍💻 Author

**Tanish Sarkar** 
*Full-Stack Developer | Innovating through Code*

