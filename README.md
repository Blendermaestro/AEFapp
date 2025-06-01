# Tyokorttisovellus (WorkCard App)

A Flutter app for managing daily work logs and exporting to PDF/Excel templates.

## Features

- Track daily work hours and activities
- Generate professional work card reports  
- Export data to PDF and Excel formats
- Local data persistence
- Cross-platform support (Android, iOS, Windows, Web)

## Prerequisites

### Flutter SDK
- **Flutter SDK** (>=3.1.0 <4.0.0)
- Download from: https://docs.flutter.dev/get-started/install
- Add Flutter to your PATH environment variable

### Platform-Specific Tools
- **Android Studio** (for Android builds) - includes Android SDK
- **Visual Studio** with C++ tools (for Windows builds)
- **Xcode** (for iOS builds - macOS only)
- **Chrome** (for web builds)

## Setup Instructions

### 1. Verify Flutter Installation
```bash
flutter doctor
```
Ensure all required components are installed.

### 2. Clone Repository
```bash
git clone https://github.com/Blendermaestro/AEFapp.git
cd AEFapp
```

### 3. Install Dependencies
```bash
flutter pub get
```

## Build Instructions

### Development Build
```bash
flutter run
```
This will launch the app on your connected device/emulator.

### Production Builds

#### Android
**APK (for direct installation):**
```bash
flutter build apk
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**App Bundle (for Google Play Store):**
```bash
flutter build appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### Windows Desktop
```bash
flutter build windows
```
Output: `build/windows/x64/runner/Release/tyokorttisovellus.exe`

#### Web
```bash
flutter build web
```
Output: `build/web/index.html`

#### iOS (macOS required)
```bash
flutter build ios
```
Then open `ios/Runner.xcworkspace` in Xcode to build and deploy.

## Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/               # UI screens
├── services/              # Business logic (PDF, Excel, storage)
└── widgets/               # Reusable UI components

assets/
├── applogo.png           # App icon
├── template.xlsx         # Excel template
└── template_workcard_blank.pdf  # PDF template
```

## Dependencies

- `shared_preferences` - Local data storage
- `excel` - Excel file generation  
- `pdf` & `printing` - PDF generation and printing
- `syncfusion_flutter_pdf` - Advanced PDF features
- `path_provider` - File system access
- `share_plus` - Cross-platform file sharing

## Troubleshooting

### Build Failures
```bash
flutter clean
flutter pub get
flutter build <platform>
```

### Common Issues
- **Android:** Ensure Android SDK is installed via Android Studio
- **Windows:** Install Visual Studio with "Desktop development with C++" workload
- **iOS:** Requires Xcode on macOS with iOS development tools
- **Web:** Ensure Chrome is installed and accessible

### Check Setup
```bash
flutter doctor -v
```
This shows detailed information about your Flutter installation.

## Getting Started with Flutter

New to Flutter? Check out these resources:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
