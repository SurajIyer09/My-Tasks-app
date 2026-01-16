# My Tasks – Modern To-Do App

## Project Overview

**App Name:** My Tasks
**Version:** 1.0.0
**Technology Stack:** Flutter (Dart)
**Platforms:** Android, iOS

My Tasks is a modern task management application designed with a strong focus on user experience and visual aesthetics. The app features a dark themed interface, persistent local storage, and intuitive gestures such as swipe-to-delete and drag-and-drop reordering.

---

## Application Screenshots

Upload screenshots to `DOCUMENTATION/screenshots/` and link them here:

```
DOCUMENTATION/screenshots/task_list.png
DOCUMENTATION/screenshots/task_completed.png
DOCUMENTATION/screenshots/create_task.png
```

Example:

```
![Task List](screenshots/task_list.png)
![Task Completed](screenshots/task_completed.png)
![Create Task](screenshots/create_task.png)
```

---

## Key Features

* Create tasks with title, priority level, and due time
* Persistent local storage using shared_preferences
* Priority system: High, Medium, Low
* Task completion animation with auto removal
* Swipe-to-delete tasks
* Drag and drop task reordering
* Modern dark UI
* Integrated time picker

---

## Technical Architecture

### Dependencies

* flutter – Core SDK
* shared_preferences – Local data persistence
* intl – Date and time formatting
* flutter_launcher_icons – App icon generation

### Data Model

```dart
class Todo {
  String id;
  String title;
  bool isCompleted;
  Priority priority;
  DateTime? dueTime;
}
```

---

## Installation & Setup

### Prerequisites

* Flutter SDK 3.7.0 or higher
* Dart SDK
* Android Studio or VS Code
* Android emulator or physical device

### Steps

```bash
flutter pub get
flutter run
```

---

## Build Instructions

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

---

## Folder Structure

```
lib/
 └── main.dart
assets/
 └── icon/
pubspec.yaml
android/
ios/
```

---

## Troubleshooting

* Kotlin version error: update Kotlin plugin to 1.9.0 or higher
* Launcher icons not visible: run dart run flutter_launcher_icons
