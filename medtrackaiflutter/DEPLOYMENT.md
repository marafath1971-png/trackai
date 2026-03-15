# Med AI Deployment Strategy

This document outlines the standard procedures for building and deploying the Med AI application for both Android and iOS platforms.

## Prerequisites
Before building for production, ensure the following are configured:
1. **Firebase Configuration**: Both `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) must be present in their respective platform directories.
2. **Environment Variables**: A `.env` file must be present at the root of the project with valid production keys (e.g., `GEMINI_API_KEY`).
3. **App Icons & Splash Screens**: Ensure all launch icons are generated via `flutter pub run flutter_launcher_icons`.

## Environment Configurations
The application uses two conceptual environments:
*   **Staging/Development**: Uses the local Firebase emulators or a dedicated staging Firebase project. API keys might point to lower-tier or sandbox equivalents.
*   **Production**: Points directly to the live Firebase project. Uses robust API keys with strict rate limits/quotas. Crashlytics and Performance Monitoring should only be active here to avoid muddying analytics with dev data.

## Android Build (AAB/APK)

To generate a release build for Android, which includes code obfuscation and AOT compilation:

### Build App Bundle (Google Play Store)
Use the App Bundle format for publishing to the Play Store. This allows Google Play to generate optimized APKs for different device architectures.
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```
*Note: We use `--obfuscate` to make reverse engineering the Dart code significantly harder and `--split-debug-info` to save symbol files needed by Crashlytics to de-obfuscate crash reports later.*

### Build APK (Direct Distribution)
If you need a direct APK (e.g., for testing on a physical device without going through the Play Store):
```bash
flutter build apk --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

## iOS Build (IPA)

To generate a release build for iOS:

1.  **Update CocoaPods**: Ensure you have the latest pods installed.
    ```bash
    cd ios && pod install --repo-update && cd ..
    ```
2.  **Build iOS Archive**:
    ```bash
    flutter build ipa --release --obfuscate --split-debug-info=./build/ios/outputs/symbols
    ```
3.  **Upload to App Store Connect**: You can upload the generated `.ipa` file directly using Transporter or Xcode's Organizer. Ensure you have the correct provisioning profiles and certificates set up in Xcode before running the build command.

## Uploading Debug Symbols to Crashlytics
Because we are obfuscating our code (`--obfuscate`), we must upload the generated debug symbols to Firebase Crashlytics so that crash reports are readable.

*   **Android/iOS**: Follow the Firebase documentation to upload the symbol files generated in `./build/app/outputs/symbols` or `./build/ios/outputs/symbols` using the Firebase CLI.

## Versioning
Ensure you update the `version:` field in `pubspec.yaml` before each release build. The format is `MAJOR.MINOR.PATCH+BUILD_NUMBER` (e.g., `1.0.0+1`). Both the primary version and the build number must be incremented appropriately for app store acceptance.
