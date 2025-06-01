# Tyokorttisovellus

A Flutter app for managing daily work logs and exporting to PDF/Excel templates.

## Prerequisites

- Flutter SDK (>=3.1.0 <4.0.0)
- Android Studio (for Android builds)
- Visual Studio (for Windows builds)
- Xcode (for iOS builds - macOS only)

## Build Instructions

### Install Dependencies
```bash
flutter pub get
```

### Run Development Build
```bash
flutter run
```

### Production Builds

**Android APK:**
```bash
flutter build apk
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle:**
```bash
flutter build appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**Windows:**
```bash
flutter build windows
```
Output: `build/windows/x64/runner/Release/`

**Web:**
```bash
flutter build web
```
Output: `build/web/`

**iOS:**
```bash
flutter build ios
```

### Troubleshooting

If build fails:
```bash
flutter clean
flutter pub get
```

Check Flutter setup:
```bash
flutter doctor
```
