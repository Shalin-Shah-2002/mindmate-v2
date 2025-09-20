# 🧠 MindMate - Mental Health Companion

<div align="center">
  <img src="assets/images/logo.png" alt="MindMate Logo" width="200" height="200" />
  
  **A comprehensive mental wellness companion for youth**
  
  [![Flutter Version](https://img.shields.io/badge/Flutter-3.9.2+-blue.svg?logo=flutter)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg?logo=firebase)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)](https://flutter.dev/)
</div>

## 📖 Overview

MindMate is a Flutter-based mobile application designed to provide comprehensive mental health support for youth. It combines AI therapy, mood tracking, community support, SOS emergency assistance, guided meditation, resource library, and social networking in one secure and accessible platform.

### 🎯 Mission
To empower young individuals with the tools, resources, and community support they need to maintain positive mental health and develop healthy coping strategies.

## ✨ Key Features

### 🔐 **Authentication & User Management**
- 🔑 Firebase Authentication (Email/Password, Google Sign-in)
- 🎨 Comprehensive user onboarding with mood and interest preferences
- 👤 Profile setup with avatar, bio, and personal information
- 🔒 Privacy controls and settings

### 🤖 **AI Therapist Chatbot**
- 💬 AI-powered chat using Gemini/OpenAI API
- 🧠 Context-aware responses focusing on mental health
- 📚 Conversation history for personal reflection
- 💡 Personalized self-care tips based on mood patterns

### 📊 **Mood Tracking**
- 😊 Daily mood logging via emoji/slider interface
- 📝 Optional text journal entries
- 📈 Graphical insights on mood trends (weekly/monthly)
- 🎯 Pattern recognition and personalized recommendations

### 🚨 **SOS Emergency Support**
- 📞 Add, edit, and store emergency contacts
- 🔴 One-click SOS button with location-based messaging
- 📋 Preloaded local and regional helpline numbers
- 🚑 Quick access to crisis resources

### 👥 **Community & Peer Support**
- 🌐 Public and anonymous posts
- 💖 Likes, comments, replies, and shares
- 👨‍👩‍👧‍👦 Thematic discussion groups (Anxiety, Exam Stress, etc.)
- 🛡️ Reporting and blocking system for safety

### 👤 **User Profiles & Social Features**
- 🏠 Personal profile pages with posts and activity
- 👫 Follow/unfollow users
- 🔐 Privacy settings and content control
- 🏆 Achievement badges and progress tracking

### 🔔 **Smart Notifications**
- 📱 Push notifications for social interactions
- ⏰ Mood tracking reminders
- 💭 AI-generated wellness tips
- 🔕 Customizable notification preferences

### 🧘 **Guided Meditation & Relaxation**
- 🎵 Short audio/video meditations
- 🫁 Breathing exercises with visual animations
- 😴 Sleep sounds and calming playlists
- ⏱️ Customizable session lengths

### 📚 **Resource Library**
- 📰 Curated articles and self-help tips
- 💬 Inspirational quotes and daily affirmations
- 🔄 Regular content updates
- 🏷️ Categorized resources by topic

### ♿ **Accessibility & Customization**
- 🌙 Light/Dark mode toggle
- 🔤 Adjustable font sizes
- 🔊 Text-to-speech support
- 🌐 Multi-language support (planned)

## 🛠️ Tech Stack

### **Frontend**
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Material Design 3**: Modern UI components

### **State Management**
- **GetX**: Reactive state management, dependency injection, and navigation

### **Backend & Services**
- **Firebase Core**: Backend infrastructure
- **Firebase Auth**: User authentication
- **Cloud Firestore**: NoSQL database
- **Firebase Storage**: File storage
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Analytics**: User analytics
- **Firebase Crashlytics**: Error tracking

### **AI & APIs**
- **Gemini API**: AI-powered chatbot responses
- **OpenAI API**: Alternative AI service
- **Google Sign-In**: Social authentication

### **Additional Packages**
```yaml
dependencies:
  get: ^4.6.6                    # State management
  firebase_core: ^3.1.0         # Firebase core
  firebase_auth: ^5.1.0         # Authentication
  cloud_firestore: ^5.0.1       # Database
  firebase_storage: ^12.0.1     # File storage
  google_sign_in: ^6.3.0        # Google authentication
  http: ^1.1.0                  # HTTP requests
  shared_preferences: ^2.2.2    # Local storage
  flutter_svg: ^2.0.9           # SVG support
  cached_network_image: ^3.3.0  # Image caching
  image_picker: ^1.0.4          # Image selection
```

## 📱 Screenshots

<div align="center">
  <img src="docs/screenshots/login.png" alt="Login Screen" width="200" />
  <img src="docs/screenshots/home.png" alt="Home Screen" width="200" />
  <img src="docs/screenshots/chat.png" alt="AI Chat" width="200" />
  <img src="docs/screenshots/mood.png" alt="Mood Tracking" width="200" />
</div>

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: Version 3.9.2 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Project**: Set up with required services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Shalin-Shah-2002/mindmate-v2.git
   cd mindmate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Configure Firebase for Flutter
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. **Configure environment variables**
   - Create `lib/config/api_keys.dart`
   - Add your API keys (Gemini, OpenAI)
   ```dart
   class ApiKeys {
     static const String geminiApiKey = 'your_gemini_api_key';
     static const String openaiApiKey = 'your_openai_api_key';
   }
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── config/              # Configuration files
├── models/              # Data models
│   ├── user_model.dart
│   ├── post_model.dart
│   └── mood_entry_model.dart
├── services/            # Service layer
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── notification_service.dart
├── viewmodels/          # Business logic (MVVM)
│   ├── auth_viewmodel.dart
│   ├── home_viewmodel.dart
│   └── chat_viewmodel.dart
├── views/               # UI components
│   ├── auth/           # Authentication screens
│   ├── home/           # Home and dashboard
│   ├── chat/           # AI chat interface
│   ├── mood/           # Mood tracking
│   ├── community/      # Social features
│   └── profile/        # User profiles
├── widgets/            # Reusable UI components
├── utils/              # Utility functions
└── main.dart           # App entry point
```

## 🔧 Configuration

### Firebase Configuration
1. Create a new Firebase project
2. Enable the following services:
   - Authentication (Google, Email/Password)
   - Cloud Firestore
   - Storage
   - Cloud Messaging
   - Analytics
   - Crashlytics

3. Update Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public posts (privacy-based access)
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### Environment Setup
- Ensure all API keys are properly configured
- Test Firebase connection
- Verify push notification setup

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart
```

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style
- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure proper error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Firebase Team** for the robust backend services
- **Flutter Team** for the amazing framework
- **GetX Community** for the powerful state management solution
- **Mental Health Organizations** for guidance on best practices
- **Open Source Community** for the inspiration and support

## 📞 Support & Contact

- **Email**: support@mindmate.app
- **GitHub Issues**: [Report bugs or request features](https://github.com/Shalin-Shah-2002/mindmate-v2/issues)
- **Documentation**: [View full documentation](https://docs.mindmate.app)

## 🔗 Links

- **Website**: [https://mindmate.app](https://mindmate.app)
- **Privacy Policy**: [Privacy Policy](https://mindmate.app/privacy)
- **Terms of Service**: [Terms of Service](https://mindmate.app/terms)

---

<div align="center">
  <p>Made with ❤️ by Shalin Shah