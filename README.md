
# 🎙️ AI Diary

> An AI-powered, voice-first journal app that transforms your spoken thoughts into organized, searchable diary entries.

AI Diary revolutionizes personal journaling by eliminating the friction of typing. Simply speak your thoughts, and our advanced AI pipeline handles the rest—recording, transcribing, summarizing, and organizing your entries with intelligent titles and insights.

## 🌍 Multi-Language Transcription Support

AI Diary leverages Google Gemini 2.5 Pro to transcribe and analyze voice entries in multiple languages. The following languages are officially supported for transcription:

- **English**
- **Spanish**
- **French**
- **German**
- **Italian**
- **Portuguese**
- **Dutch**
- **Russian**
- **Chinese (Simplified and Traditional)**
- **Japanese**
- **Korean**
- **Hindi**

You can record your diary entries in any of these languages, and the app will automatically transcribe and summarize your speech.

## ✨ Features

### 🎤 **Voice-First Experience**
- **High-Quality Recording:** Crystal-clear audio capture with noise handling
- **One-Tap Recording:** Simple, intuitive interface for quick voice entries
- **Audio Playback:** Listen to your original recordings anytime

### 🤖 **AI-Powered Processing**
- **Smart Transcription:** Converts speech to text with high accuracy
- **Intelligent Summarization:** Extracts key insights from your entries
- **Auto-Generated Titles:** Creates meaningful titles for easy browsing
- **AI Suggestions & Insights:** Generates personalized recommendations and observations based on your journal patterns
- **Powered by Google Gemini 2.5 Pro:** State-of-the-art language model

### 📱 **Modern User Experience**
- **Material 3 Design:** Beautiful, accessible interface following Google's latest design language
- **Dark/Light Themes:** Automatic theme switching based on system preferences
- **Responsive Layout:** Optimized for phones, tablets, and desktop
- **Smooth Animations:** Polished interactions and transitions

### 📅 **Smart Organization**
- **Calendar View:** Visual timeline of your journal entries
- **Home Dashboard:** Quick access to recent entries and insights
- **Search & Filter:** Find entries by date, content, or keywords
- **Favorites System:** Mark and quickly access important entries

### ☁️ **Secure Cloud Sync**
- **Firebase Integration:** Secure, real-time synchronization across devices
- **Google Sign-In:** Easy authentication with your Google account
- **Privacy-First:** Your data is encrypted and only accessible to you

### 🌐 **Cross-Platform Support**
- **Mobile:** Native Android and iOS apps
- **Web:** Progressive Web App for browsers
- **Desktop:** Windows, macOS, and Linux support

## 🏗️ Architecture & Project Structure

### **Clean Architecture Approach**
Our project follows Clean Architecture principles for maintainability and scalability:

```
lib/
├── main.dart                 # App entry point and configuration
├── config/                   # App-wide configuration
├── models/                   # Data models and entities
├── screens/                  # UI screens and pages
│   ├── auth_screen.dart      # Authentication and sign-in
│   ├── home_screen.dart      # Main dashboard
│   ├── calendar_screen.dart  # Calendar view of entries
│   ├── record_screen.dart    # Voice recording interface
│   ├── entry_details_screen.dart # Individual entry view
│   ├── favorite_screen.dart  # Favorite entries
│   └── settings_screen.dart  # App settings and preferences
├── services/                 # Business logic and external integrations
│   ├── ai_service.dart       # Google Gemini AI integration
│   ├── audio_processing_service.dart # Audio conversion and optimization
│   ├── firebase_service.dart # Cloud storage and authentication
│   ├── recording_service.dart # Audio recording functionality
│   ├── settings_service.dart # User preferences management
│   └── refresh_manager.dart  # State management and data refresh
└── widgets/                  # Reusable UI components
```

### **Service Layer Design**
Each service handles a specific domain of functionality:

- **🤖 AI Service:** Manages communication with Google Gemini API for transcription and summarization
- **🎵 Audio Processing:** Converts recordings to optimal format for AI processing using FFmpeg
- **☁️ Firebase Service:** Handles authentication, data storage, and real-time synchronization
- **🎙️ Recording Service:** Manages microphone access, audio recording, and file management
- **⚙️ Settings Service:** Persists user preferences and app configuration
- **🔄 Refresh Manager:** Coordinates data updates and UI state management

## 🛠️ Technology Stack

### **Frontend Framework**
- **Flutter 3.8.1+** - Google's UI toolkit for building natively compiled applications
- **Dart 3.0+** - Modern, object-oriented programming language optimized for UI development

### **AI & Machine Learning**
- **Google Gemini 2.5 Pro** - Advanced multimodal AI model for text generation and analysis
- **google_generative_ai (^0.4.7)** - Official Google AI SDK for Flutter

### **Audio Processing**
- **record (^6.0.0)** - Cross-platform audio recording with permission handling
- **just_audio (^0.10.4)** - High-performance audio playback with streaming support
- **ffmpeg_kit_flutter_new (^2.0.0)** - Audio conversion and optimization pipeline
- **permission_handler (^12.0.1)** - Runtime permission management

### **Backend & Cloud Services**
- **Firebase Core (^4.0.0)** - Google's mobile and web application development platform
- **Firebase Authentication (^6.0.0)** - Secure user authentication with multiple providers
- **Cloud Firestore (^6.0.0)** - NoSQL document database with real-time synchronization
- **Google Sign-In (^6.2.1)** - OAuth 2.0 authentication for Google accounts

### **UI & User Experience**
- **Material 3 Design** - Google's latest design system with dynamic theming
- **google_fonts (^6.1.0)** - Access to 1000+ Google Fonts with automatic caching
- **table_calendar (^3.0.9)** - Highly customizable calendar widget
- **wave (^0.2.0)** - Beautiful wave animations for audio visualization

### **Development Tools**
- **flutter_launcher_icons (^0.13.1)** - Automated app icon generation for all platforms
- **flutter_native_splash (^2.4.0)** - Native splash screen generation
- **flutter_lints (^6.0.0)** - Official Dart linting rules for code quality

### **Utilities & Helpers**
- **path_provider (^2.1.5)** - Cross-platform path location for file storage
- **http (^1.4.0)** - HTTP client for API communication
- **intl (^0.20.2)** - Internationalization and localization support
- **uuid (^4.3.3)** - RFC4122 UUID generation for unique identifiers

## 🚀 Getting Started

### **Prerequisites**
- **Flutter SDK:** 3.8.1 or higher
- **Dart SDK:** 3.0 or higher
- **IDE:** Android Studio, VS Code, or IntelliJ IDEA
- **Platform Tools:** Android SDK, Xcode (for iOS), or platform-specific tools

### **Environment Setup**
1. **Install Flutter:** Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install)
2. **Verify Installation:** Run `flutter doctor` to ensure proper setup
3. **Configure IDE:** Install Flutter and Dart plugins for your preferred IDE

### **Project Setup**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Emcoding15/AIDiary.git
   cd AIDiary
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication and Firestore Database
   - Download configuration files:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`

4. **Set Up AI Service**
   - Get your API key from [Google AI Studio](https://aistudio.google.com/)
   - Launch the app and enter your API key in Settings
   - The app securely stores your key for future use

5. **Run the Application**
   ```bash
   # For development
   flutter run

   # For specific platforms
   flutter run -d android
   flutter run -d ios
   flutter run -d chrome
   flutter run -d windows
   ```

### **Building for Production**

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires Xcode and Apple Developer account)
flutter build ipa --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🔄 How It Works

### **1. Voice Recording Pipeline**
```
User Input → Microphone Capture → Audio Compression → Local Storage
```
- Captures high-quality audio using platform-native recording APIs
- Applies real-time compression for optimal file sizes
- Stores temporarily for processing

### **2. Audio Processing Chain**
```
Raw Audio → FFmpeg Conversion → Format Optimization → AI-Ready File
```
- Converts to WAV format for consistency
- Optimizes for AI processing (16kHz, mono, specific bitrate)
- Reduces file size while maintaining quality

### **3. AI Analysis Pipeline**
```
Audio File → Google Gemini → Transcription + Summary + Title + Insights → Structured Data
```
- Sends optimized audio to Google Gemini 2.5 Pro
- Receives structured JSON with transcription, summary, intelligent title, and personalized suggestions
- Analyzes patterns and themes to provide meaningful insights about your journaling habits
- Validates and processes AI response

### **4. Data Persistence Flow**
```
Processed Entry → Firebase Firestore → Real-time Sync → Multi-device Access
```
- Stores entry metadata and content in Firestore
- Maintains audio files in secure cloud storage
- Provides real-time synchronization across devices

## 📱 Usage Guide

### **Getting Started**
1. **Sign In:** Use Google account or create account with email
2. **Grant Permissions:** Allow microphone access for recording
3. **Configure AI:** Enter your Google AI API key in Settings

### **Creating Entries**
1. **Tap Record:** Press the microphone button on the home screen
2. **Speak Naturally:** Share your thoughts, experiences, or reflections
3. **Stop Recording:** Tap stop when finished
4. **AI Processing:** Watch as AI transcribes and summarizes your entry
5. **Review & Edit:** Check the generated content and make adjustments if needed

### **Managing Entries**
- **Browse:** Use home feed or calendar view to find entries
- **Search:** Filter by date, keywords, or content
- **Playback:** Listen to original recordings
- **Favorites:** Mark important entries for quick access
- **Export:** Share or backup individual entries

## 🔒 Privacy & Security

- **Local Processing:** Audio processing happens on-device when possible
- **Encrypted Storage:** All data encrypted in transit and at rest
- **User Control:** Full control over data deletion and export
- **API Key Security:** Your AI API keys are stored securely and never shared
- **Firebase Security:** Industry-standard authentication and database rules

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:
- Code style and standards
- Pull request process
- Issue reporting
- Feature requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google** for Firebase, Flutter, and Gemini AI
- **Open Source Community** for the amazing packages we depend on
- **Contributors** who help make this project better

---

**Built with ❤️ using Flutter and AI**
