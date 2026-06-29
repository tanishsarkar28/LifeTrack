# Contributing to LifeTrack 🚀

Thank you for your interest in contributing to **LifeTrack**! We welcome contributions from the community, whether it's fixing bugs, improving documentation, enhancing the UI, or implementing new features.

Please follow these guidelines to help keep the project organized and maintainable.

---

# Before You Start

Before creating an issue or submitting a pull request:

* Search existing issues to avoid duplicates.
* Read the project's `README.md`.
* Keep each contribution focused on a single issue or feature.
* For significant changes, discuss your proposal by opening an issue before starting implementation.

---

# Setting Up the Project

## 1. Fork the Repository

Fork the repository to your GitHub account.

## 2. Clone Your Fork

```bash
git clone https://github.com/<your-github-username>/LifeTrack.git
cd LifeTrack
```

## 3. Install Dependencies

```bash
flutter pub get
```

## 4. Configure Supabase

Update the Supabase credentials in:

```text
lib/core/supabase_config.dart
```

using your own Supabase project credentials.

## 5. Run the Application

```bash
flutter run
```

> **Note:**
> The repository already includes the generated `*.g.dart` files.
> Contributors typically do not need to regenerate them.
> If you modify model classes, ensure the project's code-generation dependencies are compatible with your Flutter and Dart SDK version before running `build_runner`.

---

# Project Structure

```text
lib/
├── core/
├── models/
├── providers/
├── screens/
├── services/
├── utils/
└── main.dart
```

Please place new files in the appropriate directory and follow the existing project organization.

---

# Branch Naming

Create a separate branch for every contribution.

Examples:

```text
feature/monthly-dashboard
feature/add-dark-theme
fix/notification-bug
fix/profile-crash
docs/update-readme
docs/add-contributing-guide
```

---

# Coding Guidelines

Please follow these best practices:

* Follow Dart and Flutter style conventions.
* Write clean, readable, and modular code.
* Reuse widgets whenever possible.
* Avoid unnecessary code duplication.
* Use meaningful variable, method, and class names.
* Keep pull requests focused on a single change.

Before submitting your work, run:

```bash
dart format .
flutter analyze
```

If your changes introduce new functionality, ensure the application runs without errors.

---

# Commit Message Guidelines

Use clear and descriptive commit messages.

Examples:

```text
feat: add monthly progress dashboard
fix: resolve notification scheduling issue
docs: add contribution guidelines
refactor: simplify dashboard provider
```

---

# Pull Request Checklist

Before opening a Pull Request:

* Ensure the project builds successfully.
* Run `flutter analyze`.
* Format your code using `dart format .`.
* Update documentation if necessary.
* Keep your branch up to date with the latest changes.
* Link the related issue in your Pull Request.

Example:

```text
Fixes #19
```

---

# Reporting Bugs

When reporting a bug, please include:

* Operating System
* Flutter version
* Device or emulator information
* Steps to reproduce the issue
* Expected behavior
* Actual behavior
* Screenshots (if applicable)

---

# Suggesting Features

When proposing a feature, please include:

* A clear description of the problem.
* Your proposed solution.
* Any alternative approaches considered.
* Mockups or screenshots, if applicable.

---

# Code of Conduct

Please be respectful, collaborative, and constructive while interacting with maintainers and other contributors.

---

# Thank You 

Every contribution—big or small—helps improve **LifeTrack**. Thank you for taking the time to contribute and be a part of the community!
