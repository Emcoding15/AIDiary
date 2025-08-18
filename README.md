
# AI Diary

AI Diary is a modern, voice-first diary app. Instead of typing your thoughts like in a traditional journal, you simply speak—and the app records, transcribes, summarizes, and organizes your entries for you using advanced AI. Capture your day, ideas, or reflections hands-free, and let AI handle the rest.

## Features

- **Voice Recording:** Capture your thoughts with high-quality audio recording using the [`record`](https://pub.dev/packages/record) package.
- **Audio Processing:** Automatically converts and optimizes your recordings for accurate AI transcription using [`ffmpeg_kit_flutter_new`](https://pub.dev/packages/ffmpeg_kit_flutter_new).
- **AI Transcription & Summarization:** Automatic transcription, summary, and title generation for your audio entries using [Google Gemini 2.5 Pro](https://ai.google.dev/) via the [`google_generative_ai`](https://pub.dev/packages/google_generative_ai) package.
- **Modern UI:** Material 3 design, custom theming, and smooth animations built with Flutter's widget system and [`google_fonts`](https://pub.dev/packages/google_fonts).
- **Journal Organization:** View entries by date in home and calendar views using [`table_calendar`](https://pub.dev/packages/table_calendar).
- **Audio Playback:** Listen to your recorded entries with [`just_audio`](https://pub.dev/packages/just_audio).
- **Entry Details:** View transcriptions, summaries, and play audio, all managed in a clean, responsive UI.
- **Cloud Sync:** Secure storage and sync of entries using [Firebase Authentication](https://firebase.google.com/docs/auth) and [Firestore](https://firebase.google.com/docs/firestore) via [`firebase_auth`](https://pub.dev/packages/firebase_auth) and [`cloud_firestore`](https://pub.dev/packages/cloud_firestore).
- **Cross-Platform:** Works on Android, iOS, web, Windows, macOS, and Linux, thanks to Flutter's cross-platform capabilities.

(Screenshots will be added soon)

## Download

You can download the latest APK from the [Releases](https://github.com/Emcoding15/Audio-Journal/releases) section.


## Technologies Used

- **Flutter** (Dart 3.8.1+)
- **Firebase** (Authentication & Firestore)
- **Google Gemini 2.5 Pro** (AI transcription & summarization)
- **ffmpeg_kit_flutter_new** (audio processing)
- **just_audio** (audio playback)
- **record** (audio recording)
- **table_calendar** (calendar UI)
- **Material 3 Design** (modern UI)
- **Cross-platform:** Android, iOS, Web, Windows, macOS, Linux



## Getting Started

### Prerequisites

- Flutter 3.8.1 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Google AI API Key (for transcription features)
- Firebase project (for Auth and Firestore)

### Installation

1. Clone the repository
	```bash
	git clone https://github.com/Emcoding15/Audio-Journal.git
	cd Audio-Journal
	```

2. Install dependencies
	```bash
	flutter pub get
	```



3. API Keys
	- You do not need to manually add or edit any API key files.
	- To use the AI transcription and summarization features, simply open the app and enter your Google AI API key in the Settings screen.
	- The app will securely store your API key for future use.

4. Configure Firebase
	- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective platform folders.

5. Run the app
	```bash
	flutter run
	```

## Usage

1. Open the app and sign in (Google or email/password).
2. Tap the microphone button to start recording.
3. Speak your journal entry and stop when finished.
4. The app will transcribe, summarize, and title your entry using AI.
5. View your entries on the home screen or calendar view.
6. Tap an entry to view details, playback audio, or read the transcription and summary.

## How It Works

- **Recording:** Uses the device microphone and saves audio locally.
- **Audio Processing:** Converts audio to WAV/mono/16kHz using ffmpeg for optimal AI transcription.
- **AI Transcription:** Sends audio to Google Gemini 2.5 Pro, which returns transcription, summary, and title in JSON.
- **Cloud Sync:** Entries are securely stored and synced via Firebase Firestore, linked to your account.
- **Playback & Browsing:** Browse entries by date, view details, and play audio.

## License

This project is licensed under the MIT License - see the LICENSE file for details.


