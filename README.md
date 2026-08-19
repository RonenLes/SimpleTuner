# Simple Tuner

A Flutter guitar tuner with real-time pitch detection, multiple tuning presets, and support for inline and 3+3 headstock layouts.

## How to use the tuner

1. Open **Tunings** and choose the tuning you want to use. On a narrow screen, tap the arrow in the upper-left corner to open the tuning drawer.
2. Select the headstock layout that matches your instrument: **Inline** or **3 × 3**.
3. Choose a string-selection mode:
   - **Auto** detects which string you are playing.
   - **Manual** lets you tap a numbered string on the headstock before tuning it.
4. Press **Start tuning** and allow microphone access when prompted.
5. Play one string at a time and let it ring clearly near the microphone.
6. Follow the meter:
   - **TUNE UP** means the note is flat; tighten the string.
   - **TUNE DOWN** means the note is sharp; loosen the string.
   - **IN TUNE** and a centered green needle mean the string is within 5 cents of its target.
7. Repeat for every string, then press **Stop** when finished.

For the best result, tune in a quiet room, avoid touching the other strings, and make small adjustments as the needle approaches the center.

## Screenshots

### Tuner

![Simple Tuner main tuner screen](screenshots/tuner%20.png)

### Inline headstock

![Simple Tuner inline headstock layout](screenshots/inline.png)

### Tuning presets

![Simple Tuner tuning preset selector](screenshots/tunes.png)

## Run locally

```sh
cd simple_tuner
flutter pub get
flutter run
```

The project uses the microphone, so approve the operating system's microphone permission request when the app starts listening.

## Build and output locations

Run all build commands from the Flutter project directory:

```sh
cd simple_tuner
flutter pub get
```

### Windows

```sh
flutter build windows --release
```

The executable is created at:

```text
simple_tuner/build/windows/x64/runner/Release/simple_tuner.exe
```

The current checkout also has a debug executable at `simple_tuner/build/windows/x64/runner/Debug/simple_tuner.exe`. When distributing the Windows build, copy the entire `Release` directory because the executable depends on the DLLs and data beside it.

### Android

Android does not use an `.exe`. Build an installable APK with:

```sh
flutter build apk --release
```

The APK is created at:

```text
simple_tuner/build/app/outputs/flutter-apk/app-release.apk
```

For Google Play, build an Android App Bundle instead:

```sh
flutter build appbundle --release
```

The bundle is created at `simple_tuner/build/app/outputs/bundle/release/app-release.aab`.

### iOS

iOS does not use an `.exe`, and iOS builds require macOS with Xcode. Build the app bundle with:

```sh
flutter build ios --release
```

The app bundle is created at `simple_tuner/build/ios/iphoneos/Runner.app`. To distribute the app, archive it in Xcode and export or upload the resulting `.ipa` through Xcode Organizer.
