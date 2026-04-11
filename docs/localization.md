# Localization

CantScout uses the Flutter `intl` package and ARB files for localization.
Currently supported locales: **Italian (`it`)** and **English (`en`)**.

---

## File layout

```
lib/
├── controller/
│   └── AppLocalizations.dart   ← defines every localizable string as a getter
└── l10n/
    ├── intl_messages.arb       ← generated: source of truth for message keys
    ├── intl_en.arb             ← English translations
    ├── intl_it.arb             ← Italian translations
    ├── messages_all.dart       ← generated Dart glue code
    ├── messages_en.dart        ← generated
    └── messages_it.dart        ← generated
```

---

## Adding a new string

1. **Declare the getter** in `AppLocalizations.dart`:

   ```dart
   String get my_new_string => Intl.message(
     'Default English text',
     name: 'my_new_string',
     desc: 'Short description for translators',
   );
   ```

2. **Extract messages** to update `intl_messages.arb`:

   ```bash
   flutter pub run intl_translation:extract_to_arb \
     --output-dir=lib/l10n \
     lib/controller/AppLocalizations.dart
   ```

3. **Copy the new entry** from `lib/l10n/intl_messages.arb` into both
   `intl_en.arb` and `intl_it.arb`, then provide the translation:

   ```json
   "my_new_string": "Translated text here",
   "@my_new_string": {
     "description": "Short description for translators"
   }
   ```

4. **Regenerate Dart files**:

   ```bash
   flutter pub run intl_translation:generate_from_arb \
     --output-dir=lib/l10n \
     --no-use-deferred-loading \
     lib/controller/AppLocalizations.dart \
     lib/l10n/intl_en.arb

   flutter pub run intl_translation:generate_from_arb \
     --output-dir=lib/l10n \
     --no-use-deferred-loading \
     lib/controller/AppLocalizations.dart \
     lib/l10n/intl_it.arb
   ```

5. Use the getter anywhere in the widget tree via
   `AppLocalizations.of(context).my_new_string`.

---

## Adding a new language

1. Create `lib/l10n/intl_<locale>.arb` by copying `intl_en.arb` and
   translating every value.

2. Run the generation command with your new `.arb` file:

   ```bash
   flutter pub run intl_translation:generate_from_arb \
     --output-dir=lib/l10n \
     --no-use-deferred-loading \
     lib/controller/AppLocalizations.dart \
     lib/l10n/intl_<locale>.arb
   ```

3. Register the new locale in `AppLocalizations.dart`. Find the `delegates`
   and `supportedLocales` declarations and add your locale there.

4. Submit a pull request with the `.arb` file and the generated `.dart` file.
   You do **not** need to update `intl_messages.arb` (that file is generated,
   not hand-edited).

---

## Tips for translators

- Keep placeholder formatting intact: `{count}`, `{name}`, etc.
- Do not translate string keys (the left-hand side of each JSON pair).
- The `@key` metadata blocks (description, type, placeholders) do not need
  translation — just copy them as-is.
- Run `flutter run` and switch the device locale to verify your strings in
  context before submitting.
