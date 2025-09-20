# Firebase Setup for MindMate

## Current Issue
Firebase initialization is failing because the configuration files are missing.

## To Fix Firebase Configuration:

### Step 1: Install Firebase CLI (if not already done)
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Generate Firebase Configuration
Run this command in your project root:
```bash
flutterfire configure
```

This will:
- Create `firebase_options.dart`
- Add configuration to `android/app/google-services.json`
- Add configuration to `ios/Runner/GoogleService-Info.plist`

### Step 4: Update main.dart after configuration
Once you have the configuration files, update main.dart:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MindMateApp());
}
```

### Step 5: Add Firebase plugins to Android
Make sure your `android/app/build.gradle.kts` has:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this line
}
```

And your `android/build.gradle.kts` has:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0") // Add this line
}
```

## Current Workaround
The app is now configured to run without Firebase for testing purposes. Once you complete the Firebase setup above, you can enable full Firebase functionality.

## Test the Current Setup
Run: `flutter run` 
The app should now launch successfully without Firebase errors.