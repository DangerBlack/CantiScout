# Building CantScout

---

## Prerequisites

| Requirement | Minimum version | Notes |
|-------------|----------------|-------|
| Flutter SDK | 3.2.0 | `flutter --version` |
| Dart SDK | 3.2.0 | bundled with Flutter |
| Android SDK | API 21 (Android 5.0) | target: API 34 |
| Xcode | 15 | iOS builds only; macOS required |
| Java | 17 | required by Gradle |

Install Flutter by following the
[official guide](https://docs.flutter.dev/get-started/install).

---

## Get the source

```bash
git clone <repo-url>
cd cantiscout
flutter pub get
```

---

## Run in development

```bash
# On a connected Android or iOS device / emulator
flutter run

# List available devices
flutter devices
```

---

## Build — Android

### Debug APK

```bash
flutter build apk --debug
```

### Release APK (universal)

```bash
flutter build apk \
  --build-name=<version>  \   # e.g. 5.0.0
  --build-number=<code>       # integer, increments each release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release APK (arm64 only — smaller, recommended for modern devices)

```bash
flutter build apk \
  --target-platform android-arm64 \
  --build-name=<version> \
  --build-number=<code>
```

### App Bundle (required for Play Store)

```bash
flutter build appbundle \
  --build-name=<version> \
  --build-number=<code>
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Build — iOS

Requires a Mac with Xcode installed.

```bash
flutter build ios \
  --build-name=<version> \
  --build-number=<code>
```

For App Store distribution, open `ios/Runner.xcworkspace` in Xcode and use
**Product → Archive**.

---

## Signing

### Android

Create a keystore and configure `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=<path-to-keystore>
```

Reference `key.properties` from `android/app/build.gradle` as described in the
[Flutter signing guide](https://docs.flutter.dev/deployment/android#signing-the-app).

### iOS

Configure signing in Xcode under **Signing & Capabilities** for the `Runner`
target.

---

## Launcher icons

Launcher icons are generated from assets using `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

Source assets are in `assets/images/`:

| File | Purpose |
|------|---------|
| `image_path_android.png` | Android icon (legacy) |
| `image_path_ios.png` | iOS icon |
| `adaptive_icon_background.png` | Android adaptive icon background layer |
| `adaptive_icon_foreground.png` | Android adaptive icon foreground layer |

---

## Version numbering

CantScout follows **semantic versioning** for the build name (`major.minor.patch`)
and a monotonically increasing integer for the build number. Both are set at
build time via `--build-name` and `--build-number`.

The current version is declared in `pubspec.yaml`:

```yaml
version: 5.0.0+1
#        ^^^^^  ^
#        name   number
```
