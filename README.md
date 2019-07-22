# canti_scout

Canti Scout cantare insieme mai stato così facile

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.io/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.io/docs/cookbook)

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.


```
flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/controller/AppLocalizations.dart

flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/controller/AppLocalizations.dart lib/l10n/intl_it.arb
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/controller/AppLocalizations.dart lib/l10n/intl_en.arb

```

## Build

```bash
flutter build apk --build-name=4.0.0 --build-number=20
```

64 bit
```bash
flutter build apk --build-name=4.0.0 --build-number=20 --target-platform android-arm64
```