# 노래 가사 인식 (Song Lyrics) — Flutter App

Listens to music via the microphone, identifies the song using the **AudD API**,
and displays synchronized (or best-effort auto-advancing) lyrics two lines at
a time, in a dark-mode, single-screen UI. No login/account required.

## What's in this folder

```
song_lyrics_app/
├── pubspec.yaml                     # dependencies (minimal set)
├── lib/
│   ├── main.dart                    # app entry point + dark theme
│   ├── config.dart                  # <-- AUDD_API_TOKEN goes here
│   ├── models/
│   │   └── lyric_line.dart
│   ├── services/
│   │   ├── audd_service.dart        # calls AudD API, handles errors gracefully
│   │   ├── lrc_parser.dart          # parses synced (LRC) or plain lyrics
│   │   └── demo_lyrics.dart         # fallback demo lyrics
│   ├── screens/
│   │   └── home_screen.dart         # the single screen: mic button + lyrics
│   └── widgets/
│       └── lyrics_box.dart          # large 2-line "subtitle" box
└── android_manifest_reference/
    └── AndroidManifest_additions.xml  # permissions to add
```

This is **source only** (no generated Gradle/Android boilerplate), so you
drop it into a fresh Flutter project scaffold. That's the standard, most
maintainable way to hand off Flutter code.

## Setup instructions

### 1. Prerequisites
- Flutter SDK installed (`flutter doctor` should be green for Android).
- An Android device or emulator.

### 2. Create the project scaffold
```bash
flutter create song_lyrics_app
cd song_lyrics_app
```

### 3. Copy in the provided files
Copy this project's `lib/` folder (overwrite the generated one) and
`pubspec.yaml` into your new `song_lyrics_app/` project, replacing the
defaults.

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Add Android permissions
Open `android/app/src/main/AndroidManifest.xml` and add the three
`<uses-permission>` lines shown in
`android_manifest_reference/AndroidManifest_additions.xml`.

### 6. Set the minimum Android SDK
Open `android/app/build.gradle` (or `build.gradle.kts`) and make sure:
```gradle
defaultConfig {
    minSdkVersion 21   // required by the `record` package
    ...
}
```

### 7. Place your AudD API token
Open **`lib/config.dart`**. The token you provided is already set as the
default:
```dart
const String auddApiToken = String.fromEnvironment(
  'AUDD_API_TOKEN',
  defaultValue: '738e05089ea89479048e178759ac29d8',
);
```
- To use a different token, replace the `defaultValue` string, **or**
  (recommended, so you don't hardcode a real key in source) pass it at
  run/build time instead:
  ```bash
  flutter run --dart-define=AUDD_API_TOKEN=your_token_here
  flutter build apk --dart-define=AUDD_API_TOKEN=your_token_here
  ```
- If the token is ever empty (no default and no `--dart-define`), the app
  automatically shows **demo lyrics** instead of an error — no setup is
  required to try the UI.

### 8. Run
```bash
flutter run
```
Grant the microphone permission when prompted, tap the mic button, and
hold the phone near the music for ~7 seconds.

## Building an APK automatically with GitHub Actions (no local setup needed)

This project includes `.github/workflows/build.yml`, which builds a
release APK on GitHub's free servers every time you push code, and lets
you download the finished `.apk` file — no Flutter installation needed
on your own computer. See the step-by-step guide below.

## How it works
1. Tap the mic button → records ~7 seconds of audio to a temp file.
2. The clip is sent to `https://api.audd.io/` with `return=lyrics`.
3. If AudD returns lyrics in **LRC format** (`[mm:ss.xx]text`), the app
   parses real timestamps and lyrics advance in sync with elapsed time.
4. If AudD returns **plain-text** lyrics (no timestamps — depends on your
   plan/provider), the app evenly spaces lines (4s each) so they still
   auto-advance, and shows a small note under the lyrics box.
5. If there's no token, no network, no match, or no lyrics available, the
   app shows demo lyrics with a small explanatory note instead of an error.
6. Only the current line + next line are ever shown at once, in a large
   dark "subtitle" box, per the design requirement.

## Notes on Korean support
Korean text is handled natively by Flutter's `Text` widget; Android
devices ship with CJK-capable system fallback fonts, so no extra font
asset or package is needed to render 한글 correctly.

## Limitations (by design, to keep this simple)
- Recording is a fixed ~7-second clip per tap (no continuous/background
  listening), which keeps the mic/permission logic simple.
- Lyric timing starts counting from the moment recognition completes, not
  from the exact position within the song — AudD's response doesn't
  reliably provide a usable playback offset. For true frame-accurate
  sync you'd need a full audio-analysis/offset-detection layer, which
  was intentionally left out per the "keep it simple" requirement.
